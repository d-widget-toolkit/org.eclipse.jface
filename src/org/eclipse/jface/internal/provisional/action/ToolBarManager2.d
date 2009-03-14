/*******************************************************************************
 * Copyright (c) 2006 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 ******************************************************************************/

module org.eclipse.jface.internal.provisional.action.ToolBarManager2;

import org.eclipse.jface.internal.provisional.action.IToolBarManager2;
import org.eclipse.jface.action.IContributionManagerOverrides;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.core.runtime.ListenerList;
import org.eclipse.jface.action.ToolBarManager;
import org.eclipse.jface.util.IPropertyChangeListener;
import org.eclipse.jface.util.PropertyChangeEvent;

import java.lang.all;
import java.util.Set;

/**
 * Extends <code>ToolBarManager</code> to implement <code>IToolBarManager2</code>.
 *
 * <p>
 * <strong>EXPERIMENTAL</strong>. This class or interface has been added as
 * part of a work in progress. There is a guarantee neither that this API will
 * work nor that it will remain the same. Please do not use this API without
 * consulting with the Platform/UI team.
 * </p>
 *
 * @since 3.2
 */
public class ToolBarManager2 : ToolBarManager, IToolBarManager2 {

    // delegate to super
    public ToolBar createControl(Composite parent) {
        return super.createControl(parent);
    }
    public ToolBar getControl() {
        return super.getControl();
    }
    public void dispose() {
        super.dispose();
    }
    public void setOverrides(IContributionManagerOverrides newOverrides) {
        super.setOverrides(newOverrides);
    }

    /**
     * A collection of objects listening to changes to this manager. This
     * collection is <code>null</code> if there are no listeners.
     */
    private /+transient+/ ListenerList listenerList = null;

    /**
     * Creates a new tool bar manager with the default SWT button style. Use the
     * <code>createControl</code> method to create the tool bar control.
     */
    public this() {
        super();
    }

    /**
     * Creates a tool bar manager with the given SWT button style. Use the
     * <code>createControl</code> method to create the tool bar control.
     *
     * @param style
     *            the tool bar item style
     * @see org.eclipse.swt.widgets.ToolBar for valid style bits
     */
    public this(int style) {
        super(style);
    }

    /**
     * Creates a tool bar manager for an existing tool bar control. This manager
     * becomes responsible for the control, and will dispose of it when the
     * manager is disposed.
     *
     * @param toolbar
     *            the tool bar control
     */
    public this(ToolBar toolbar) {
        super(toolbar);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.action.IToolBarManager2#createControl2(org.eclipse.swt.widgets.Composite)
     */
    public Control createControl2(Composite parent) {
        return createControl(parent);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.action.IToolBarManager2#getControl2()
     */
    public Control getControl2() {
        return getControl();
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.action.IToolBarManager2#getItemCount()
     */
    public int getItemCount() {
        ToolBar toolBar = getControl();
        if (toolBar is null || toolBar.isDisposed()) {
            return 0;
        }
        return toolBar.getItemCount();
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.action.IToolBarManager2#addPropertyChangeListener(org.eclipse.jface.util.IPropertyChangeListener)
     */
    public void addPropertyChangeListener(IPropertyChangeListener listener) {
        if (listenerList is null) {
            listenerList = new ListenerList(ListenerList.IDENTITY);
        }

        listenerList.add(cast(Object)listener);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.action.IToolBarManager2#removePropertyChangeListener(org.eclipse.jface.util.IPropertyChangeListener)
     */
    public void removePropertyChangeListener(IPropertyChangeListener listener) {
        if (listenerList !is null) {
            listenerList.remove(cast(Object)listener);

            if (listenerList.isEmpty()) {
                listenerList = null;
            }
        }
    }

    /**
     * @return the listeners attached to this event manager.
     * The listeners currently attached; may be empty, but never
     * null.
     *
     */
    protected final Object[] getListeners() {
        final ListenerList list = listenerList;
        if (list is null) {
            return new Object[0];
        }

        return list.getListeners();
    }

    /*
     * Notifies any property change listeners that a property has changed. Only
     * listeners registered at the time this method is called are notified.
     */
    private void firePropertyChange(PropertyChangeEvent event) {
        Object[] list = getListeners();
        for (int i = 0; i < list.length; ++i) {
            (cast(IPropertyChangeListener) list[i]).propertyChange(event);
        }
    }

    /*
     * Notifies any property change listeners that a property has changed. Only
     * listeners registered at the time this method is called are notified. This
     * method avoids creating an event object if there are no listeners
     * registered, but calls firePropertyChange(PropertyChangeEvent) if there are.
     */
    private void firePropertyChange(String propertyName,
            Object oldValue, Object newValue) {
        if (listenerList !is null) {
            firePropertyChange(new PropertyChangeEvent(this, propertyName,
                    oldValue, newValue));
        }
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.action.ToolBarManager#relayout(org.eclipse.swt.widgets.ToolBar, int, int)
     */
    protected override void relayout(ToolBar layoutBar, int oldCount, int newCount) {
        super.relayout(layoutBar, oldCount, newCount);
        firePropertyChange(PROP_LAYOUT, new Integer(oldCount), new Integer(newCount));
    }
}
