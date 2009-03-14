/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
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
module org.eclipse.jface.util.OpenStrategy;

import org.eclipse.jface.util.IOpenEventListener;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.TableTree;
import org.eclipse.swt.custom.TableTreeItem;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.core.runtime.ListenerList;

import java.lang.all;
import java.util.Set;
import java.util.EventListener;

/**
 * Implementation of single-click and double-click strategies.
 * <p>
 * Usage:
 * <pre>
 *  OpenStrategy handler = new OpenStrategy(control);
 *  handler.addOpenListener(new IOpenEventListener() {
 *      public void handleOpen(SelectionEvent e) {
 *          ... // code to handle the open event.
 *      }
 *  });
 * </pre>
 * </p>
 */
public class OpenStrategy {
    /**
     * Default behavior. Double click to open the item.
     */
    public static const int DOUBLE_CLICK = 0;

    /**
     * Single click will open the item.
     */
    public static const int SINGLE_CLICK = 1;

    /**
     * Hover will select the item.
     */
    public static const int SELECT_ON_HOVER = 1 << 1;

    /**
     * Open item when using arrow keys
     */
    public static const int ARROW_KEYS_OPEN = 1 << 2;

    /** A single click will generate
     * an open event but key arrows will not do anything.
     *
     * @deprecated
     */
    public static const int NO_TIMER = SINGLE_CLICK;

    /** A single click will generate an open
     * event and key arrows will generate an open event after a
     * small time.
     *
     * @deprecated
     */
    public static const int FILE_EXPLORER = SINGLE_CLICK | ARROW_KEYS_OPEN;

    /** Pointing to an item will change the selection
     * and a single click will gererate an open event
     *
     * @deprecated
     */
    public static const int ACTIVE_DESKTOP = SINGLE_CLICK | SELECT_ON_HOVER;

    // Time used in FILE_EXPLORER and ACTIVE_DESKTOP
    private static const int TIME = 500;

    /* SINGLE_CLICK or DOUBLE_CLICK;
     * In case of SINGLE_CLICK, the bits SELECT_ON_HOVER and ARROW_KEYS_OPEN
     * my be set as well. */
    private static int CURRENT_METHOD = DOUBLE_CLICK;

    private Listener eventHandler;

    private ListenerList openEventListeners;

    private ListenerList selectionEventListeners;

    private ListenerList postSelectionEventListeners;

    /**
     * @param control the control the strategy is applied to
     */
    public this(Control control) {
        openEventListeners = new ListenerList();
        selectionEventListeners = new ListenerList();
        postSelectionEventListeners = new ListenerList();
        initializeHandler(control.getDisplay());
        addListener(control);
    }

    /**
     * Adds an IOpenEventListener to the collection of openEventListeners
     * @param listener the listener to add
     */
    public void addOpenListener(IOpenEventListener listener) {
        openEventListeners.add(cast(Object)listener);
    }

    /**
     * Removes an IOpenEventListener to the collection of openEventListeners
     * @param listener the listener to remove
     */
    public void removeOpenListener(IOpenEventListener listener) {
        openEventListeners.remove(cast(Object)listener);
    }

    /**
     * Adds an SelectionListener to the collection of selectionEventListeners
     * @param listener the listener to add
     */
    public void addSelectionListener(SelectionListener listener) {
        selectionEventListeners.add(cast(Object)listener);
    }

    /**
     * Removes an SelectionListener to the collection of selectionEventListeners
     * @param listener the listener to remove
     */
    public void removeSelectionListener(SelectionListener listener) {
        selectionEventListeners.remove(cast(Object)listener);
    }

    /**
     * Adds an SelectionListener to the collection of selectionEventListeners
     * @param listener the listener to add
     */
    public void addPostSelectionListener(SelectionListener listener) {
        postSelectionEventListeners.add(cast(Object)listener);
    }

    /**
     * Removes an SelectionListener to the collection of selectionEventListeners
     * @param listener the listener to remove
     */
    public void removePostSelectionListener(SelectionListener listener) {
        postSelectionEventListeners.remove(cast(Object)listener);
    }

    /**
     * This method is internal to the framework; it should not be implemented outside
     * the framework.
     * @return the current used single/double-click method
     *
     */
    public static int getOpenMethod() {
        return CURRENT_METHOD;
    }

    /**
     * Set the current used single/double-click method.
     *
     * This method is internal to the framework; it should not be implemented outside
     * the framework.
     * @param method the method to be used
     * @see OpenStrategy#DOUBLE_CLICK
     * @see OpenStrategy#SINGLE_CLICK
     * @see OpenStrategy#SELECT_ON_HOVER
     * @see OpenStrategy#ARROW_KEYS_OPEN
     */
    public static void setOpenMethod(int method) {
        if (method is DOUBLE_CLICK) {
            CURRENT_METHOD = method;
            return;
        }
        if ((method & SINGLE_CLICK) is 0) {
            throw new IllegalArgumentException("Invalid open mode"); //$NON-NLS-1$
        }
        if ((method & (SINGLE_CLICK | SELECT_ON_HOVER | ARROW_KEYS_OPEN)) is 0) {
            throw new IllegalArgumentException("Invalid open mode"); //$NON-NLS-1$
        }
        CURRENT_METHOD = method;
    }

