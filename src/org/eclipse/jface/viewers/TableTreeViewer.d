/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - bug 153993
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TableTreeViewer;

import org.eclipse.jface.viewers.AbstractTreeViewer;
import org.eclipse.jface.viewers.CellEditor;
import org.eclipse.jface.viewers.ICellEditorListener;
import org.eclipse.jface.viewers.ICellModifier;
import org.eclipse.jface.viewers.ColumnViewer;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.DoubleClickEvent;
import org.eclipse.jface.viewers.OpenEvent;
import org.eclipse.jface.viewers.ITableLabelProvider;
import org.eclipse.jface.viewers.ViewerLabel;


import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.TableTree;
import org.eclipse.swt.custom.TableTreeEditor;
import org.eclipse.swt.custom.TableTreeItem;
import org.eclipse.swt.events.FocusAdapter;
import org.eclipse.swt.events.FocusEvent;
import org.eclipse.swt.events.FocusListener;
import org.eclipse.swt.events.MouseAdapter;
import org.eclipse.swt.events.MouseEvent;
import org.eclipse.swt.events.MouseListener;
import org.eclipse.swt.events.TreeListener;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Widget;

import java.lang.all;
import java.util.List;
import java.util.Set;

/**
 * A concrete viewer based on a SWT <code>TableTree</code> control.
 * <p>
 * This class is not intended to be subclassed outside the viewer framework. It
 * is designed to be instantiated with a pre-existing SWT table tree control and
 * configured with a domain-specific content provider, label provider, element
 * filter (optional), and element sorter (optional).
 * </p>
 * <p>
 * Content providers for table tree viewers must implement the
 * <code>ITreeContentProvider</code> interface.
 * </p>
 * <p>
 * Label providers for table tree viewers must implement either the
 * <code>ITableLabelProvider</code> or the <code>ILabelProvider</code>
 * interface (see <code>TableTreeViewer.setLabelProvider</code> for more
 * details).
 * </p>
 *
 * @deprecated As of 3.1 use {@link TreeViewer} instead
 * @noextend This class is not intended to be subclassed by clients.
 */
public class TableTreeViewer : AbstractTreeViewer {
    alias AbstractTreeViewer.addTreeListener addTreeListener;
    alias AbstractTreeViewer.doUpdateItem doUpdateItem;
    alias AbstractTreeViewer.getLabelProvider getLabelProvider;
    alias AbstractTreeViewer.getSelection getSelection;
    alias AbstractTreeViewer.setSelection setSelection;

    /**
     * Internal table viewer implementation.
     */
    private TableTreeEditorImpl tableEditorImpl;

    /**
     * This viewer's table tree control.
     */
    private TableTree tableTree;

    /**
     * This viewer's table tree editor.
     */
    private TableTreeEditor tableTreeEditor;

    /**
     * Copied from original TableEditorImpl and moved here since refactoring
     * completely wiped out the original implementation in 3.3
     *
     * @since 3.1
     */
    class TableTreeEditorImpl {

        private CellEditor cellEditor;

        private CellEditor[] cellEditors;

        private ICellModifier cellModifier;

        private String[] columnProperties;

        private Item tableItem;

        private int columnNumber;

        private ICellEditorListener cellEditorListener;

        private FocusListener focusListener;

        private MouseListener mouseListener;

        private int doubleClickExpirationTime;

        private ColumnViewer viewer;

        private this(ColumnViewer viewer) {
            this.viewer = viewer;
            initCellEditorListener();
        }

        /**
         * Returns this <code>TableViewerImpl</code> viewer
         *
         * @return the viewer
         */
        public ColumnViewer getViewer() {
            return viewer;
        }

