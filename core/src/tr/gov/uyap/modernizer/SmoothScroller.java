package tr.gov.uyap.modernizer;

import javax.swing.*;
import java.awt.*;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;
import java.util.concurrent.*;

public class SmoothScroller implements MouseWheelListener {
    private static final Map<JScrollPane, SmoothScroller> activeScrollers =
            Collections.synchronizedMap(new WeakHashMap<>());

    // Windows 15.6ms zamanlayıcı kuantizasyonunu aşan yüksek çözünürlüklü executor (120Hz-240Hz)
    private static final ScheduledExecutorService EXECUTOR = Executors.newScheduledThreadPool(1, r -> {
        Thread t = new Thread(r, "Modernizer-SmoothScroller");
        t.setDaemon(true);
        t.setPriority(Thread.MAX_PRIORITY);
        return t;
    });

    private final JScrollPane scrollPane;
    private ScheduledFuture<?> animationTask;
    private double currentY;
    private double targetY;
    private long lastWheelTime = 0;
    private long lastStepNano = 0;
    private double velocityMultiplier = 1.0;
    private volatile boolean isStepRunning = false;
    private volatile boolean isAnimating = false;

    public SmoothScroller(JScrollPane pane) {
        this.scrollPane = pane;
        this.scrollPane.setWheelScrollingEnabled(false);
        this.scrollPane.addMouseWheelListener(this);

        JViewport vp = this.scrollPane.getViewport();
        if (vp != null) {
            vp.setScrollMode(JViewport.BLIT_SCROLL_MODE);
        }
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

    public static int getEffectiveTargetHz() {
        int configHz = ModernizerConfig.getTargetHz();
        try {
            GraphicsEnvironment ge = GraphicsEnvironment.getLocalGraphicsEnvironment();
            GraphicsDevice gd = ge.getDefaultScreenDevice();
            int screenRate = gd.getDisplayMode().getRefreshRate();
            if (screenRate >= 60 && screenRate <= 360) {
                return Math.max(configHz, screenRate);
            }
        } catch (Throwable ignored) {}
        return configHz > 0 ? configHz : 120;
    }

    @Override
    public void mouseWheelMoved(MouseWheelEvent e) {
        if (!ModernizerConfig.isSmoothScrollEnabled()) {
            scrollPane.setWheelScrollingEnabled(true);
            return;
        }

        JScrollBar vbar = scrollPane.getVerticalScrollBar();
        if (vbar == null || !vbar.isVisible()) return;

        long now = System.currentTimeMillis();
        long dt = now - lastWheelTime;
        lastWheelTime = now;

        if (dt < 120) {
            velocityMultiplier = Math.min(2.5, velocityMultiplier + 0.25);
        } else {
            velocityMultiplier = 1.0;
        }

        double delta;
        if (e.getScrollType() == MouseWheelEvent.WHEEL_UNIT_SCROLL) {
            delta = e.getUnitsToScroll() * (ModernizerConfig.getScrollStep() / 3.0);
        } else {
            delta = e.getWheelRotation() * ModernizerConfig.getScrollStep();
        }

        delta *= velocityMultiplier;

        if (!isAnimating) {
            currentY = vbar.getValue();
            targetY = currentY;
        }

        targetY += delta;
        int min = vbar.getMinimum();
        int max = vbar.getMaximum() - vbar.getModel().getExtent();
        targetY = Math.max(min, Math.min(max, targetY));

        startAnimation();
    }

    private synchronized void startAnimation() {
        if (isAnimating) return;
        isAnimating = true;
        lastStepNano = System.nanoTime();

        int hz = getEffectiveTargetHz();
        long periodNanos = 1_000_000_000L / hz;

        animationTask = EXECUTOR.scheduleAtFixedRate(this::dispatchStep, 0, periodNanos, TimeUnit.NANOSECONDS);
    }

    private void dispatchStep() {
        if (!isAnimating) return;
        SwingUtilities.invokeLater(this::step);
    }

    private synchronized void stopAnimation() {
        isAnimating = false;
        if (animationTask != null) {
            animationTask.cancel(false);
            animationTask = null;
        }
        velocityMultiplier = 1.0;
        lastStepNano = 0;
    }

    private synchronized void restartIfRunning() {
        if (isAnimating) {
            stopAnimation();
            startAnimation();
        }
    }

    private void step() {
        if (!isAnimating) return;
        if (isStepRunning) return;
        isStepRunning = true;
        try {
            JScrollBar vbar = scrollPane.getVerticalScrollBar();
            if (vbar == null) {
                stopAnimation();
                return;
            }

            long now = System.nanoTime();
            if (lastStepNano == 0) lastStepNano = now;
            double dtSec = (now - lastStepNano) / 1_000_000_000.0;
            lastStepNano = now;

            // Arka planda donma vb. olursa fizik sıçramasını önlemek için sınırlama
            if (dtSec > 0.05) dtSec = 0.016;

            double diff = targetY - currentY;
            if (Math.abs(diff) < 0.5) {
                currentY = targetY;
                vbar.setValue((int) Math.round(currentY));
                stopAnimation();
                return;
            }

            double decay = ModernizerConfig.getScrollDecay();
            double factor = 1.0 - Math.exp(-decay * dtSec);

            currentY += diff * factor;

            int min = vbar.getMinimum();
            int max = vbar.getMaximum() - vbar.getModel().getExtent();
            currentY = Math.max(min, Math.min(max, currentY));

            vbar.setValue((int) Math.round(currentY));
        } finally {
            isStepRunning = false;
        }
    }

    private void uninstallInternal() {
        stopAnimation();
        scrollPane.removeMouseWheelListener(this);
        scrollPane.setWheelScrollingEnabled(true);
    }
}