    /**
     * @return true if editors should be activated when opened.
     */
    public static bool activateOnOpen() {
        return getOpenMethod() is DOUBLE_CLICK;
    }

    /*
     * Adds all needed listener to the control in order to implement
     * single-click/double-click strategies.
     */
    private void addListener(Control c) {
        c.addListener(SWT.MouseEnter, eventHandler);
        c.addListener(SWT.MouseExit, eventHandler);
        c.addListener(SWT.MouseMove, eventHandler);
        c.addListener(SWT.MouseDown, eventHandler);
        c.addListener(SWT.MouseUp, eventHandler);
        c.addListener(SWT.KeyDown, eventHandler);
        c.addListener(SWT.Selection, eventHandler);
        c.addListener(SWT.DefaultSelection, eventHandler);
        c.addListener(SWT.Collapse, eventHandler);
        c.addListener(SWT.Expand, eventHandler);
    }

    /*
     * Fire the selection event to all selectionEventListeners
     */
    private void fireSelectionEvent(SelectionEvent e) {
        if (e.item !is null && e.item.isDisposed()) {
            return;
        }
        Object l[] = selectionEventListeners.getListeners();
        for (int i = 0; i < l.length; i++) {
            (cast(SelectionListener) l[i]).widgetSelected(e);
        }
    }

    /*
     * Fire the default selection event to all selectionEventListeners
     */
    private void fireDefaultSelectionEvent(SelectionEvent e) {
        Object l[] = selectionEventListeners.getListeners();
        for (int i = 0; i < l.length; i++) {
            (cast(SelectionListener) l[i]).widgetDefaultSelected(e);
        }
    }

    /*
     * Fire the post selection event to all postSelectionEventListeners
     */
    private void firePostSelectionEvent(SelectionEvent e) {
        if (e.item !is null && e.item.isDisposed()) {
            return;
        }
        Object l[] = postSelectionEventListeners.getListeners();
        for (int i = 0; i < l.length; i++) {
            (cast(SelectionListener) l[i]).widgetSelected(e);
        }
    }

    /*
     * Fire the open event to all openEventListeners
     */
    private void fireOpenEvent(SelectionEvent e) {
        if (e.item !is null && e.item.isDisposed()) {
            return;
        }
        Object l[] = openEventListeners.getListeners();
        for (int i = 0; i < l.length; i++) {
            (cast(IOpenEventListener) l[i]).handleOpen(e);
        }
    }

