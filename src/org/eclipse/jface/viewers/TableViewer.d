/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - concept of ViewerRow,
 *                                                 fix for 159597, refactoring (bug 153993),
 *                                                 widget-independency (bug 154329), fix for 187826, 191468
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TableViewer;

import org.eclipse.jface.viewers.AbstractTableViewer;
import org.eclipse.jface.viewers.TableViewerRow;
import org.eclipse.jface.viewers.ColumnViewerEditor;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.TableViewerEditor;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationStrategy;
import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Set;

/**
 * A concrete viewer based on a SWT <code>Table</code> control.
 * <p>
 * This class is not intended to be subclassed outside the viewer framework. It
 * is designed to be instantiated with a pre-existing SWT table control and
 * configured with a domain-specific content provider, table label provider,
 * element filter (optional), and element sorter (optional).
 * </p>
 * <p>
 * Label providers for table viewers must implement either the
 * <code>ITableLabelProvider</code> or the <code>ILabelProvider</code> interface
 * (see <code>TableViewer.setLabelProvider</code> for more details).
 * </p>
 * <p>
 * As of 3.1 the TableViewer now supports the SWT.VIRTUAL flag. If the
 * underlying table is SWT.VIRTUAL, the content provider may implement {@link
 * ILazyContentProvider} instead of {@link IStructuredContentProvider} . Note
 * that in this case, the viewer does not support sorting or filtering. Also
 * note that in this case, the Widget based APIs may return null if the element
 * is not specified or not created yet.
 * </p>
 * <p>
 * Users of SWT.VIRTUAL should also avoid using getItems() from the Table within
 * the TreeViewer as this does not necessarily generate a callback for the
 * TreeViewer to populate the items. It also has the side effect of creating all
 * of the items thereby eliminating the performance improvements of SWT.VIRTUAL.
 * </p>
 * <p>
 * Users setting up an editable table with more than 1 column <b>have</b> to pass the
 * SWT.FULL_SELECTION style bit
 * </p>
 * 
 * @see SWT#VIRTUAL
 * @see #doFindItem(Object)
 * @see #internalRefresh(Object, bool)
 * @noextend This class is not intended to be subclassed by clients.
 */
public class TableViewer : AbstractTableViewer {
    alias AbstractTableViewer.refresh refresh;
    alias AbstractTableViewer.setSelection setSelection;

    /**
     * This viewer's table control.
     */
    private Table table;

    /**
     * The cached row which is reused all over
     */
    private TableViewerRow cachedRow;

    /**
     * Creates a table viewer on a newly-created table control under the given
     * parent. The table control is created using the SWT style bits
     * <code>MULTI, H_SCROLL, V_SCROLL,</code> and <code>BORDER</code>. The
     * viewer has no input, no content provider, a default label provider, no
     * sorter, and no filters. The table has no columns.
     * 
     * @param parent
     *      the parent control
     */
    public this(Composite parent) {
        this(parent, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.BORDER);
    }

    /**
     * Creates a table viewer on a newly-created table control under the given
     * parent. The table control is created using the given style bits. The
     * viewer has no input, no content provider, a default label provider, no
     * sorter, and no filters. The table has no columns.
     * 
     * @param parent
     *      the parent control
     * @param style
     *      SWT style bits
     */
    public this(Composite parent, int style) {
        this(new Table(parent, style));
    }

    /**
     * Creates a table viewer on the given table control. The viewer has no
     * input, no content provider, a default label provider, no sorter, and no
     * filters.
     * 
     * @param table
     *      the table control
     */
    public this(Table table) {
        this.table = table;
        hookControl(table);
    }

    public override Control getControl() {
        return table;
    }

    /**
     * Returns this table viewer's table control.
     * 
     * @return the table control
     */
    public Table getTable() {
        return table;
    }

    protected override ColumnViewerEditor createViewerEditor() {
        return new TableViewerEditor(this, null,
                new ColumnViewerEditorActivationStrategy(this),
                ColumnViewerEditor.DEFAULT);
    }

    /**
     * <p>
     * Sets a new selection for this viewer and optionally makes it visible. The
     * TableViewer implementation of this method is inefficient for the
     * ILazyContentProvider as lookup is done by indices rather than elements
     * and may require population of the entire table in worse case.
     * </p>
     * <p>
     * Use Table#setSelection(int[] indices) and Table#showSelection() if you
     * wish to set selection more efficiently when using a ILazyContentProvider.
     * </p>
     * 
     * @param selection
     *      the new selection
     * @param reveal
     *      <code>true</code> if the selection is to be made visible, and
     *      <code>false</code> otherwise
     * @see Table#setSelection(int[])
     * @see Table#showSelection()
     */
    public override void setSelection(ISelection selection, bool reveal) {
        super.setSelection(selection, reveal);
    }

    protected override ViewerRow getViewerRowFromItem(Widget item) {
        if (cachedRow is null) {
            cachedRow = new TableViewerRow(cast(TableItem) item);
        } else {
            cachedRow.setItem(cast(TableItem) item);
        }

        return cachedRow;
    }

