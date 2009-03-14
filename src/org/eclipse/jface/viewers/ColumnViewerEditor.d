/*******************************************************************************
 * Copyright (c) 2006, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - refactoring (bug 153993)
 *                                                 fix in bug: 151295,178946,166500,195908,201906,207676,180504,216706,218336
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.ColumnViewerEditor;

import org.eclipse.jface.viewers.CellEditor;
import org.eclipse.jface.viewers.ICellEditorListener;
import org.eclipse.jface.viewers.ColumnViewer;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationStrategy;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ViewerColumn;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationEvent;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationListener;
import org.eclipse.jface.viewers.ColumnViewerEditorDeactivationEvent;
import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.DoubleClickEvent;
import org.eclipse.jface.viewers.OpenEvent;

import org.eclipse.swt.SWT;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.FocusAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.TraverseEvent;
import org.eclipse.swt.events.TraverseListener;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Item;
import org.eclipse.core.runtime.ListenerList;

import java.lang.all;
import java.util.Set;

/**
 * This is the base for all editor implementations of Viewers. ColumnViewer
 * implementors have to subclass this class and implement the missing methods
 *
 * @since 3.3
 * @see TableViewerEditor
 * @see TreeViewerEditor
 */
public abstract class ColumnViewerEditor {
    private CellEditor cellEditor;

    private ICellEditorListener cellEditorListener;

    private FocusListener focusListener;

    private MouseListener mouseListener;

    private ColumnViewer viewer;

    private TraverseListener tabeditingListener;

    private ViewerCell cell;

    private ListenerList editorActivationListener;

    private ColumnViewerEditorActivationStrategy editorActivationStrategy;

    private bool inEditorDeactivation;

    private DisposeListener disposeListener;

    /**
     * Tabbing from cell to cell is turned off
     */
    public static const int DEFAULT = 1;

    /**
     * Should if the end of the row is reach started from the start/end of the
     * row below/above
     */
    public static const int TABBING_MOVE_TO_ROW_NEIGHBOR = 1 << 1;

    /**
     * Should if the end of the row is reach started from the beginning in the
     * same row
     */
    public static const int TABBING_CYCLE_IN_ROW = 1 << 2;

    /**
     * Support tabbing to Cell above/below the current cell
     */
    public static const int TABBING_VERTICAL = 1 << 3;

    /**
     * Should tabbing from column to column with in one row be supported
     */
    public static const int TABBING_HORIZONTAL = 1 << 4;

    /**
     * Style mask used to enable keyboard activation
     */
    public static const int KEYBOARD_ACTIVATION = 1 << 5;

    /**
     * Style mask used to turn <b>off</b> the feature that an editor activation
     * is canceled on double click. It is also possible to turn off this feature
     * per cell-editor using {@link CellEditor#getDoubleClickTimeout()}
     * @since 3.4
     */
    public static final int KEEP_EDITOR_ON_DOUBLE_CLICK = 1 << 6;

    private int feature;

    /**
     * @param viewer
     *            the viewer this editor is attached to
     * @param editorActivationStrategy
     *            the strategy used to decide about editor activation
     * @param feature
     *            bit mask controlling the editor
     *            <ul>
     *            <li>{@link ColumnViewerEditor#DEFAULT}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_CYCLE_IN_ROW}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_HORIZONTAL}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_MOVE_TO_ROW_NEIGHBOR}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_VERTICAL}</li>
     *            </ul>
     */
    protected this(ColumnViewer viewer,
            ColumnViewerEditorActivationStrategy editorActivationStrategy,
            int feature) {
        this.viewer = viewer;
        this.editorActivationStrategy = editorActivationStrategy;
        if ((feature & KEYBOARD_ACTIVATION) is KEYBOARD_ACTIVATION) {
            this.editorActivationStrategy
                    .setEnableEditorActivationWithKeyboard(true);
        }
        this.feature = feature;
        this.disposeListener = new class(viewer) DisposeListener {
            ColumnViewer viewer_;
            this(ColumnViewer a){
                viewer_=a;
            }
            public void widgetDisposed(DisposeEvent e) {
                if( viewer_.isCellEditorActive() ) {
                    cancelEditing();
                }
            }

        };
        initCellEditorListener();
    }

    private void initCellEditorListener() {
        cellEditorListener = new class ICellEditorListener {
            public void editorValueChanged(bool oldValidState,
                    bool newValidState) {
                // Ignore.
            }

            public void cancelEditor() {
                this.outer.cancelEditing();
            }

            public void applyEditorValue() {
                this.outer.applyEditorValue();
            }
        };
    }