        private void activateCellEditor() {
            if( cellEditors !is null ) {
                if( cellEditors[columnNumber] !is null && cellModifier !is null ) {
                    Object element = tableItem.getData();
                    String property = columnProperties[columnNumber];

                    if( cellModifier.canModify(element, property) ) {
                        cellEditor = cellEditors[columnNumber];

                        cellEditor.addListener(cellEditorListener);

                        Object value = cellModifier.getValue(element, property);
                        cellEditor.setValue(value);
                        // Tricky flow of control here:
                        // activate() can trigger callback to cellEditorListener
                        // which will clear cellEditor
                        // so must get control first, but must still call activate()
                        // even if there is no control.
                        final Control control = cellEditor.getControl();
                        cellEditor.activate();
                        if (control is null) {
                            return;
                        }
                        setLayoutData(cellEditor.getLayoutData());
                        setEditor(control, tableItem, columnNumber);
                        cellEditor.setFocus();
                        if (focusListener is null) {
                            focusListener = new class FocusAdapter {
                                public void focusLost(FocusEvent e) {
                                    applyEditorValue();
                                }
                            };
                        }
                        control.addFocusListener(focusListener);
                        mouseListener = new class(control) MouseAdapter {
                            Control control_;
                            this(Control a){
                                control_=a;
                            }
                            public void mouseDown(MouseEvent e) {
                                // time wrap?
                                // check for expiration of doubleClickTime
                                if (e.time <= doubleClickExpirationTime) {
                                    control_.removeMouseListener(mouseListener);
                                    cancelEditing();
                                    handleDoubleClickEvent();
                                } else if (mouseListener !is null) {
                                    control_.removeMouseListener(mouseListener);
                                }
                            }
                        };
                        control.addMouseListener(mouseListener);
                    }
                }
            }
        }

        /**
         * Activate a cell editor for the given mouse position.
         */
        private void activateCellEditor(MouseEvent event) {
            if (tableItem is null || tableItem.isDisposed()) {
                // item no longer exists
                return;
            }
            int columnToEdit;
            int columns = getColumnCount();
            if (columns is 0) {
                // If no TableColumn, Table acts as if it has a single column
                // which takes the whole width.
                columnToEdit = 0;
            } else {
                columnToEdit = -1;
                for (int i = 0; i < columns; i++) {
                    Rectangle bounds = getBounds(tableItem, i);
                    if (bounds.contains(event.x, event.y)) {
                        columnToEdit = i;
                        break;
                    }
                }
                if (columnToEdit is -1) {
                    return;
                }
            }

            columnNumber = columnToEdit;
            activateCellEditor();
        }

        /**
         * Deactivates the currently active cell editor.
         */
        public void applyEditorValue() {
            CellEditor c = this.cellEditor;
            if (c !is null) {
                // null out cell editor before calling save
                // in case save results in applyEditorValue being re-entered
                // see 1GAHI8Z: ITPUI:ALL - How to code event notification when
                // using cell editor ?
                this.cellEditor = null;
                Item t = this.tableItem;
                // don't null out table item -- same item is still selected
                if (t !is null && !t.isDisposed()) {
                    saveEditorValue(c, t);
                }
                setEditor(null, null, 0);
                c.removeListener(cellEditorListener);
                Control control = c.getControl();
                if (control !is null) {
                    if (mouseListener !is null) {
                        control.removeMouseListener(mouseListener);
                    }
                    if (focusListener !is null) {
                        control.removeFocusListener(focusListener);
                    }
                }
                c.deactivate();
            }
        }

        /**
         * Cancels the active cell editor, without saving the value back to the
         * domain model.
         */
        public void cancelEditing() {
            if (cellEditor !is null) {
                setEditor(null, null, 0);
                cellEditor.removeListener(cellEditorListener);
                CellEditor oldEditor = cellEditor;
                cellEditor = null;
                oldEditor.deactivate();
            }
        }

        /**
         * Start editing the given element.
         *
         * @param element
         * @param column
         */
        public void editElement(Object element, int column) {
            if (cellEditor !is null) {
                applyEditorValue();
            }

            setSelection(new StructuredSelection(element), true);
            Item[] selection = getSelection();
            if (selection.length !is 1) {
                return;
            }

            tableItem = selection[0];

            // Make sure selection is visible
            showSelection();
            columnNumber = column;
            activateCellEditor();

        }

        /**
         * Return the array of CellEditors used in the viewer
         *
         * @return the cell editors
         */
        public CellEditor[] getCellEditors() {
            return cellEditors;
        }

        /**
         * Get the cell modifier
         *
         * @return the cell modifier
         */
        public ICellModifier getCellModifier() {
            return cellModifier;
        }

        /**
         * Return the properties for the column
         *
         * @return the array of column properties
         */
        public Object[] getColumnProperties() {
            return stringcast( columnProperties );
        }

