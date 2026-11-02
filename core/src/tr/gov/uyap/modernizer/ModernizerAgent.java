package tr.gov.uyap.modernizer;

import javax.swing.*;
import java.awt.*;
import java.awt.event.AWTEventListener;
import java.awt.event.ContainerEvent;
import java.awt.event.HierarchyEvent;
import java.lang.instrument.Instrumentation;

public class ModernizerAgent {
    public static void premain(String agentArgs, Instrumentation inst) {
        ThemeManager.initDisplayEnhancements();

        SwingUtilities.invokeLater(() -> {
            String theme = ModernizerConfig.getTheme();
            if (!"system".equalsIgnoreCase(theme)) {
                ThemeManager.applyTheme(theme);
            }

            Toolkit.getDefaultToolkit().addAWTEventListener(new AWTEventListener() {
                @Override
                public void eventDispatched(AWTEvent event) {
                    if (event instanceof HierarchyEvent) {
                        HierarchyEvent he = (HierarchyEvent) event;
                        if ((he.getChangeFlags() & HierarchyEvent.SHOWING_CHANGED) != 0 && he.getComponent().isShowing()) {
                            scanComponent(he.getComponent());
                        }
                    }
                }
            }, AWTEvent.HIERARCHY_EVENT_MASK);
        });
    }

    private static void scanComponent(Component comp) {
        if (comp instanceof JFrame) {
            ModernizerUI.injectMenu((JFrame) comp);
        }
        if (comp instanceof JScrollPane) {
            SmoothScroller.hook((JScrollPane) comp);
        }
        if (comp instanceof Container) {
            Container cont = (Container) comp;
            for (Component child : cont.getComponents()) {
                scanComponent(child);
            }
        }
    }
}