    private bool activateCellEditor(ColumnViewerEditorActivationEvent activationEvent) {

        ViewerColumn part = viewer.getViewerColumn(cell.getColumnIndex());
        Object element = cell.getElement();

        if (part !is null && part.getEditingSupport() !is null
                && part.getEditingSupport().canEdit_package(element)) {
            cellEditor = part.getEditingSupport().getCellEditor_package(element);
            if (cellEditor !is null) {
                int timeout = cellEditor.getDoubleClickTimeout_package();

                int activationTime;

                if (timeout !is 0) {
                    activationTime = activationEvent.time + timeout;
                } else {
                    activationTime = 0;
                }

                if (editorActivationListener !is null
                        && !editorActivationListener.isEmpty()) {
                    Object[] ls = editorActivationListener.getListeners();
                    for (int i = 0; i < ls.length; i++) {
                        (cast(ColumnViewerEditorActivationListener) ls[i])
                                .beforeEditorActivated(activationEvent);

                        // Was the activation canceled ?
                        if (activationEvent.cancel) {
                            return false;
                        }
                    }
                }

                updateFocusCell(cell, activationEvent);

                cellEditor.addListener(cellEditorListener);
                part.getEditingSupport().initializeCellEditorValue_package(cellEditor,
                        cell);

                // Tricky flow of control here:
                // activate() can trigger callback to cellEditorListener which
                // will clear cellEditor
                // so must get control first, but must still call activate()
                // even if there is no control.
                Control control = cellEditor.getControl();
                cellEditor.activate(activationEvent);
                if (control is null) {
                    return false;
                }
                setLayoutData(cellEditor.getLayoutData());
                setEditor(control, cast(Item) cell.getItem(), cell.getColumnIndex());
                cellEditor.setFocus();

                if (cellEditor.dependsOnExternalFocusListener_package()) {
                    if (focusListener is null) {
                        focusListener = new class FocusAdapter {
                            public void focusLost(FocusEvent e) {
                                applyEditorValue();
                            }
                        };
                    }
                    control.addFocusListener(focusListener);
                }

                mouseListener = new class(control, activationEvent, activationTime) MouseAdapter {
                    Control control_;
                    ColumnViewerEditorActivationEvent activationEvent_;
                    int activationTime_;
                    this(Control a, ColumnViewerEditorActivationEvent b, int c){
                        control_=a;
                        activationEvent_=b;
                        activationTime_=c;
                    }
                    public void mouseDown(MouseEvent e) {
                        // time wrap?
                        // check for expiration of doubleClickTime
                        if (shouldFireDoubleClick(activationTime_, e.time, activationEvent_) && e.button is 1) {
                            control_.removeMouseListener(mouseListener);
                            cancelEditing();
                            handleDoubleClickEvent();
                        } else if (mouseListener !is null) {
                            control_.removeMouseListener(mouseListener);
                        }
                    }
                };

                if (activationTime !is 0
                        && (feature & KEEP_EDITOR_ON_DOUBLE_CLICK) is 0) {
                    control.addMouseListener(mouseListener);
                }

                if (tabeditingListener is null) {
                    tabeditingListener = new class TraverseListener {

                        public void keyTraversed(TraverseEvent e) {
                            if ((feature & DEFAULT) !is DEFAULT) {
                                processTraverseEvent(cell.getColumnIndex(),
                                        viewer.getViewerRowFromItem_package(cell
                                                .getItem()), e);
                            }
                        }
                    };
                }

                control.addTraverseListener(tabeditingListener);

                if (editorActivationListener !is null
                        && !editorActivationListener.isEmpty()) {
                    Object[] ls = editorActivationListener.getListeners();
                    for (int i = 0; i < ls.length; i++) {
                        (cast(ColumnViewerEditorActivationListener) ls[i])
                                .afterEditorActivated(activationEvent);
                    }
                }

                this.cell.getItem().addDisposeListener(disposeListener);

                return true;
            }

        }

        return false;
    }

    private bool shouldFireDoubleClick(int activationTime, int mouseTime,
            ColumnViewerEditorActivationEvent activationEvent) {
        return mouseTime <= activationTime
                && activationEvent.eventType !is ColumnViewerEditorActivationEvent.KEY_PRESSED
                && activationEvent.eventType !is ColumnViewerEditorActivationEvent.PROGRAMMATIC
                && activationEvent.eventType !is ColumnViewerEditorActivationEvent.TRAVERSAL;
    }

