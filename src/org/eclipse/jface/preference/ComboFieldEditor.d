/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Remy Chi Jian Suen <remy.suen@gmail.com> - Bug 214392 missing implementation of ComboFieldEditor.setEnabled
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.preference.ComboFieldEditor;

import org.eclipse.jface.preference.FieldEditor;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Combo;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Set;

/**
 * A field editor for a combo box that allows the drop-down selection of one of
 * a list of items.
 *
 * @since 3.3
 */
public class ComboFieldEditor : FieldEditor {

    /**
     * The <code>Combo</code> widget.
     */
    private Combo fCombo;

    /**
     * The value (not the name) of the currently selected item in the Combo widget.
     */
    private String fValue;

    /**
     * The names (labels) and underlying values to populate the combo widget.  These should be
     * arranged as: { {name1, value1}, {name2, value2}, ...}
     */
    private String[][] fEntryNamesAndValues;

    /**
     * Create the combo box field editor.
     *
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param entryNamesAndValues the names (labels) and underlying values to populate the combo widget.  These should be
     * arranged as: { {name1, value1}, {name2, value2}, ...}
     * @param parent the parent composite
     */
    public this(String name, String labelText, String[][] entryNamesAndValues, Composite parent) {
        init(name, labelText);
        Assert.isTrue(checkArray(entryNamesAndValues));
        fEntryNamesAndValues = entryNamesAndValues;
        createControl(parent);
    }

    /**
     * Checks whether given <code>String[][]</code> is of "type"
     * <code>String[][2]</code>.
     *
     * @return <code>true</code> if it is ok, and <code>false</code> otherwise
     */
    private bool checkArray(String[][] table) {
        if (table is null) {
            return false;
        }
        for (int i = 0; i < table.length; i++) {
            String[] array = table[i];
            if (array is null || array.length !is 2) {
                return false;
            }
        }
        return true;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.preference.FieldEditor#adjustForNumColumns(int)
     */
    protected override void adjustForNumColumns(int numColumns) {
        if (numColumns > 1) {
            Control control = getLabelControl();
            int left = numColumns;
            if (control !is null) {
                (cast(GridData)control.getLayoutData()).horizontalSpan = 1;
                left = left - 1;
            }
            (cast(GridData)fCombo.getLayoutData()).horizontalSpan = left;
        } else {
            Control control = getLabelControl();
            if (control !is null) {
                (cast(GridData)control.getLayoutData()).horizontalSpan = 1;
            }
            (cast(GridData)fCombo.getLayoutData()).horizontalSpan = 1;
        }
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.preference.FieldEditor#doFillIntoGrid(org.eclipse.swt.widgets.Composite, int)
     */
    protected override void doFillIntoGrid(Composite parent, int numColumns) {
        int comboC = 1;
        if (numColumns > 1) {
            comboC = numColumns - 1;
        }
        Control control = getLabelControl(parent);
        GridData gd = new GridData();
        gd.horizontalSpan = 1;
        control.setLayoutData(gd);
        control = getComboBoxControl(parent);
        gd = new GridData();
        gd.horizontalSpan = comboC;
        gd.horizontalAlignment = GridData.FILL;
        control.setLayoutData(gd);
        control.setFont(parent.getFont());
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.preference.FieldEditor#doLoad()
     */
    protected override void doLoad() {
        updateComboForValue(getPreferenceStore().getString(getPreferenceName()));
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.preference.FieldEditor#doLoadDefault()
     */
    protected override void doLoadDefault() {
        updateComboForValue(getPreferenceStore().getDefaultString(getPreferenceName()));
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.preference.FieldEditor#doStore()
     */
    protected override void doStore() {
        if (fValue is null) {
            getPreferenceStore().setToDefault(getPreferenceName());
            return;
        }
        getPreferenceStore().setValue(getPreferenceName(), fValue);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.preference.FieldEditor#getNumberOfControls()
     */
    public override int getNumberOfControls() {
        return 2;
    }

    /*
     * Lazily create and return the Combo control.
     */
    private Combo getComboBoxControl(Composite parent) {
        if (fCombo is null) {
            fCombo = new Combo(parent, SWT.READ_ONLY);
            fCombo.setFont(parent.getFont());
            for (int i = 0; i < fEntryNamesAndValues.length; i++) {
                fCombo.add(fEntryNamesAndValues[i][0], i);
            }

            fCombo.addSelectionListener(new class SelectionAdapter {
                public void widgetSelected(SelectionEvent evt) {
                    String oldValue = fValue;
                    String name = fCombo.getText();
                    fValue = getValueForName(name);
                    setPresentsDefaultValue(false);
                    fireValueChanged(VALUE, stringcast(oldValue), stringcast(fValue));
                }
            });
        }
        return fCombo;
    }

    /*
     * Given the name (label) of an entry, return the corresponding value.
     */
    private String getValueForName(String name) {
        for (int i = 0; i < fEntryNamesAndValues.length; i++) {
            String[] entry = fEntryNamesAndValues[i];
            if (name.equals(entry[0])) {
                return entry[1];
            }
        }
        return fEntryNamesAndValues[0][0];
    }

    /*
     * Set the name in the combo widget to match the specified value.
     */
    private void updateComboForValue(String value) {
        fValue = value;
        for (int i = 0; i < fEntryNamesAndValues.length; i++) {
            if (value.equals(fEntryNamesAndValues[i][1])) {
                fCombo.setText(fEntryNamesAndValues[i][0]);
                return;
            }
        }
        if (fEntryNamesAndValues.length > 0) {
            fValue = fEntryNamesAndValues[0][1];
            fCombo.setText(fEntryNamesAndValues[0][0]);
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.preference.FieldEditor#setEnabled(bool,
     *      org.eclipse.swt.widgets.Composite)
     */
    public void setEnabled(bool enabled, Composite parent) {
        super.setEnabled(enabled, parent);
        getComboBoxControl(parent).setEnabled(enabled);
    }
}
