/*******************************************************************************
 * Copyright (c) 2005, 2006 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.layout.LayoutGenerator;

import org.eclipse.jface.layout.GridDataFactory;
import org.eclipse.jface.layout.LayoutConstants;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Layout;
import org.eclipse.swt.widgets.Scrollable;
import org.eclipse.jface.util.Geometry;

import java.lang.all;
import java.util.List;
import java.util.Set;

/* package */class LayoutGenerator {

    /**
     * Default size for controls with varying contents
     */
    private static const Point defaultSize;

    /**
     * Default wrapping size for wrapped labels
     */
    private static const int wrapSize = 350;

    private static const GridDataFactory nonWrappingLabelData;

    static this(){
        defaultSize = new Point(150, 150);
        nonWrappingLabelData = GridDataFactory.fillDefaults().align_(SWT.BEGINNING, SWT.CENTER).grab(false, false);
    }

    private static bool hasStyle(Control c, int style) {
        return (c.getStyle() & style) !is 0;
    }

    /**
     * Generates a GridLayout for the given composite by examining its child
     * controls and attaching layout data to any immediate children that do not
     * already have layout data.
     *
     * @param toGenerate
     *            composite to generate a layout for
     */
    public static void generateLayout(Composite toGenerate) {
        Control[] children = toGenerate.getChildren();

        for (int i = 0; i < children.length; i++) {
            Control control = children[i];

            // Skip any children that already have layout data
            if (control.getLayoutData() !is null) {
                continue;
            }

            applyLayoutDataTo(control);
        }
    }

    private static void applyLayoutDataTo(Control control) {
        defaultsFor(control).applyTo(control);
    }

    /**
     * Creates default factory for this control types:
     * <ul>
     *  <li>{@link Button} with {@link SWT#CHECK}</li>
     *  <li>{@link Button}</li>
     *  <li>{@link Composite}</li>
     * </ul>
     * @param control the control the factory is search for
     * @return a default factory for the control
     */
    public static GridDataFactory defaultsFor(Control control) {
        if ( auto button = cast(Button) control ) {

            if (hasStyle(button, SWT.CHECK)) {
                return nonWrappingLabelData.copy();
            } else {
                return GridDataFactory.fillDefaults().align_(SWT.FILL, SWT.CENTER).hint(Geometry.max(button.computeSize(SWT.DEFAULT, SWT.DEFAULT, true), LayoutConstants.getMinButtonSize()));
            }
        }

        if (auto scrollable = cast(Scrollable) control ) {

            if ( auto composite = cast(Composite) scrollable ) {

                Layout theLayout = composite.getLayout();
                if ( cast(GridLayout) theLayout ) {
                    bool growsHorizontally = false;
                    bool growsVertically = false;

                    Control[] children = composite.getChildren();
                    for (int i = 0; i < children.length; i++) {
                        Control child = children[i];

                        GridData data = cast(GridData) child.getLayoutData();

                        if (data !is null) {
                            if (data.grabExcessHorizontalSpace) {
                                growsHorizontally = true;
                            }
                            if (data.grabExcessVerticalSpace) {
                                growsVertically = true;
                            }
                        }
                    }

                    return GridDataFactory.fillDefaults().grab(growsHorizontally, growsVertically);
                }
            }
        }

        bool wrapping = hasStyle(control, SWT.WRAP);

        // Assume any control with the H_SCROLL or V_SCROLL flags are
        // horizontally or vertically
        // scrollable, respectively.
        bool hScroll = hasStyle(control, SWT.H_SCROLL);
        bool vScroll = hasStyle(control, SWT.V_SCROLL);

        bool containsText = hasMethodSetText(control);//, "setText", [ ArrayWrapperString.classinfo ] ); //$NON-NLS-1$

        // If the control has a setText method, an addModifyListener method, and
        // does not have
        // the SWT.READ_ONLY flag, assume it contains user-editable text.
        bool userEditable = !hasStyle(control, SWT.READ_ONLY) && containsText && hasMethodAddModifyListener(control);//, "addModifyListener", [ ModifyListener.classinfo ]); //$NON-NLS-1$

        // For controls containing user-editable text...
        if (userEditable) {
            if (hasStyle(control, SWT.MULTI)) {
                vScroll = true;
            }

            if (!wrapping) {
                hScroll = true;
            }
        }

        // Compute the horizontal hint
        int hHint = SWT.DEFAULT;
        bool grabHorizontal = hScroll;

        // For horizontally-scrollable controls, override their horizontal
        // preferred size
        // with a constant
        if (hScroll) {
            hHint = defaultSize.x;
        } else {
            // For wrapping controls, there are two cases.
            // 1. For controls that contain text (like wrapping labels,
            // read-only text boxes,
            // etc.) override their preferred size with the preferred wrapping
            // point and
            // make them grab horizontal space.
            // 2. For non-text controls (like wrapping toolbars), assume that
            // their non-wrapped
            // size is best.

            if (wrapping) {
                if (containsText) {
                    hHint = wrapSize;
                    grabHorizontal = true;
                }
            }
        }

        int vAlign = SWT.FILL;

        // Heuristic for labels: Controls that contain non-wrapping read-only
        // text should be
        // center-aligned rather than fill-aligned
        if (!vScroll && !wrapping && !userEditable && containsText) {
            vAlign = SWT.CENTER;
        }

        return GridDataFactory.fillDefaults().grab(grabHorizontal, vScroll).align_(SWT.FILL, vAlign).hint(hHint, vScroll ? defaultSize.y : SWT.DEFAULT);
    }

    struct ControlInfo {
        char[] name;
        bool   hasSetText;
        bool   hasAddModifierListener;
    }
    static ControlInfo[] controlInfo = [
        { "org.eclipse.swt.custom.CBanner.CBanner", false, false },
        { "org.eclipse.swt.custom.CCombo.CCombo", true, true },
        { "org.eclipse.swt.custom.CLabel.CLabel", true, false },
        { "org.eclipse.swt.custom.CTabFolder.CTabFolder", false, false },
        { "org.eclipse.swt.custom.SashForm.SashForm", false, false },
        { "org.eclipse.swt.custom.ScrolledComposite.ScrolledComposite", false, false },
        { "org.eclipse.swt.custom.StyledText.StyledText", true, true },
        { "org.eclipse.swt.custom.TableCursor.TableCursor", false, false },
        { "org.eclipse.swt.custom.TableTree.TableTree", false, false },
        { "org.eclipse.swt.custom.ViewForm.ViewForm", false, false },
        { "org.eclipse.swt.opengl.GLCanvas.GLCanvas", false, false },
        { "org.eclipse.swt.widgets.Button.Button", true, false },
        { "org.eclipse.swt.widgets.Canvas.Canvas", false, false },
        { "org.eclipse.swt.widgets.Combo.Combo", true, true },
        { "org.eclipse.swt.widgets.Composite.Composite", false, false },
        { "org.eclipse.swt.widgets.Control.Control", false, false },
        { "org.eclipse.swt.widgets.CoolBar.CoolBar", false, false },
        { "org.eclipse.swt.widgets.DateTime.DateTime", false, false },
        { "org.eclipse.swt.widgets.Decorations.Decorations", true, false },
        { "org.eclipse.swt.widgets.ExpandBar.ExpandBar", false, false },
        { "org.eclipse.swt.widgets.Group.Group", true, false },
        { "org.eclipse.swt.widgets.Label.Label", true, false },
        { "org.eclipse.swt.widgets.Link.Link", true, false },
        { "org.eclipse.swt.widgets.List.List", false, false },
        { "org.eclipse.swt.widgets.ProgressBar.ProgressBar", false, false },
        { "org.eclipse.swt.widgets.Sash.Sash", false, false },
        { "org.eclipse.swt.widgets.Scale.Scale", false, false },
        { "org.eclipse.swt.widgets.Scrollable.Scrollable", false, false },
        { "org.eclipse.swt.widgets.Shell.Shell", true, false },
        { "org.eclipse.swt.widgets.Slider.Slider", false, false },
        { "org.eclipse.swt.widgets.Spinner.Spinner", false, true },
        { "org.eclipse.swt.widgets.TabFolder.TabFolder", false, false },
        { "org.eclipse.swt.widgets.Table.Table", false, false },
        { "org.eclipse.swt.widgets.Text.Text", true, true },
        { "org.eclipse.swt.widgets.ToolBar.ToolBar", false, false },
        { "org.eclipse.swt.widgets.Tree.Tree", false, false },
    ];
    private static bool hasMethodSetText(Control control) {
        char[] name = control.classinfo.name;
        foreach( ci; controlInfo ){
            if( ci.name == name ){
                return ci.hasSetText;
            }
        }
        throw new Exception( Format( "{}:{} Control was not found for reflection info: {}", __FILE__, __LINE__, name ));
    }
    private static bool hasMethodAddModifyListener(Control control) {
        char[] name = control.classinfo.name;
        foreach( ci; controlInfo ){
            if( ci.name == name ){
                return ci.hasAddModifierListener;
            }
        }
        throw new Exception( Format( "{}:{} Control was not found for reflection info: {}", __FILE__, __LINE__, name ));
    }
//    private static bool hasMethod(Control control, String name, ClassInfo[] parameterTypes) {
//        ClassInfo c = control.classinfo;
//        implMissing(__FILE__,__LINE__);
//        pragma(msg, "FIXME org.eclipse.jface.layout.LayoutGenerator hasMethod reflection" );
//        return true;
///+        try {
//            return c.getMethod(name, parameterTypes) !is null;
//        } catch (SecurityException e) {
//            return false;
//        } catch (NoSuchMethodException e) {
//            return false;
//        }+/
//    }
}