    /**
     * Applies the current value and deactivates the currently active cell
     * editor.
     */
    void applyEditorValue() {
        // avoid re-entering
        if (!inEditorDeactivation) {
            try {
                inEditorDeactivation = true;
                CellEditor c = this.cellEditor;
                if (c !is null && this.cell !is null) {
                    ColumnViewerEditorDeactivationEvent tmp = new ColumnViewerEditorDeactivationEvent(
                            cell);
                    tmp.eventType = ColumnViewerEditorDeactivationEvent.EDITOR_SAVED;
                    if (editorActivationListener !is null
                            && !editorActivationListener.isEmpty()) {
                        Object[] ls = editorActivationListener.getListeners();
                        for (int i = 0; i < ls.length; i++) {

                            (cast(ColumnViewerEditorActivationListener) ls[i])
                                    .beforeEditorDeactivated(tmp);
                        }
                    }

                    Item t = cast(Item) this.cell.getItem();

                    // don't null out table item -- same item is still selected
                    if (t !is null && !t.isDisposed()) {
                        saveEditorValue(c);
                    }
                    if (!viewer.getControl().isDisposed()) {
                        setEditor(null, null, 0);
                    }

                    c.removeListener(cellEditorListener);
                    Control control = c.getControl();
                    if (control !is null && !control.isDisposed()) {
                        if (mouseListener !is null) {
                            control.removeMouseListener(mouseListener);
                            // Clear the instance not needed any more
                            mouseListener = null;
                        }
                        if (focusListener !is null) {
                            control.removeFocusListener(focusListener);
                        }

                        if (tabeditingListener !is null) {
                            control.removeTraverseListener(tabeditingListener);
                        }
                    }
                    c.deactivate_package(tmp);

                    if (editorActivationListener !is null
                            && !editorActivationListener.isEmpty()) {
                        Object[] ls = editorActivationListener.getListeners();
                        for (int i = 0; i < ls.length; i++) {
                            (cast(ColumnViewerEditorActivationListener) ls[i])
                                    .afterEditorDeactivated(tmp);
                        }
                    }

                    if( ! this.cell.getItem().isDisposed() ) {
                        this.cell.getItem().removeDisposeListener(disposeListener);
                    }
                }

                this.cellEditor = null;
                this.cell = null;
            } finally {
                inEditorDeactivation = false;
            }
        }
    }

    /**
     * Cancel editing
     */
    void cancelEditing() {
        // avoid re-entering
        if (!inEditorDeactivation) {
            try {
                inEditorDeactivation = true;
                if (cellEditor !is null) {
                    ColumnViewerEditorDeactivationEvent tmp = new ColumnViewerEditorDeactivationEvent(
                            cell);
                    tmp.eventType = ColumnViewerEditorDeactivationEvent.EDITOR_CANCELED;
                    if (editorActivationListener !is null
                            && !editorActivationListener.isEmpty()) {
                        Object[] ls = editorActivationListener.getListeners();
                        for (int i = 0; i < ls.length; i++) {

                            (cast(ColumnViewerEditorActivationListener) ls[i])
                                    .beforeEditorDeactivated(tmp);
                        }
                    }

                    if (!viewer.getControl().isDisposed()) {
                        setEditor(null, null, 0);
                    }

                    cellEditor.removeListener(cellEditorListener);

                    Control control = cellEditor.getControl();
                    if (control !is null && !viewer.getControl().isDisposed()) {
                        if (mouseListener !is null) {
                            control.removeMouseListener(mouseListener);
                            // Clear the instance not needed any more
                            mouseListener = null;
                        }
                        if (focusListener !is null) {
                            control.removeFocusListener(focusListener);
                        }

                        if (tabeditingListener !is null) {
                            control.removeTraverseListener(tabeditingListener);
                        }
                    }

                    CellEditor oldEditor = cellEditor;
                    oldEditor.deactivate_package(tmp);

                    if (editorActivationListener !is null
                            && !editorActivationListener.isEmpty()) {
                        Object[] ls = editorActivationListener.getListeners();
                        for (int i = 0; i < ls.length; i++) {
                            (cast(ColumnViewerEditorActivationListener) ls[i])
                                    .afterEditorDeactivated(tmp);
                        }
                    }

                    if( ! this.cell.getItem().isDisposed() ) {
                        this.cell.getItem().addDisposeListener(disposeListener);
                    }

                    this.cellEditor = null;
                    this.cell = null;

                }
            } finally {
                inEditorDeactivation = false;
            }
        }
    }

    /**
     * Enable the editor by mouse down
     *
     * @param event
     */
    void handleEditorActivationEvent(ColumnViewerEditorActivationEvent event) {

        // Only activate if the event isn't tagged as canceled
        if (!event.cancel
                && editorActivationStrategy.isEditorActivationEvent_package(event)) {
            if (cellEditor !is null) {
                applyEditorValue();
            }

            this.cell = cast(ViewerCell) event.getSource();

            if( ! activateCellEditor(event) ) {
                this.cell = null;
                this.cellEditor = null;
            }
        }
    }

