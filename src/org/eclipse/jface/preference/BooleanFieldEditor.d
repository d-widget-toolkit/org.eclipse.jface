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
module org.eclipse.jface.preference.BooleanFieldEditor;

import org.eclipse.jface.preference.FieldEditor;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Label;

import java.lang.all;
import java.util.Set;

/**
 * A field editor for a bool type preference.
 */
public class BooleanFieldEditor : FieldEditor {

    /**
     * Style constant (value <code>0</code>) indicating the default
     * layout where the field editor's check box appears to the left
     * of the label.
     */
    public static const int DEFAULT = 0;

    /**
     * Style constant (value <code>1</code>) indicating a layout
     * where the field editor's label appears on the left
     * with a check box on the right.
     */
    public static const int SEPARATE_LABEL = 1;

    /**
     * Style bits. Either <code>DEFAULT</code> or
     * <code>SEPARATE_LABEL</code>.
     */
    private int style;

    /**
     * The previously selected, or "before", value.
     */
    private bool wasSelected;

    /**
     * The checkbox control, or <code>null</code> if none.
     */
    private Button checkBox = null;

    /**
     * Creates a new bool field editor
     */
    protected this() {
    }

    /**
     * Creates a bool field editor in the given style.
     *
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param style the style, either <code>DEFAULT</code> or
     *   <code>SEPARATE_LABEL</code>
     * @param parent the parent of the field editor's control
     * @see #DEFAULT
     * @see #SEPARATE_LABEL
     */
    public this(String name, String labelText, int style,
            Composite parent) {
        init(name, labelText);
        this.style = style;
        createControl(parent);
    }

    /**
     * Creates a bool field editor in the default style.
     *
     * @param name the name of the preference this field editor works on
     * @param label the label text of the field editor
     * @param parent the parent of the field editor's control
     */
    public this(String name, String label, Composite parent) {
        this(name, label, DEFAULT, parent);
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     */
    protected override void adjustForNumColumns(int numColumns) {
        if (style is SEPARATE_LABEL) {
            numColumns--;
        }
        (cast(GridData) checkBox.getLayoutData()).horizontalSpan = numColumns;
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     */
    protected override void doFillIntoGrid(Composite parent, int numColumns) {
        String text = getLabelText();
        switch (style) {
        case SEPARATE_LABEL:
            getLabelControl(parent);
            numColumns--;
            text = null;
        default:
            checkBox = getChangeControl(parent);
            GridData gd = new GridData();
            gd.horizontalSpan = numColumns;
            checkBox.setLayoutData(gd);
            if (text !is null) {
                checkBox.setText(text);
            }
        }
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     * Loads the value from the preference store and sets it to
     * the check box.
     */
    protected override void doLoad() {
        if (checkBox !is null) {
            bool value = getPreferenceStore()
                    .getBoolean(getPreferenceName());
            checkBox.setSelection(value);
            wasSelected = value;
        }
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     * Loads the default value from the preference store and sets it to
     * the check box.
     */
    protected override void doLoadDefault() {
        if (checkBox !is null) {
            bool value = getPreferenceStore().getDefaultBoolean(
                    getPreferenceName());
            checkBox.setSelection(value);
            wasSelected = value;
        }
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     */
    protected override void doStore() {
        getPreferenceStore().setValue(getPreferenceName(),
                checkBox.getSelection());
    }

    /**
     * Returns this field editor's current value.
     *
     * @return the value
     */
    public bool getBooleanValue() {
        return checkBox.getSelection();
    }

    /**
     * Returns the change button for this field editor.
     * @param parent The Composite to create the receiver in.
     *
     * @return the change button
     */
    protected Button getChangeControl(Composite parent) {
        if (checkBox is null) {
            checkBox = new Button(parent, SWT.CHECK | SWT.LEFT);
            checkBox.setFont(parent.getFont());
            checkBox.addSelectionListener(new class SelectionAdapter {
                public void widgetSelected(SelectionEvent e) {
                    bool isSelected = checkBox.getSelection();
                    valueChanged(wasSelected, isSelected);
                    wasSelected = isSelected;
                }
            });
            checkBox.addDisposeListener(new class DisposeListener {
                public void widgetDisposed(DisposeEvent event) {
                    checkBox = null;
                }
            });
        } else {
            checkParent(checkBox, parent);
        }
        return checkBox;
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     */
    public override int getNumberOfControls() {
        switch (style) {
        case SEPARATE_LABEL:
            return 2;
        default:
            return 1;
        }
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     */
    public override void setFocus() {
        if (checkBox !is null) {
            checkBox.setFocus();
        }
    }

    /* (non-Javadoc)
     * Method declared on FieldEditor.
     */
    public override void setLabelText(String text) {
        super.setLabelText(text);
        Label label = getLabelControl();
        if (label is null && checkBox !is null) {
            checkBox.setText(text);
        }
    }

    /**
     * Informs this field editor's listener, if it has one, about a change
     * to the value (<code>VALUE</code> property) provided that the old and
     * new values are different.
     *
     * @param oldValue the old value
     * @param newValue the new value
     */
    protected void valueChanged(bool oldValue, bool newValue) {
        setPresentsDefaultValue(false);
        if (oldValue !is newValue) {
            fireStateChanged(VALUE, oldValue, newValue);
        }
    }

    /*
     * @see FieldEditor.setEnabled
     */
    public override void setEnabled(bool enabled, Composite parent) {
        //Only call super if there is a label already
        if (style is SEPARATE_LABEL) {
            super.setEnabled(enabled, parent);
        }
        getChangeControl(parent).setEnabled(enabled);
    }

}