        /**
         * Handles the mouse down event; activates the cell editor.
         *
         * @param event
         *            the mouse event that should be handled
         */
        public void handleMouseDown(MouseEvent event) {
            if (event.button !is 1) {
                return;
            }

            if (cellEditor !is null) {
                applyEditorValue();
            }

            // activate the cell editor immediately. If a second mouseDown
            // is received prior to the expiration of the doubleClick time then
            // the cell editor will be deactivated and a doubleClick event will
            // be processed.
            //
            doubleClickExpirationTime = event.time
                    + Display.getCurrent().getDoubleClickTime();

            Item[] items = getSelection();
            // Do not edit if more than one row is selected.
            if (items.length !is 1) {
                tableItem = null;
                return;
            }
            tableItem = items[0];

            activateCellEditor(event);
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

        /**
         * Return whether there is an active cell editor.
         *
         * @return <code>true</code> if there is an active cell editor;
         *         otherwise <code>false</code> is returned.
         */
        public bool isCellEditorActive() {
            return cellEditor !is null;
        }

        /**
         * Saves the value of the currently active cell editor, by delegating to
         * the cell modifier.
         */
        private void saveEditorValue(CellEditor cellEditor, Item tableItem) {
            if( cellModifier !is null ) {
                if( ! cellEditor.isValueValid() ) {
                    // Do what????
                }
            }
            String property = null;

            if( columnProperties !is null && columnNumber < columnProperties.length ) {
                property = columnProperties[columnNumber];
            }
            cellModifier.modify(tableItem, property, cellEditor.getValue());
        }

        /**
         * Set the cell editors
         *
         * @param editors
         */
        public void setCellEditors(CellEditor[] editors) {
            this.cellEditors = editors;
        }

        /**
         * Set the cell modifier
         *
         * @param modifier
         */
        public void setCellModifier(ICellModifier modifier) {
            this.cellModifier = modifier;
        }

        /**
         * Set the column properties
         *
         * @param columnProperties
         */
        public void setColumnProperties(String[] columnProperties) {
            this.columnProperties = columnProperties;
        }

        Rectangle getBounds(Item item, int columnNumber) {
            return (cast(TableTreeItem) item).getBounds(columnNumber);
        }

        int getColumnCount() {
            // getColumnCount() should be a API in TableTree.
            return getTableTree().getTable().getColumnCount();
        }

        Item[] getSelection() {
            return getTableTree().getSelection();
        }

        void setEditor(Control w, Item item, int columnNumber) {
            tableTreeEditor.setEditor(w, cast(TableTreeItem) item, columnNumber);
        }

        void setSelection(StructuredSelection selection, bool b) {
            this.outer.setSelection(selection, b);
        }

        void showSelection() {
            getTableTree().showSelection();
        }

        void setLayoutData(LayoutData layoutData) {
            tableTreeEditor.horizontalAlignment = layoutData.horizontalAlignment;
            tableTreeEditor.grabHorizontal = layoutData.grabHorizontal;
            tableTreeEditor.minimumWidth = layoutData.minimumWidth;
        }

        void handleDoubleClickEvent() {
            Viewer viewer = getViewer();
            fireDoubleClick(new DoubleClickEvent(viewer, viewer.getSelection()));
            fireOpen(new OpenEvent(viewer, viewer.getSelection()));
        }
    }

    /**
     * Creates a table tree viewer on the given table tree control. The viewer
     * has no input, no content provider, a default label provider, no sorter,
     * and no filters.
     *
     * @param tree
     *            the table tree control
     */
    public this(TableTree tree) {
        super();
        tableTree = tree;
        hookControl(tree);
        tableTreeEditor = new TableTreeEditor(tableTree);
        tableEditorImpl = new TableTreeEditorImpl(this);
    }

    /**
     * Creates a table tree viewer on a newly-created table tree control under
     * the given parent. The table tree control is created using the SWT style
     * bits <code>MULTI, H_SCROLL, V_SCROLL, and BORDER</code>. The viewer
     * has no input, no content provider, a default label provider, no sorter,
     * and no filters.
     *
     * @param parent
     *            the parent control
     */
    public this(Composite parent) {
        this(parent, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.BORDER);
    }

