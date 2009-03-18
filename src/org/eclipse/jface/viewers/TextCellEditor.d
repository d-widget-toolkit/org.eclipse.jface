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

module org.eclipse.jface.viewers.TextCellEditor;

import org.eclipse.jface.viewers.CellEditor;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.FocusAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.KeyAdapter;
import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.ModifyEvent;
import org.eclipse.swt.events.ModifyListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.SelectionAdapter;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.TraverseEvent;
import org.eclipse.swt.events.TraverseListener;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Text;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Set;

/**
 * A cell editor that manages a text entry field.
 * The cell editor's value is the text string itself.
 * <p>
 * This class may be instantiated; it is not intended to be subclassed.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class TextCellEditor : CellEditor {

    /**
     * The text control; initially <code>null</code>.
     */
    protected Text text;

    private ModifyListener modifyListener;

    /**
     * State information for updating action enablement
     */
    private bool isSelection = false;

    private bool isDeleteable = false;

    private bool isSelectable = false;

    /**
     * Default TextCellEditor style
     * specify no borders on text widget as cell outline in table already
     * provides the look of a border.
     */
    private static const int defaultStyle = SWT.SINGLE;

    /**
     * Creates a new text string cell editor with no control
     * The cell editor value is the string itself, which is initially the empty
     * string. Initially, the cell editor has no cell validator.
     *
     * @since 2.1
     */
    public this() {
        setStyle(defaultStyle);
    }

    /**
     * Creates a new text string cell editor parented under the given control.
     * The cell editor value is the string itself, which is initially the empty string.
     * Initially, the cell editor has no cell validator.
     *
     * @param parent the parent control
     */
    public this(Composite parent) {
        this(parent, defaultStyle);
    }

    /**
     * Creates a new text string cell editor parented under the given control.
     * The cell editor value is the string itself, which is initially the empty string.
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
     * Checks to see if the "deletable" state (can delete/
     * nothing to delete) has changed and if so fire an
     * enablement changed notification.
     */
    private void checkDeleteable() {
        bool oldIsDeleteable = isDeleteable;
        isDeleteable = isDeleteEnabled();
        if (oldIsDeleteable !is isDeleteable) {
            fireEnablementChanged(DELETE);
        }
    }

    /**
     * Checks to see if the "selectable" state (can select)
     * has changed and if so fire an enablement changed notification.
     */
    private void checkSelectable() {
        bool oldIsSelectable = isSelectable;
        isSelectable = isSelectAllEnabled();
        if (oldIsSelectable !is isSelectable) {
            fireEnablementChanged(SELECT_ALL);
        }
    }

    /**
     * Checks to see if the selection state (selection /
     * no selection) has changed and if so fire an
     * enablement changed notification.
     */
    private void checkSelection() {
        bool oldIsSelection = isSelection;
        isSelection = text.getSelectionCount() > 0;
        if (oldIsSelection !is isSelection) {
            fireEnablementChanged(COPY);
            fireEnablementChanged(CUT);
        }
    }

    /* (non-Javadoc)
     * Method declared on CellEditor.
     */
    protected override Control createControl(Composite parent) {
        text = new Text(parent, getStyle());
        text.addSelectionListener(new class SelectionAdapter {
            public void widgetDefaultSelected(SelectionEvent e) {
                handleDefaultSelection(e);
            }
        });
        text.addKeyListener(new class KeyAdapter {
            // hook key pressed - see PR 14201
            public void keyPressed(KeyEvent e) {
                keyReleaseOccured(e);

                // as a result of processing the above call, clients may have
                // disposed this cell editor
                if ((getControl() is null) || getControl().isDisposed()) {
                    return;
                }
                checkSelection(); // see explanation below
                checkDeleteable();
                checkSelectable();
            }
        });
        text.addTraverseListener(new class TraverseListener {
            public void keyTraversed(TraverseEvent e) {
                if (e.detail is SWT.TRAVERSE_ESCAPE
                        || e.detail is SWT.TRAVERSE_RETURN) {
                    e.doit = false;
                }
            }
        });
        // We really want a selection listener but it is not supported so we
        // use a key listener and a mouse listener to know when selection changes
        // may have occurred
        text.addMouseListener(new class MouseAdapter {
            public void mouseUp(MouseEvent e) {
                checkSelection();
                checkDeleteable();
                checkSelectable();
            }
        });
        text.addFocusListener(new class FocusAdapter {
            public void focusLost(FocusEvent e) {
                this.outer.focusLost();
            }
        });
        text.setFont(parent.getFont());
        text.setBackground(parent.getBackground());
        text.setText("");//$NON-NLS-1$
        text.addModifyListener(getModifyListener());
        return text;
    }

    /**
     * The <code>TextCellEditor</code> implementation of
     * this <code>CellEditor</code> framework method returns
     * the text string.
     *
     * @return the text string
     */
    protected override Object doGetValue() {
        return new ArrayWrapperString(text.getText());
    }

    /* (non-Javadoc)
     * Method declared on CellEditor.
     */
    protected override void doSetFocus() {
        if (text !is null) {
            text.selectAll();
            text.setFocus();
            checkSelection();
            checkDeleteable();
            checkSelectable();
        }
    }

    /**
     * The <code>TextCellEditor</code> implementation of
     * this <code>CellEditor</code> framework method accepts
     * a text string (type <code>String</code>).
     *
     * @param value a text string (type <code>String</code>)
     */
    protected override void doSetValue(Object value) {
        Assert.isTrue(text !is null && ( cast(ArrayWrapperString)value ));
        text.removeModifyListener(getModifyListener());
        text.setText((cast(ArrayWrapperString)value).array);
        text.addModifyListener(getModifyListener());
    }

    /**
     * Processes a modify event that occurred in this text cell editor.
     * This framework method performs validation and sets the error message
     * accordingly, and then reports a change via <code>fireEditorValueChanged</code>.
     * Subclasses should call this method at appropriate times. Subclasses
     * may extend or reimplement.
     *
     * @param e the SWT modify event
     */
    protected void editOccured(ModifyEvent e) {
        String value = text.getText();
        if (value is null) {
            value = "";//$NON-NLS-1$
        }
        Object typedValue = new ArrayWrapperString(value);
        bool oldValidState = isValueValid();
        bool newValidState = isCorrect(typedValue);
        if (typedValue is null && newValidState) {
            Assert.isTrue(false,
                    "Validator isn't limiting the cell editor's type range");//$NON-NLS-1$
        }
        if (!newValidState) {
            // try to insert the current value into the error message.
            setErrorMessage(Format(getErrorMessage(), value ));
        }
        valueChanged(oldValidState, newValidState);
    }

    /**
     * Since a text editor field is scrollable we don't
     * set a minimumSize.
     */
    public override LayoutData getLayoutData() {
        return new LayoutData();
    }

    /**
     * Return the modify listener.
     */
    private ModifyListener getModifyListener() {
        if (modifyListener is null) {
            modifyListener = new class ModifyListener {
                public void modifyText(ModifyEvent e) {
                    editOccured(e);
                }
            };
        }
        return modifyListener;
    }

    /**
     * Handles a default selection event from the text control by applying the editor
     * value and deactivating this cell editor.
     *
     * @param event the selection event
     *
     * @since 3.0
     */
    protected void handleDefaultSelection(SelectionEvent event) {
        // same with enter-key handling code in keyReleaseOccured(e);
        fireApplyEditorValue();
        deactivate();
    }

    /**
     * The <code>TextCellEditor</code>  implementation of this
     * <code>CellEditor</code> method returns <code>true</code> if
     * the current selection is not empty.
     */
    public override bool isCopyEnabled() {
        if (text is null || text.isDisposed()) {
            return false;
        }
        return text.getSelectionCount() > 0;
    }

    /**
     * The <code>TextCellEditor</code>  implementation of this
     * <code>CellEditor</code> method returns <code>true</code> if
     * the current selection is not empty.
     */
    public override bool isCutEnabled() {
        if (text is null || text.isDisposed()) {
            return false;
        }
        return text.getSelectionCount() > 0;
    }

    /**
     * The <code>TextCellEditor</code>  implementation of this
     * <code>CellEditor</code> method returns <code>true</code>
     * if there is a selection or if the caret is not positioned
     * at the end of the text.
     */
    public override bool isDeleteEnabled() {
        if (text is null || text.isDisposed()) {
            return false;
        }
        return text.getSelectionCount() > 0
                || text.getCaretPosition() < text.getCharCount();
    }

    /**
     * The <code>TextCellEditor</code>  implementation of this
     * <code>CellEditor</code> method always returns <code>true</code>.
     */
    public override bool isPasteEnabled() {
        if (text is null || text.isDisposed()) {
            return false;
        }
        return true;
    }

    /**
     * Check if save all is enabled
     * @return true if it is
     */
    public bool isSaveAllEnabled() {
        if (text is null || text.isDisposed()) {
            return false;
        }
        return true;
    }

    /**
     * Returns <code>true</code> if this cell editor is
     * able to perform the select all action.
     * <p>
     * This default implementation always returns
     * <code>false</code>.
     * </p>
     * <p>
     * Subclasses may override
     * </p>
     * @return <code>true</code> if select all is possible,
     *  <code>false</code> otherwise
     */
    public override bool isSelectAllEnabled() {
        if (text is null || text.isDisposed()) {
            return false;
        }
        return text.getCharCount() > 0;
    }

    /**
     * Processes a key release event that occurred in this cell editor.
     * <p>
     * The <code>TextCellEditor</code> implementation of this framework method
     * ignores when the RETURN key is pressed since this is handled in
     * <code>handleDefaultSelection</code>.
     * An exception is made for Ctrl+Enter for multi-line texts, since
     * a default selection event is not sent in this case.
     * </p>
     *
     * @param keyEvent the key event
     */
    protected override void keyReleaseOccured(KeyEvent keyEvent) {
        if (keyEvent.character is '\r') { // Return key
            // Enter is handled in handleDefaultSelection.
            // Do not apply the editor value in response to an Enter key event
            // since this can be received from the IME when the intent is -not-
            // to apply the value.
            // See bug 39074 [CellEditors] [DBCS] canna input mode fires bogus event from Text Control
            //
            // An exception is made for Ctrl+Enter for multi-line texts, since
            // a default selection event is not sent in this case.
            if (text !is null && !text.isDisposed()
                    && (text.getStyle() & SWT.MULTI) !is 0) {
                if ((keyEvent.stateMask & SWT.CTRL) !is 0) {
                    super.keyReleaseOccured(keyEvent);
                }
            }
            return;
        }
        super.keyReleaseOccured(keyEvent);
    }

    /**
     * The <code>TextCellEditor</code> implementation of this
     * <code>CellEditor</code> method copies the
     * current selection to the clipboard.
     */
    public override void performCopy() {
        text.copy();
    }

    /**
     * The <code>TextCellEditor</code> implementation of this
     * <code>CellEditor</code> method cuts the
     * current selection to the clipboard.
     */
    public override void performCut() {
        text.cut();
        checkSelection();
        checkDeleteable();
        checkSelectable();
    }

    /**
     * The <code>TextCellEditor</code> implementation of this
     * <code>CellEditor</code> method deletes the
     * current selection or, if there is no selection,
     * the character next character from the current position.
     */
    public override void performDelete() {
        if (text.getSelectionCount() > 0) {
            // remove the contents of the current selection
            text.insert(""); //$NON-NLS-1$
        } else {
            // remove the next character
            int pos = text.getCaretPosition();
            if (pos < text.getCharCount()) {
                text.setSelection(pos, pos + 1);
                text.insert(""); //$NON-NLS-1$
            }
        }
        checkSelection();
        checkDeleteable();
        checkSelectable();
    }

    /**
     * The <code>TextCellEditor</code> implementation of this
     * <code>CellEditor</code> method pastes the
     * the clipboard contents over the current selection.
     */
    public override void performPaste() {
        text.paste();
        checkSelection();
        checkDeleteable();
        checkSelectable();
    }

    /**
     * The <code>TextCellEditor</code> implementation of this
     * <code>CellEditor</code> method selects all of the
     * current text.
     */
    public override void performSelectAll() {
        text.selectAll();
        checkSelection();
        checkDeleteable();
    }

    /**
     * This implementation of
     * {@link CellEditor#dependsOnExternalFocusListener()} returns false if the
     * current instance's class is TextCellEditor, and true otherwise.
     * Subclasses that hook their own focus listener should override this method
     * and return false. See also bug 58777.
     * 
     * @since 3.4
     */
    protected override bool dependsOnExternalFocusListener() {
        return this.classinfo !is TextCellEditor.classinfo;
    }
}
