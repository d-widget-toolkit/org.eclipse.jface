/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
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
module org.eclipse.jface.viewers.CheckboxCellEditor;

import org.eclipse.jface.viewers.CellEditor;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationEvent;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Set;

/**
 * A cell editor that manages a checkbox.
 * The cell editor's value is a bool.
 * <p>
 * This class may be instantiated; it is not intended to be subclassed.
 * </p>
 * <p>
 * Note that this implementation simply fakes it and does does not create
 * any new controls. The mere activation of this editor means that the value
 * of the check box is being toggled by the end users; the listener method
 * <code>applyEditorValue</code> is immediately called to signal the change.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class CheckboxCellEditor : CellEditor {

    /**
     * The checkbox value.
     */
    /* package */
    bool value = false;

    /**
     * Default CheckboxCellEditor style
     */
    private static const int defaultStyle = SWT.NONE;

    /**
     * Creates a new checkbox cell editor with no control
     * @since 2.1
     */
    public this() {
        setStyle(defaultStyle);
    }

    /**
     * Creates a new checkbox cell editor parented under the given control.
     * The cell editor value is a bool value, which is initially <code>false</code>.
     * Initially, the cell editor has no cell validator.
     *
     * @param parent the parent control
     */
    public this(Composite parent) {
        this(parent, defaultStyle);
    }

    /**
     * Creates a new checkbox cell editor parented under the given control.
     * The cell editor value is a bool value, which is initially <code>false</code>.
     * Initially, the cell editor has no cell validator.
     *
     * @param parent the parent control
     * @param style the style bits
     * @since 2.1
     */
    public this(Composite parent, int style) {
        super(parent, style);
    }

    /**
     * The <code>CheckboxCellEditor</code> implementation of
     * this <code>CellEditor</code> framework method simulates
     * the toggling of the checkbox control and notifies
     * listeners with <code>ICellEditorListener.applyEditorValue</code>.
     */
    public override void activate() {
        value = !value;
        fireApplyEditorValue();
    }

    /**
     * The <code>CheckboxCellEditor</code> implementation of
     * this <code>CellEditor</code> framework method does
     * nothing and returns <code>null</code>.
     */
    protected override Control createControl(Composite parent) {
        return null;
    }

    /**
     * The <code>CheckboxCellEditor</code> implementation of
     * this <code>CellEditor</code> framework method returns
     * the checkbox setting wrapped as a <code>Boolean</code>.
     *
     * @return the Boolean checkbox value
     */
    protected override Object doGetValue() {
        return value ? Boolean.TRUE : Boolean.FALSE;
    }

    /* (non-Javadoc)
     * Method declared on CellEditor.
     */
    protected override void doSetFocus() {
        // Ignore
    }

    /**
     * The <code>CheckboxCellEditor</code> implementation of
     * this <code>CellEditor</code> framework method accepts
     * a value wrapped as a <code>Boolean</code>.
     *
     * @param value a Boolean value
     */
    protected override void doSetValue(Object value) {
        Assert.isTrue( null !is cast(Boolean)value );
        this.value = (cast(Boolean) value).booleanValue();
    }

    public override void activate(ColumnViewerEditorActivationEvent activationEvent) {
        if (activationEvent.eventType !is ColumnViewerEditorActivationEvent.TRAVERSAL) {
            super.activate(activationEvent);
        }
    }
}
