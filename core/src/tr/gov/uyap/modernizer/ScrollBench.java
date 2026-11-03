package tr.gov.uyap.modernizer;

import javax.swing.*;
import java.awt.*;
import java.awt.event.InputEvent;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * Gelistirici olcum araci (-Duyap.bench=true). Gercek pencerede Robot ile tekerlek olayi
 * gonderir, kare araligi ve cizim suresini dosyaya yazar. Normal kullanimda devre disidir.
 */
public class ScrollBench {
    public static final boolean ENABLED = Boolean.getBoolean("uyap.bench");
    public static final java.util.concurrent.atomic.AtomicInteger WHEELS = new java.util.concurrent.atomic.AtomicInteger();
    public static final List<Long> TICKS = Collections.synchronizedList(new ArrayList<>());
    public static final List<Long> LAT = Collections.synchronizedList(new ArrayList<>());
    public static final List<long[]> SAMPLES = Collections.synchronizedList(new ArrayList<>());

    public static void start() {
        if (!ENABLED) return;
        Thread t = new Thread(() -> {
            try {
                Thread.sleep(9000);
                JScrollPane best = null;
                long bestArea = 0;
                for (Window w : Window.getWindows()) {
                    best = findLargest(w, best);
                }
                if (best == null) { write("no scrollpane"); System.exit(2); }
                Window win = SwingUtilities.getWindowAncestor(best);
                SwingUtilities.invokeAndWait(() -> { win.setAlwaysOnTop(true); win.toFront(); win.requestFocus(); });
                Thread.sleep(1500);
                Point p = best.getLocationOnScreen();
                Robot r = new Robot();
                int cx = p.x + best.getWidth() / 2, cy = p.y + best.getHeight() / 2;
                r.mouseMove(cx, cy);
                Thread.sleep(500);
                StringBuilder sb = new StringBuilder();
                sb.append("pane=").append(best.getWidth()).append("x").append(best.getHeight())
                  .append(" view=").append(best.getViewport().getView().getClass().getName()).append("\n");
                JScrollBar vb = best.getVerticalScrollBar();
                sb.append("vbar visible=").append(vb.isVisible()).append(" value=").append(vb.getValue()).append(" max=").append(vb.getMaximum()).append(" ext=").append(vb.getModel().getExtent()).append("\n");
                sb.append("pane wheelListeners=").append(best.getMouseWheelListeners().length).append(" wheelScrollingEnabled=").append(best.isWheelScrollingEnabled()).append("\n");
                Component v = best.getViewport().getView();
                sb.append("view wheelListeners=").append(v.getMouseWheelListeners().length).append(" mouseListeners=").append(v.getMouseListeners().length).append("\n");
                for (java.awt.event.MouseWheelListener l : v.getMouseWheelListeners()) sb.append("  viewWL: ").append(l.getClass().getName()).append("\n");
                for (java.awt.event.MouseWheelListener l : best.getMouseWheelListeners()) sb.append("  paneWL: ").append(l.getClass().getName()).append("\n");
                for (Component ch : best.getViewport().getComponents()) sb.append("  vpChild: ").append(ch.getClass().getName()).append("\n");
                SAMPLES.clear(); TICKS.clear(); LAT.clear();
                int robotWheelsBefore = WHEELS.get();
                r.mouseWheel(3); Thread.sleep(300);
                sb.append("robot wheel received=").append(WHEELS.get() - robotWheelsBefore).append(" mouse=").append(MouseInfo.getPointerInfo().getLocation()).append(" target=").append(cx + "," + cy).append("\n");
                boolean synthetic = (WHEELS.get() - robotWheelsBefore) == 0;
                sb.append("synthetic=").append(synthetic).append("\n");
                final Component view2 = v;
                // 3 seri tekerlek hareketi: 25 centik x 40ms
                for (int burst = 0; burst < 3; burst++) {
                    for (int i = 0; i < 25; i++) {
                        if (synthetic) {
                            Toolkit.getDefaultToolkit().getSystemEventQueue().postEvent(new java.awt.event.MouseWheelEvent(view2, java.awt.event.MouseEvent.MOUSE_WHEEL, System.currentTimeMillis(), 0, 100, 100, 0, false, java.awt.event.MouseWheelEvent.WHEEL_UNIT_SCROLL, 3, 3));
                        } else { r.mouseWheel(3); }
                        Thread.sleep(40);
                    }
                    Thread.sleep(700);
                }
                Thread.sleep(500);
                List<long[]> s = new ArrayList<>(SAMPLES);
                sb.append("vbar value after=").append(vb.getValue()).append("\n");
                sb.append("steps=").append(s.size()).append("\n");
                List<Double> gaps = new ArrayList<>();
                List<Double> paints = new ArrayList<>();
                for (int i = 0; i < s.size(); i++) {
                    paints.add((s.get(i)[1] - s.get(i)[0]) / 1e6);
                    if (i > 0 && s.get(i)[0] - s.get(i - 1)[0] < 100_000_000L) {
                        gaps.add((s.get(i)[0] - s.get(i - 1)[0]) / 1e6);
                    }
                }
                List<Long> tk = new ArrayList<>(TICKS); List<Double> tg = new ArrayList<>();
                for (int i = 1; i < tk.size(); i++) { double g = (tk.get(i) - tk.get(i-1)) / 1e6; if (g < 100) tg.add(g); }
                List<Long> la = new ArrayList<>(LAT); List<Double> lm = new ArrayList<>();
                for (long x : la) lm.add(x / 1e6);
                sb.append("ticks=").append(tk.size()).append(" tickGap(ms) ").append(stats(tg)).append("\n");
                sb.append("posts=").append(la.size()).append(" invokeLater latency(ms) ").append(stats(lm)).append("\n");
                sb.append("gap(ms) ").append(stats(gaps)).append("\n");
                sb.append("setValue->paintDone(ms) ").append(stats(paints)).append("\n");
                write(sb.toString());
            } catch (Throwable e) {
                write("bench error: " + e);
            }
            System.exit(0);
        }, "ScrollBench");
        t.setDaemon(true);
        t.start();
    }

    private static JScrollPane findLargest(Component c, JScrollPane best) {
        if (c instanceof JScrollPane) {
            JScrollPane sp = (JScrollPane) c;
            if (sp.isShowing() && (best == null || area(sp) > area(best))) best = sp;
        }
        if (c instanceof Container) {
            for (Component ch : ((Container) c).getComponents()) best = findLargest(ch, best);
        }
        return best;
    }

    private static long area(Component c) { return (long) c.getWidth() * c.getHeight(); }

    private static String stats(List<Double> v) {
        if (v.isEmpty()) return "n/a";
        List<Double> s = new ArrayList<>(v);
        Collections.sort(s);
        double sum = 0; for (double d : s) sum += d;
        return String.format("n=%d avg=%.1f p50=%.1f p90=%.1f p99=%.1f max=%.1f", s.size(), sum / s.size(),
                s.get(s.size() / 2), s.get((int) (s.size() * 0.9)), s.get(Math.min(s.size() - 1, (int) (s.size() * 0.99))),
                s.get(s.size() - 1));
    }

    private static void write(String text) {
        try (PrintWriter w = new PrintWriter(System.getenv("TEMP") + "\\uyap_bench.txt", "UTF-8")) {
            w.println(text);
        } catch (Exception ignored) {}
    }
}