    private void saveEditorValue(CellEditor cellEditor) {
        ViewerColumn part = viewer.getViewerColumn(cell.getColumnIndex());

        if (part !is null && part.getEditingSupport() !is null) {
            part.getEditingSupport().saveCellEditorValue_package(cellEditor, cell);
        }
    }

    /**
     * Return whether there is an active cell editor.
     *
     * @return <code>true</code> if there is an active cell editor; otherwise
     *         <code>false</code> is returned.
     */
    bool isCellEditorActive() {
        return cellEditor !is null;
    }

    void handleDoubleClickEvent() {
        viewer.fireDoubleClick_package(new DoubleClickEvent(viewer, viewer
                .getSelection()));
        viewer.fireOpen_package(new OpenEvent(viewer, viewer.getSelection()));
    }

    /**
     * Adds the given listener, it is to be notified when the cell editor is
     * activated or deactivated.
     *
     * @param listener
     *            the listener to add
     */
    public void addEditorActivationListener(
            ColumnViewerEditorActivationListener listener) {
        if (editorActivationListener is null) {
            editorActivationListener = new ListenerList();
        }
        editorActivationListener.add(listener);
    }

    /**
     * Removes the given listener.
     *
     * @param listener
     *            the listener to remove
     */
    public void removeEditorActivationListener(
            ColumnViewerEditorActivationListener listener) {
        if (editorActivationListener !is null) {
            editorActivationListener.remove(listener);
        }
    }

    /**
     * Process the traverse event and opens the next available editor depending
     * of the implemented strategy. The default implementation uses the style
     * constants
     * <ul>
     * <li>{@link ColumnViewerEditor#TABBING_MOVE_TO_ROW_NEIGHBOR}</li>
     * <li>{@link ColumnViewerEditor#TABBING_CYCLE_IN_ROW}</li>
     * <li>{@link ColumnViewerEditor#TABBING_VERTICAL}</li>
     * <li>{@link ColumnViewerEditor#TABBING_HORIZONTAL}</li>
     * </ul>
     *
     * <p>
     * Subclasses may overwrite to implement their custom logic to edit the next
     * cell
     * </p>
     *
     * @param columnIndex
     *            the index of the current column
     * @param row
     *            the current row - may only be used for the duration of this
     *            method call
     * @param event
     *            the traverse event
     */
    protected void processTraverseEvent(int columnIndex, ViewerRow row,
            TraverseEvent event) {

        ViewerCell cell2edit = null;

        if (event.detail is SWT.TRAVERSE_TAB_PREVIOUS) {
            event.doit = false;

            if ((event.stateMask & SWT.CTRL) is SWT.CTRL
                    && (feature & TABBING_VERTICAL) is TABBING_VERTICAL) {
                cell2edit = searchCellAboveBelow(row, viewer, columnIndex, true);
            } else if ((feature & TABBING_HORIZONTAL) is TABBING_HORIZONTAL) {
                cell2edit = searchPreviousCell(row, row.getCell(columnIndex),
                        row.getCell(columnIndex), viewer);
            }
        } else if (event.detail is SWT.TRAVERSE_TAB_NEXT) {
            event.doit = false;

            if ((event.stateMask & SWT.CTRL) is SWT.CTRL
                    && (feature & TABBING_VERTICAL) is TABBING_VERTICAL) {
                cell2edit = searchCellAboveBelow(row, viewer, columnIndex,
                        false);
            } else if ((feature & TABBING_HORIZONTAL) is TABBING_HORIZONTAL) {
                cell2edit = searchNextCell(row, row.getCell(columnIndex), row
                        .getCell(columnIndex), viewer);
            }
        }

        if (cell2edit !is null) {

            viewer.getControl().setRedraw(false);
            ColumnViewerEditorActivationEvent acEvent = new ColumnViewerEditorActivationEvent(
                    cell2edit, event);
            viewer.triggerEditorActivationEvent_package(acEvent);
            viewer.getControl().setRedraw(true);
        }
    }