    //Initialize event handler.
    private void initializeHandler( Display display_) {
        eventHandler = new class(display_) Listener {
            Display display;
            bool timerStarted = false;

            Event mouseUpEvent = null;

            Event mouseMoveEvent = null;

            SelectionEvent selectionPendent = null;

            bool enterKeyDown = false;

            SelectionEvent defaultSelectionPendent = null;

            bool arrowKeyDown = false;

            int[1] count;

            long startTime;

            bool collapseOccurred = false;

            bool expandOccurred = false;

            this(Display a){
                display = a;
                startTime = System.currentTimeMillis();
            }

            public void handleEvent( Event e) {
                if (e.type is SWT.DefaultSelection) {
                    SelectionEvent event = new SelectionEvent(e);
                    fireDefaultSelectionEvent(event);
                    if (CURRENT_METHOD is DOUBLE_CLICK) {
                        fireOpenEvent(event);
                    } else {
                        if (enterKeyDown) {
                            fireOpenEvent(event);
                            enterKeyDown = false;
                            defaultSelectionPendent = null;
                        } else {
                            defaultSelectionPendent = event;
                        }
                    }
                    return;
                }

                switch (e.type) {
                case SWT.MouseEnter:
                case SWT.MouseExit:
                    mouseUpEvent = null;
                    mouseMoveEvent = null;
                    selectionPendent = null;
                    break;
                case SWT.MouseMove:
                    if ((CURRENT_METHOD & SELECT_ON_HOVER) is 0) {
                        return;
                    }
                    if (e.stateMask !is 0) {
                        return;
                    }
                    if (e.widget.getDisplay().getFocusControl() !is e.widget) {
                        return;
                    }
                    mouseMoveEvent = e;
                    Runnable runnable = new class() Runnable {
                        public void run() {
                            long time = System.currentTimeMillis();
                            int diff = cast(int) (time - startTime);
                            if (diff <= TIME) {
                                display.timerExec(diff * 2 / 3, this );
                            } else {
                                timerStarted = false;
                                setSelection(mouseMoveEvent);
                            }
                        }
                    };
                    startTime = System.currentTimeMillis();
                    if (!timerStarted) {
                        timerStarted = true;
                        display.timerExec(TIME * 2 / 3, runnable );
                    }
                    break;
                case SWT.MouseDown:
                    mouseUpEvent = null;
                    arrowKeyDown = false;
                    break;
                case SWT.Expand:
                    expandOccurred = true;
                    break;
                case SWT.Collapse:
                    collapseOccurred = true;
                    break;
                case SWT.MouseUp:
                    mouseMoveEvent = null;
                    if ((e.button !is 1) || ((e.stateMask & ~SWT.BUTTON1) !is 0)) {
                        return;
                    }
                    if (selectionPendent !is null
                            && !(collapseOccurred || expandOccurred)) {
                        mouseSelectItem(selectionPendent);
                    } else {
                        mouseUpEvent = e;
                        collapseOccurred = false;
                        expandOccurred = false;
                    }
                    break;
                case SWT.KeyDown:
                    mouseMoveEvent = null;
                    mouseUpEvent = null;
                    arrowKeyDown = ((e.keyCode is SWT.ARROW_UP) || (e.keyCode is SWT.ARROW_DOWN))
                            && e.stateMask is 0;
                    if (e.character is SWT.CR) {
                        if (defaultSelectionPendent !is null) {
                            fireOpenEvent(new SelectionEvent(e));
                            enterKeyDown = false;
                            defaultSelectionPendent = null;
                        } else {
                            enterKeyDown = true;
                        }
                    }
                    break;
                case SWT.Selection:
                    SelectionEvent event = new SelectionEvent(e);
                    fireSelectionEvent(event);
                    mouseMoveEvent = null;
                    if (mouseUpEvent !is null) {
                        mouseSelectItem(event);
                    } else {
                        selectionPendent = event;
                    }
                    count[0]++;
                    // In the case of arrowUp/arrowDown when in the arrowKeysOpen mode, we
                    // want to delay any selection until the last arrowDown/Up occurs.  This
                    // handles the case where the user presses arrowDown/Up successively.
                    // We only want to open an editor for the last selected item.
                    display.asyncExec(new class( count, e) Runnable {
                        int id_;
                        int[] count_;
                        Event e_;
                        this( int[] a, Event b){
                            count_ = a;
                            e_ = b;
                            id_ = count_[0];
                        }
                        public void run() {
                            if (arrowKeyDown) {
                                display.timerExec(TIME, new class(id_,count_,e_) Runnable {
                                    int id__;
                                    Event e__;
                                    int[] count__;
                                    this(int a, int[] b, Event c){
                                        id__ = a;
                                        count__ = b;
                                        e__ = c;
                                    }
                                    public void run() {
                                        if (id__ is count__[0]) {
                                            firePostSelectionEvent(new SelectionEvent(e__));
                                            if ((CURRENT_METHOD & ARROW_KEYS_OPEN) !is 0) {
                                                fireOpenEvent(new SelectionEvent(e__));
                                            }
                                        }
                                    }
                                });
                            } else {
                                firePostSelectionEvent(new SelectionEvent(e_));
                            }
                        }
                    });
                    break;
                default:
                }
            }

            void mouseSelectItem(SelectionEvent e) {
                if ((CURRENT_METHOD & SINGLE_CLICK) !is 0) {
                    fireOpenEvent(e);
                }
                mouseUpEvent = null;
                selectionPendent = null;
            }

            void setSelection(Event e) {
                if (e is null) {
                    return;
                }
                Widget w = e.widget;
                if (w.isDisposed()) {
                    return;
                }

                SelectionEvent selEvent = new SelectionEvent(e);

                /*ISSUE: May have to create a interface with method:
                 setSelection(Point p) so that user's custom widgets
                 can use this class. If we keep this option. */
                if ( auto tree = cast(Tree)w) {
                    TreeItem item = tree.getItem(new Point(e.x, e.y));
                    if (item !is null) {
                        tree.setSelection([ item ]);
                    }
                    selEvent.item = item;
                } else if ( auto table = cast(Table)w) {
                    TableItem item = table.getItem(new Point(e.x, e.y));
                    if (item !is null) {
                        table.setSelection([ item ]);
                    }
                    selEvent.item = item;
                } else if ( auto table = cast(TableTree)w) {
                    TableTreeItem item = table.getItem(new Point(e.x, e.y));
                    if (item !is null) {
                        table.setSelection([ item ]);
                    }
                    selEvent.item = item;
                } else {
                    return;
                }
                if (selEvent.item is null) {
                    return;
                }
                fireSelectionEvent(selEvent);
                firePostSelectionEvent(selEvent);
            }
        };
    }
}