    /**
     * Creates a table tree viewer on a newly-created table tree control under
     * the given parent. The table tree control is created using the given SWT
     * style bits. The viewer has no input, no content provider, a default label
     * provider, no sorter, and no filters.
     *
     * @param parent
     *            the parent control
     * @param style
     *            the SWT style bits
     */
    public this(Composite parent, int style) {
        this(new TableTree(parent, style));
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override void addTreeListener(Control c, TreeListener listener) {
        (cast(TableTree) c).addTreeListener(listener);
    }

    /**
     * Cancels a currently active cell editor. All changes already done in the
     * cell editor are lost.
     */
    public override void cancelEditing() {
        tableEditorImpl.cancelEditing();
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override void doUpdateItem(Item item, Object element) {
        // update icon and label
        // Similar code in TableTreeViewer.doUpdateItem()
        IBaseLabelProvider prov = getLabelProvider();
        ITableLabelProvider tprov = null;

        if ( auto t = cast(ITableLabelProvider) prov ) {
            tprov = t;
        }

        int columnCount = tableTree.getTable().getColumnCount();
        TableTreeItem ti = cast(TableTreeItem) item;
        // Also enter loop if no columns added. See 1G9WWGZ: JFUIF:WINNT -
        // TableViewer with 0 columns does not work
        for (int column = 0; column < columnCount || column is 0; column++) {
            String text = "";//$NON-NLS-1$
            Image image = null;
            if (tprov !is null) {
                text = tprov.getColumnText(element, column);
                image = tprov.getColumnImage(element, column);
            } else {
                if (column is 0) {
                    ViewerLabel updateLabel = new ViewerLabel(item.getText(),
                            item.getImage());
                    buildLabel(updateLabel, element);

                    // As it is possible for user code to run the event
                    // loop check here.
                    if (item.isDisposed()) {
                        unmapElement(element, item);
                        return;
                    }

                    text = updateLabel.getText();
                    image = updateLabel.getImage();
                }
            }

            // Avoid setting text to null
            if (text is null) {
                text = ""; //$NON-NLS-1$
            }

            ti.setText(column, text);
            // Apparently a problem to setImage to null if already null
            if (ti.getImage(column) !is image) {
                ti.setImage(column, image);
            }

            getColorAndFontCollector().setFontsAndColors(element);
            getColorAndFontCollector().applyFontsAndColors(ti);
        }

    }

    /**
     * Starts editing the given element.
     *
     * @param element
     *            the element
     * @param column
     *            the column number
     */
    public override void editElement(Object element, int column) {
        tableEditorImpl.editElement(element, column);
    }

    /**
     * Returns the cell editors of this viewer.
     *
     * @return the list of cell editors
     */
    public override CellEditor[] getCellEditors() {
        return tableEditorImpl.getCellEditors();
    }

    /**
     * Returns the cell modifier of this viewer.
     *
     * @return the cell modifier
     */
    public override ICellModifier getCellModifier() {
        return tableEditorImpl.getCellModifier();
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override Item[] getChildren(Widget o) {
        if (auto i = cast(TableTreeItem) o ) {
            return i.getItems();
        }
        if (auto i = cast(TableTree) o ) {
            return i.getItems();
        }
        return null;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#getChild(org.eclipse.swt.widgets.Widget,
     *      int)
     */
    protected override Item getChild(Widget widget, int index) {
        if (auto w = cast(TableTreeItem) widget ) {
            return w.getItem(index);
        }
        if (auto w = cast(TableTree) widget ) {
            return w.getItem(index);
        }
        return null;
    }

    /**
     * Returns the column properties of this viewer. The properties must
     * correspond with the columns of the table control. They are used to
     * identify the column in a cell modifier.
     *
     * @return the list of column properties
     */
    public override Object[] getColumnProperties() {
        return tableEditorImpl.getColumnProperties();
    }

    /*
     * (non-Javadoc) Method declared on Viewer.
     */
    public override Control getControl() {
        return tableTree;
    }

    /**
     * Returns the element with the given index from this viewer. Returns
     * <code>null</code> if the index is out of range.
     * <p>
     * This method is internal to the framework.
     * </p>
     *
     * @param index
     *            the zero-based index
     * @return the element at the given index, or <code>null</code> if the
     *         index is out of range
     */
    public Object getElementAt(int index) {
        // XXX: Workaround for 1GBCSB1: SWT:WIN2000 - TableTree should have
        // getItem(int index)
        TableTreeItem i = tableTree.getItems()[index];
        if (i !is null) {
            return i.getData();
        }
        return null;
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override bool getExpanded(Item item) {
        return (cast(TableTreeItem) item).getExpanded();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ColumnViewer#getItemAt(org.eclipse.swt.graphics.Point)
     */
    protected override Item getItemAt(Point p) {
        return getTableTree().getTable().getItem(p);
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override int getItemCount(Control widget) {
        return (cast(TableTree) widget).getItemCount();
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override int getItemCount(Item item) {
        return (cast(TableTreeItem) item).getItemCount();
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override org.eclipse.swt.widgets.Item.Item[] getItems(
            org.eclipse.swt.widgets.Item.Item item) {
        return (cast(TableTreeItem) item).getItems();
    }

    /**
     * The table tree viewer implementation of this <code>Viewer</code>
     * framework method returns the label provider, which in the case of table
     * tree viewers will be an instance of either
     * <code>ITableLabelProvider</code> or <code>ILabelProvider</code>. If
     * it is an <code>ITableLabelProvider</code>, then it provides a separate
     * label text and image for each column. If it is an
     * <code>ILabelProvider</code>, then it provides only the label text and
     * image for the first column, and any remaining columns are blank.
     */
    public override IBaseLabelProvider getLabelProvider() {
        return super.getLabelProvider();
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override Item getParentItem(Item item) {
        return (cast(TableTreeItem) item).getParentItem();
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override Item[] getSelection(Control widget) {
        return (cast(TableTree) widget).getSelection();
    }

    /**
     * Returns this table tree viewer's table tree control.
     *
     * @return the table tree control
     */
    public TableTree getTableTree() {
        return tableTree;
    }

    /*
     * (non-Javadoc) Method declared on AbstractTreeViewer.
     */
    protected override void hookControl(Control control) {
        super.hookControl(control);
        tableTree.getTable().addMouseListener(new class MouseAdapter {
            public void mouseDown(MouseEvent e) {
                /*
                 * If user clicked on the [+] or [-], do not activate
                 * CellEditor.
                 */
                // XXX: This code should not be here. SWT should either have
                // support to see
                // if the user clicked on the [+]/[-] or manage the table editor
                // activation
                org.eclipse.swt.widgets.TableItem.TableItem[] items = tableTree
                        .getTable().getItems();
                for (int i = 0; i < items.length; i++) {
                    Rectangle rect = items[i].getImageBounds(0);
                    if (rect.contains(e.x, e.y)) {
                        return;
                    }
                }

                tableEditorImpl.handleMouseDown(e);
            }
        });
    }

    /**
     * Returns whether there is an active cell editor.
     *
     * @return <code>true</code> if there is an active cell editor, and
     *         <code>false</code> otherwise
     */
    public override bool isCellEditorActive() {
        return tableEditorImpl.isCellEditorActive();
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override Item newItem(Widget parent, int flags, int ix) {
        TableTreeItem item;
        if (ix >= 0) {
            if (cast(TableTreeItem) parent ) {
                item = new TableTreeItem(cast(TableTreeItem) parent, flags, ix);
            } else {
                item = new TableTreeItem(cast(TableTree) parent, flags, ix);
            }
        } else {
            if (cast(TableTreeItem)parent ) {
                item = new TableTreeItem(cast(TableTreeItem) parent, flags);
            } else {
                item = new TableTreeItem(cast(TableTree) parent, flags);
            }
        }
        return item;
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void removeAll(Control widget) {
        (cast(TableTree) widget).removeAll();
    }

    /**
     * Sets the cell editors of this table viewer.
     *
     * @param editors
     *            the list of cell editors
     */
    public override void setCellEditors(CellEditor[] editors) {
        tableEditorImpl.setCellEditors(editors);
    }

    /**
     * Sets the cell modifier of this table viewer.
     *
     * @param modifier
     *            the cell modifier
     */
    public override void setCellModifier(ICellModifier modifier) {
        tableEditorImpl.setCellModifier(modifier);
    }

    /**
     * Sets the column properties of this table viewer. The properties must
     * correspond with the columns of the table control. They are used to
     * identify the column in a cell modifier.
     *
     * @param columnProperties
     *            the list of column properties
     */
    public override void setColumnProperties(String[] columnProperties) {
        tableEditorImpl.setColumnProperties(columnProperties);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void setExpanded(Item node, bool expand) {
        (cast(TableTreeItem) node).setExpanded(expand);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void setSelection(List items) {
        TableTreeItem[] newItems = arraycast!(TableTreeItem)(items.toArray());
        getTableTree().setSelection(newItems);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void showItem(Item item) {
        getTableTree().showItem(cast(TableTreeItem) item);
    }
}
