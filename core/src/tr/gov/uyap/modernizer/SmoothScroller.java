package tr.gov.uyap.modernizer;

import javax.swing.*;
import java.awt.Component;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Microsoft Word ve modern arayüz standartlarında akıcı kaydırma (Smooth Scroller).
 * Cubic Ease-Out interpolasyonu ve yüksek çözünürlüklü 120Hz/240Hz zamanlayıcı ile
 * sıfır input lag, anlık tepki ve pürüzsüz duruş sağlar.
 */
public class SmoothScroller implements MouseWheelListener {
    private static final Map<JScrollPane, SmoothScroller> activeScrollers =
            Collections.synchronizedMap(new WeakHashMap<>());

    private final JScrollPane scrollPane;
    private PrecisionTicker.Handle animTask;

    private double animStartPos;
    private double animTargetPos;
    private long animStartTimeNanos;
    private long animDurationNanos;
    private volatile boolean isRunning = false;
    private final AtomicBoolean isDispatchPending = new AtomicBoolean(false);

    // Microsoft Word / modern tarayıcı standart kaydırma süresi (~160ms)
    private static final double DEFAULT_DURATION_MS = 160.0;
    private long lastWheelTime = 0;
    private double velocityMultiplier = 1.0;

    public SmoothScroller(JScrollPane pane) {
        this.scrollPane = pane;
        this.scrollPane.setWheelScrollingEnabled(false);
        this.scrollPane.addMouseWheelListener(this);

        JViewport vp = this.scrollPane.getViewport();
        if (vp != null) {
            vp.setScrollMode(JViewport.BLIT_SCROLL_MODE);
            vp.addChangeListener(e -> attachView());
        }
        attachView();
        Timer sweeper = new Timer(750, e -> attachView());
        sweeper.setRepeats(true);
        sweeper.start();
    }

    // UYAP editor bileseni (text.t) kendi MouseWheelListener'ina sahip oldugu icin tekerlek olaylari
    // ScrollPane'e hic ulasmiyordu. Bilesenin dinleyicilerini devralip Ctrl+tekerlek gibi
    // islevleri orijinaline devrediyoruz.
    private Component hookedView;
    private final java.util.List<MouseWheelListener> delegates = new java.util.ArrayList<>();

    private void attachView() {
        JViewport vp = scrollPane.getViewport();
        Component view = vp == null ? null : vp.getView();
        if (view == null) return;
        if (view != hookedView) {
            detachView();
            hookedView = view;
            view.addMouseWheelListener(this);
        }
        sweepListeners();
    }

    private void sweepListeners() {
        Component view = hookedView;
        if (view == null) return;
        boolean foreign = false;
        for (MouseWheelListener l : view.getMouseWheelListeners()) {
            if (l == this || delegates.contains(l)) {
                if (l != this) view.removeMouseWheelListener(l);
                continue;
            }
            delegates.add(l);
            view.removeMouseWheelListener(l);
        }
    }

    private void detachView() {
        if (hookedView == null) return;
        hookedView.removeMouseWheelListener(this);
        for (MouseWheelListener l : delegates) hookedView.addMouseWheelListener(l);
        delegates.clear();
        hookedView = null;
    }

    public static void hook(JScrollPane pane) {
        if (pane == null) return;
        synchronized (activeScrollers) {
            if (activeScrollers.containsKey(pane)) return;
            if (ModernizerConfig.isSmoothScrollEnabled()) {
                SmoothScroller scroller = new SmoothScroller(pane);
                activeScrollers.put(pane, scroller);
            }
        }
    }

    public static void updateAll() {
        boolean enabled = ModernizerConfig.isSmoothScrollEnabled();
        synchronized (activeScrollers) {
            if (!enabled) {
                for (SmoothScroller s : activeScrollers.values()) {
                    s.uninstallInternal();
                }
                activeScrollers.clear();
            } else {
                for (SmoothScroller s : activeScrollers.values()) {
                    s.restartIfRunning();
                }
            }
        }
    }