    private ViewerCell searchCellAboveBelow(ViewerRow row, ColumnViewer viewer,
            int columnIndex, bool above) {
        ViewerCell rv = null;

        ViewerRow newRow = null;

        if (above) {
            newRow = row.getNeighbor(ViewerRow.ABOVE, false);
        } else {
            newRow = row.getNeighbor(ViewerRow.BELOW, false);
        }

        if (newRow !is null) {
            ViewerColumn column = viewer.getViewerColumn(columnIndex);
            if (column !is null
                    && column.getEditingSupport() !is null
                    && column.getEditingSupport().canEdit_package(
                            newRow.getItem().getData())) {
                rv = newRow.getCell(columnIndex);
            } else {
                rv = searchCellAboveBelow(newRow, viewer, columnIndex, above);
            }
        }

        return rv;
    }

    private bool isCellEditable(ColumnViewer viewer, ViewerCell cell) {
        ViewerColumn column = viewer.getViewerColumn(cell.getColumnIndex());
        return column !is null && column.getEditingSupport() !is null
                && column.getEditingSupport().canEdit_package(cell.getElement());
    }

    private ViewerCell searchPreviousCell(ViewerRow row,
            ViewerCell currentCell, ViewerCell originalCell, ColumnViewer viewer) {
        ViewerCell rv = null;
        ViewerCell previousCell;

        if (currentCell !is null) {
            previousCell = currentCell.getNeighbor(ViewerCell.LEFT, true);
        } else {
            if (row.getColumnCount() !is 0) {
                previousCell = row.getCell(row.getCreationIndex_package(row
                        .getColumnCount() - 1));
            } else {
                previousCell = row.getCell(0);
            }

        }

        // No endless loop
        if (originalCell.opEquals(previousCell)) {
            return null;
        }

        if (previousCell !is null) {
            if (isCellEditable(viewer, previousCell)) {
                rv = previousCell;
            } else {
                rv = searchPreviousCell(row, previousCell, originalCell, viewer);
            }
        } else {
            if ((feature & TABBING_CYCLE_IN_ROW) is TABBING_CYCLE_IN_ROW) {
                rv = searchPreviousCell(row, null, originalCell, viewer);
            } else if ((feature & TABBING_MOVE_TO_ROW_NEIGHBOR) is TABBING_MOVE_TO_ROW_NEIGHBOR) {
                ViewerRow rowAbove = row.getNeighbor(ViewerRow.ABOVE, false);
                if (rowAbove !is null) {
                    rv = searchPreviousCell(rowAbove, null, originalCell,
                            viewer);
                }
            }
        }

        return rv;
    }

    private ViewerCell searchNextCell(ViewerRow row, ViewerCell currentCell,
            ViewerCell originalCell, ColumnViewer viewer) {
        ViewerCell rv = null;

        ViewerCell nextCell;

        if (currentCell !is null) {
            nextCell = currentCell.getNeighbor(ViewerCell.RIGHT, true);
        } else {
            nextCell = row.getCell(row.getCreationIndex_package(0));
        }

        // No endless loop
        if (originalCell.opEquals(nextCell)) {
            return null;
        }

        if (nextCell !is null) {
            if (isCellEditable(viewer, nextCell)) {
                rv = nextCell;
            } else {
                rv = searchNextCell(row, nextCell, originalCell, viewer);
            }
        } else {
            if ((feature & TABBING_CYCLE_IN_ROW) is TABBING_CYCLE_IN_ROW) {
                rv = searchNextCell(row, null, originalCell, viewer);
            } else if ((feature & TABBING_MOVE_TO_ROW_NEIGHBOR) is TABBING_MOVE_TO_ROW_NEIGHBOR) {
                ViewerRow rowBelow = row.getNeighbor(ViewerRow.BELOW, false);
                if (rowBelow !is null) {
                    rv = searchNextCell(rowBelow, null, originalCell, viewer);
                }
            }
        }

        return rv;
    }

    /**
     * Position the editor inside the control
     *
     * @param w
     *            the editor control
     * @param item
     *            the item (row) in which the editor is drawn in
     * @param fColumnNumber
     *            the column number in which the editor is shown
     */
    protected abstract void setEditor(Control w, Item item, int fColumnNumber);

    /**
     * set the layout data for the editor
     *
     * @param layoutData
     *            the layout data used when editor is displayed
     */
    protected abstract void setLayoutData(LayoutData layoutData);

    /**
     * @param focusCell
     *            updates the cell with the current input focus
     * @param event
     *            the event requesting to update the focusCell
     */
    protected abstract void updateFocusCell(ViewerCell focusCell,
            ColumnViewerEditorActivationEvent event);

    /**
     * @return the cell currently holding the focus if no cell has the focus or
     *         the viewer implementation doesn't support <code>null</code> is
     *         returned
     *
     */
    public ViewerCell getFocusCell() {
        return null;
    }

    /**
     * @return the viewer working for
     */
    protected ColumnViewer getViewer() {
        return viewer;
    }
}