    /**
     * Create a new row with style at index
     * 
     * @param style
     * @param rowIndex
     * @return ViewerRow
     * @since 3.3
     */
    protected override ViewerRow internalCreateNewRowPart(int style, int rowIndex) {
        TableItem item;

        if (rowIndex >= 0) {
            item = new TableItem(table, style, rowIndex);
        } else {
            item = new TableItem(table, style);
        }

        return getViewerRowFromItem(item);
    }

    protected override Item getItemAt(Point p) {
        TableItem[] selection = table.getSelection();

        if (selection.length is 1) {
            int columnCount = table.getColumnCount();

            for (int i = 0; i < columnCount; i++) {
                if (selection[0].getBounds(i).contains(p)) {
                    return selection[0];
                }
            }
        }

        return table.getItem(p);
    }

    // Methods to provide widget independency

    protected override int doGetItemCount() {
        return table.getItemCount();
    }

    protected override int doIndexOf(Item item) {
        return table.indexOf(cast(TableItem) item);
    }

    protected override void doSetItemCount(int count) {
        table.setItemCount(count);
    }

    protected override Item[] doGetItems() {
        return table.getItems();
    }

    protected override int doGetColumnCount() {
        return table.getColumnCount();
    }

    protected override Widget doGetColumn(int index) {
        return table.getColumn(index);
    }

    protected override Item doGetItem(int index) {
        return table.getItem(index);
    }

    protected override Item[] doGetSelection() {
        return table.getSelection();
    }

    protected override int[] doGetSelectionIndices() {
        return table.getSelectionIndices();
    }

    protected override void doClearAll() {
        table.clearAll();
    }

    protected override void doResetItem(Item item) {
        TableItem tableItem = cast(TableItem) item;
        int columnCount = Math.max(1, table.getColumnCount());
        for (int i = 0; i < columnCount; i++) {
            tableItem.setText(i, ""); //$NON-NLS-1$
            if (tableItem.getImage(i) !is null) {
                tableItem.setImage(i, null);
            }
        }
    }

    protected override void doRemove(int start, int end) {
        table.remove(start, end);
    }

    protected override void doRemoveAll() {
        table.removeAll();
    }

    protected override void doRemove(int[] indices) {
        table.remove(indices);
    }

    protected override void doShowItem(Item item) {
        table.showItem(cast(TableItem) item);
    }

    protected override void doDeselectAll() {
        table.deselectAll();
    }

    protected override void doSetSelection(Item[] items) {
//         Assert.isNotNull(items, "Items-Array can not be null"); //$NON-NLS-1$

        TableItem[] t = new TableItem[items.length];
        System.arraycopy(items, 0, t, 0, t.length);

        table.setSelection(t);
    }

    protected override void doShowSelection() {
        table.showSelection();
    }

    protected override void doSetSelection(int[] indices) {
        table.setSelection(indices);
    }

    protected override void doClear(int index) {
        table.clear(index);
    }

    protected override void doSelect(int[] indices) {
        table.select(indices);
    }

    /**
     * Refreshes this viewer starting with the given element. Labels are updated
     * as described in <code>refresh(bool updateLabels)</code>. The methods
     * attempts to preserve the selection.
     * <p>
     * Unlike the <code>update</code> methods, this handles structural changes
     * to the given element (e.g. addition or removal of children). If only the
     * given element needs updating, it is more efficient to use the
     * <code>update</code> methods.
     * </p>
     * 
     * <p>
     * Subclasses who can provide this feature can open this method for the
     * public
     * </p>
     * 
     * @param element
     *      the element
     * @param updateLabels
     *      <code>true</code> to update labels for existing elements,
     *      <code>false</code> to only update labels as needed, assuming that labels
     *      for existing elements are unchanged.
     * @param reveal
     *      <code>true</code> to make the preserved selection visible afterwards
     * 
     * @since 3.3
     */
    public void refresh(Object element, bool updateLabels,
            bool reveal) {
        if (checkBusy())
            return;

        if (isCellEditorActive()) {
            cancelEditing();
        }

        preservingSelection(new class(element,updateLabels) Runnable {
            Object element_;
            bool updateLabels_;
            this(Object a,bool b){
                element_ = a;
                updateLabels_ = b;
            }
            public void run() {
                internalRefresh(element_, updateLabels_);
            }
        }, reveal);
    }

    /**
     * Refreshes this viewer with information freshly obtained from this
     * viewer's model. If <code>updateLabels</code> is <code>true</code> then
     * labels for otherwise unaffected elements are updated as well. Otherwise,
     * it assumes labels for existing elements are unchanged, and labels are
     * only obtained as needed (for example, for new elements).
     * <p>
     * Calling <code>refresh(true)</code> has the same effect as
     * <code>refresh()</code>.
     * <p>
     * Note that the implementation may still obtain labels for existing
     * elements even if <code>updateLabels</code> is false. The intent is simply
     * to allow optimization where possible.
     * 
     * @param updateLabels
     *      <code>true</code> to update labels for existing elements,
     *      <code>false</code> to only update labels as needed, assuming that labels
     *      for existing elements are unchanged.
     * @param reveal
     *      <code>true</code> to make the preserved selection visible afterwards
     * 
     * @since 3.3
     */
    public void refresh(bool updateLabels, bool reveal) {
        refresh(getRoot(), updateLabels, reveal);
    }
}