    @Override
    public void mouseWheelMoved(MouseWheelEvent e) {
        ScrollBench.WHEELS.incrementAndGet();
        if (!ModernizerConfig.isSmoothScrollEnabled()) {
            scrollPane.setWheelScrollingEnabled(true);
            return;
        }

        // Ctrl/Shift/Alt + tekerlek (yakinlastirma vb.) orijinal dinleyicilere birakilir
        if (e.isControlDown() || e.isShiftDown() || e.isAltDown()) {
            for (MouseWheelListener l : new java.util.ArrayList<>(delegates)) l.mouseWheelMoved(e);
            return;
        }

        JScrollBar vbar = scrollPane.getVerticalScrollBar();
        if (vbar == null || !vbar.isVisible()) return;

        long now = System.currentTimeMillis();
        long dt = now - lastWheelTime;
        lastWheelTime = now;

        // Word benzeri dinamik ivmelenme (tekerlek hızlı çevrildiğinde hız katlanır)
        if (dt < 90) {
            velocityMultiplier = Math.min(3.2, velocityMultiplier + 0.35);
        } else if (dt > 220) {
            velocityMultiplier = 1.0;
        }

        double rotation;
        try {
            rotation = e.getPreciseWheelRotation();
        } catch (Throwable ignored) {
            rotation = e.getWheelRotation();
        }

        double step = ModernizerConfig.getScrollStep();
        if (step <= 0) step = 75.0;

        double delta = rotation * step * velocityMultiplier;
        int min = vbar.getMinimum();
        int max = vbar.getMaximum() - vbar.getModel().getExtent();

        synchronized (this) {
            double currentPos = vbar.getValue();
            if (!isRunning) {
                animStartPos = currentPos;
                animTargetPos = Math.max(min, Math.min(max, currentPos + delta));
            } else {
                // Word benzeri kesintisiz zincirleme: Önceki hareketin kalanı korunur, yeni delta eklenir
                double remaining = animTargetPos - currentPos;
                animStartPos = currentPos;
                animTargetPos = Math.max(min, Math.min(max, currentPos + remaining + delta));
            }

            animStartTimeNanos = System.nanoTime();
            animDurationNanos = (long) (DEFAULT_DURATION_MS * 1_000_000L);

            if (!isRunning) {
                isRunning = true;
                startTimer();
            }
        }
    }

    private synchronized void startTimer() {
        int hz = ModernizerConfig.getTargetHz();
        if (hz <= 0) hz = 120;
        try {
            int screen = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment()
                    .getDefaultScreenDevice().getDisplayMode().getRefreshRate();
            if (screen >= 60 && screen <= 360) hz = Math.max(hz, screen);
        } catch (Throwable ignored) {}
        long periodNanos = 1_000_000_000L / hz;
        animTask = PrecisionTicker.schedule(this::tick, periodNanos);
    }

    private void tick() {
        if (ScrollBench.ENABLED) ScrollBench.TICKS.add(System.nanoTime());
        if (!isRunning) return;
        // EDT henüz önceki kareyi çiziyorsa yeni event yığma (coalesce/drop)
        // Böylece kuyruk asla şişmez, input lag oluşmaz
        if (isDispatchPending.compareAndSet(false, true)) {
            final long posted = System.nanoTime();
            SwingUtilities.invokeLater(() -> {
                if (ScrollBench.ENABLED) ScrollBench.LAT.add(System.nanoTime() - posted);
                try {
                    stepOnEdt();
                } finally {
                    isDispatchPending.set(false);
                }
            });
        }
    }

    private void stepOnEdt() {
        if (!isRunning) return;

        JScrollBar vbar = scrollPane.getVerticalScrollBar();
        if (vbar == null) {
            stopAnimation();
            return;
        }

        long elapsedNanos = System.nanoTime() - animStartTimeNanos;
        double progress = (double) elapsedNanos / animDurationNanos;

        if (progress >= 1.0) {
            vbar.setValue((int) Math.round(animTargetPos));
            stopAnimation();
            return;
        }

        // Microsoft Word Cubic Ease-Out eğrisi: 1 - (1 - u)^3
        // Anında ilk hareket hızı (sıfır gecikme) ve hedefe yaklaştıkça ipeksi yavaşlama
        double u = 1.0 - progress;
        double easeOut = 1.0 - (u * u * u);

        double newY = animStartPos + (animTargetPos - animStartPos) * easeOut;
        if (ScrollBench.ENABLED) {
            final long t0 = System.nanoTime();
            vbar.setValue((int) Math.round(newY));
            SwingUtilities.invokeLater(() -> ScrollBench.SAMPLES.add(new long[]{t0, System.nanoTime()}));
        } else {
            vbar.setValue((int) Math.round(newY));
        }
    }

    private synchronized void stopAnimation() {
        isRunning = false;
        if (animTask != null) {
            animTask.cancel(false);
            animTask = null;
        }
        velocityMultiplier = 1.0;
    }

    private synchronized void restartIfRunning() {
        if (isRunning) {
            if (animTask != null) {
                animTask.cancel(false);
                animTask = null;
            }
            startTimer();
        }
    }

    private void uninstallInternal() {
        stopAnimation();
        detachView();
        scrollPane.removeMouseWheelListener(this);
        scrollPane.setWheelScrollingEnabled(true);
    }
}
