package tr.gov.uyap.modernizer;

import javax.swing.*;
import java.awt.event.MouseWheelEvent;
import java.awt.event.MouseWheelListener;
import java.util.Collections;
import java.util.Map;
import java.util.WeakHashMap;

public class SmoothScroller implements MouseWheelListener {
    private static final Map<JScrollPane, SmoothScroller> activeScrollers =
            Collections.synchronizedMap(new WeakHashMap<>());

    private final JScrollPane scrollPane;
    private final Timer timer;
    private double currentY;
    private double targetY;
    private long lastWheelTime = 0;
    private double velocityMultiplier = 1.0;
    private boolean isUpdating = false;

    public SmoothScroller(JScrollPane pane) {
        this.scrollPane = pane;
        int hz = ModernizerConfig.getTargetHz();
        int interval = Math.max(4, 1000 / hz);

        this.scrollPane.setWheelScrollingEnabled(false);
        this.scrollPane.addMouseWheelListener(this);

        this.timer = new Timer(interval, e -> step());
        this.timer.setCoalesce(true);
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
            }
        }
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

        if (!timer.isRunning()) {
            currentY = vbar.getValue();
            targetY = currentY;
        }

        targetY += delta;
        int min = vbar.getMinimum();
        int max = vbar.getMaximum() - vbar.getModel().getExtent();
        targetY = Math.max(min, Math.min(max, targetY));

        if (!timer.isRunning()) {
            timer.start();
        }
    }

    private void step() {
        if (isUpdating) return; // Drop step if EDT is still rasterizing
        isUpdating = true;
        try {
            JScrollBar vbar = scrollPane.getVerticalScrollBar();
            if (vbar == null) {
                timer.stop();
                return;
            }

            double diff = targetY - currentY;
            if (Math.abs(diff) < 0.5) {
                currentY = targetY;
                vbar.setValue((int) Math.round(currentY));
                timer.stop();
                velocityMultiplier = 1.0;
                return;
            }

            double decay = ModernizerConfig.getScrollDecay();
            double dtSec = timer.getDelay() / 1000.0;
            double factor = 1.0 - Math.exp(-decay * dtSec);

            currentY += diff * factor;

            int min = vbar.getMinimum();
            int max = vbar.getMaximum() - vbar.getModel().getExtent();
            currentY = Math.max(min, Math.min(max, currentY));

            vbar.setValue((int) Math.round(currentY));
        } finally {
            isUpdating = false;
        }
    }

    private void uninstallInternal() {
        timer.stop();
        scrollPane.removeMouseWheelListener(this);
        scrollPane.setWheelScrollingEnabled(true);
    }
}
