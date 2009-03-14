/*******************************************************************************
 * Copyright (c) 2004, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - concept of ViewerRow,
 *                                                 refactoring (bug 153993), bug 167323, 191468, 205419
 *     Matthew Hall - bug 221988
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TreeViewer;

import org.eclipse.jface.viewers.AbstractTreeViewer;
import org.eclipse.jface.viewers.TreeViewerRow;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.ColumnViewerEditor;
import org.eclipse.jface.viewers.IContentProvider;
import org.eclipse.jface.viewers.TreeSelection;
import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.TreeViewerEditor;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationStrategy;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationEvent;
import org.eclipse.jface.viewers.ILazyTreeContentProvider;
import org.eclipse.jface.viewers.ILazyTreePathContentProvider;
import org.eclipse.jface.viewers.TreePath;
import org.eclipse.jface.viewers.TreeExpansionEvent;
import org.eclipse.jface.viewers.ViewerCell;


import org.eclipse.swt.SWT;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.events.TreeEvent;
import org.eclipse.swt.events.TreeListener;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.jface.util.Policy;

import java.lang.all;
import java.util.Arrays;
import java.util.List;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.Set;

/**
 * A concrete viewer based on an SWT <code>Tree</code> control.
 * <p>
 * This class is not intended to be subclassed outside the viewer framework. It
 * is designed to be instantiated with a pre-existing SWT tree control and
 * configured with a domain-specific content provider, label provider, element
 * filter (optional), and element sorter (optional).
 * </p>
 * <p>
 * Content providers for tree viewers must implement either the
 * {@link ITreeContentProvider} interface, (as of 3.2) the
 * {@link ILazyTreeContentProvider} interface, or (as of 3.3) the
 * {@link ILazyTreePathContentProvider}. If the content provider is an
 * <code>ILazyTreeContentProvider</code> or an
 * <code>ILazyTreePathContentProvider</code>, the underlying Tree must be
 * created using the {@link SWT#VIRTUAL} style bit, the tree viewer will not
 * support sorting or filtering, and hash lookup must be enabled by calling
 * {@link #setUseHashlookup(bool)}.
 * </p>
 * <p>
 * Users setting up an editable tree with more than 1 column <b>have</b> to pass the
 * SWT.FULL_SELECTION style bit
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class TreeViewer : AbstractTreeViewer {
    alias AbstractTreeViewer.addTreeListener addTreeListener;
    alias AbstractTreeViewer.getLabelProvider getLabelProvider;
    alias AbstractTreeViewer.getSelection getSelection;
    alias AbstractTreeViewer.preservingSelection preservingSelection;
    alias AbstractTreeViewer.remove remove;
    alias AbstractTreeViewer.setSelection setSelection;

    private static final String VIRTUAL_DISPOSE_KEY = Policy.JFACE
            ~ ".DISPOSE_LISTENER"; //$NON-NLS-1$

    /**
     * This viewer's control.
     */
    private Tree tree;

    /**
     * Flag for whether the tree has been disposed of.
     */
    private bool treeIsDisposed = false;

    private bool contentProviderIsLazy;

    private bool contentProviderIsTreeBased;

    /**
     * The row object reused
     */
    private TreeViewerRow cachedRow;

    /**
     * true if we are inside a preservingSelection() call
     */
    private bool preservingSelection_;

    /**
     * Creates a tree viewer on a newly-created tree control under the given
     * parent. The tree control is created using the SWT style bits
     * <code>MULTI, H_SCROLL, V_SCROLL,</code> and <code>BORDER</code>. The
     * viewer has no input, no content provider, a default label provider, no
     * sorter, and no filters.
     *
     * @param parent
     *            the parent control
     */
    public this(Composite parent) {
        this(parent, SWT.MULTI | SWT.H_SCROLL | SWT.V_SCROLL | SWT.BORDER);
    }

    /**
     * Creates a tree viewer on a newly-created tree control under the given
     * parent. The tree control is created using the given SWT style bits. The
     * viewer has no input, no content provider, a default label provider, no
     * sorter, and no filters.
     *
     * @param parent
     *            the parent control
     * @param style
     *            the SWT style bits used to create the tree.
     */
    public this(Composite parent, int style) {
        this(new Tree(parent, style));
    }

    /**
     * Creates a tree viewer on the given tree control. The viewer has no input,
     * no content provider, a default label provider, no sorter, and no filters.
     *
     * @param tree
     *            the tree control
     */
    public this(Tree tree) {
        super();
        this.tree = tree;
        hookControl(tree);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void addTreeListener(Control c, TreeListener listener) {
        (cast(Tree) c).addTreeListener(listener);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ColumnViewer#getColumnViewerOwner(int)
     */
    protected override Widget getColumnViewerOwner(int columnIndex) {
        if (columnIndex < 0 || ( columnIndex > 0 && columnIndex >= getTree().getColumnCount() ) ) {
            return null;
        }

        if (getTree().getColumnCount() is 0)// Hang it off the table if it
            return getTree();

        return getTree().getColumn(columnIndex);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override Item[] getChildren(Widget o) {
        if (auto ti = cast(TreeItem)o ) {
            return ti.getItems();
        }
        if (auto t = cast(Tree)o ) {
            return t.getItems();
        }
        return null;
    }

    /*
     * (non-Javadoc) Method declared in Viewer.
     */
    public override Control getControl() {
        return tree;
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override bool getExpanded(Item item) {
        return (cast(TreeItem) item).getExpanded();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ColumnViewer#getItemAt(org.eclipse.swt.graphics.Point)
     */
    protected override Item getItemAt(Point p) {
        TreeItem[] selection = tree.getSelection();

        if( selection.length is 1 ) {
            int columnCount = tree.getColumnCount();

            for( int i = 0; i < columnCount; i++ ) {
                if( selection[0].getBounds(i).contains(p) ) {
                    return selection[0];
                }
            }
        }

        return getTree().getItem(p);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override int getItemCount(Control widget) {
        return (cast(Tree) widget).getItemCount();
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override int getItemCount(Item item) {
        return (cast(TreeItem) item).getItemCount();
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override Item[] getItems(Item item) {
        return (cast(TreeItem) item).getItems();
    }

    /**
     * The tree viewer implementation of this <code>Viewer</code> framework
     * method ensures that the given label provider is an instance of either
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
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override Item getParentItem(Item item) {
        return (cast(TreeItem) item).getParentItem();
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override Item[] getSelection(Control widget) {
        return (cast(Tree) widget).getSelection();
    }

    /**
     * Returns this tree viewer's tree control.
     *
     * @return the tree control
     */
    public Tree getTree() {
        return tree;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#hookControl(org.eclipse.swt.widgets.Control)
     */
    protected override void hookControl(Control control) {
        super.hookControl(control);
        Tree treeControl = cast(Tree) control;

        if ((treeControl.getStyle() & SWT.VIRTUAL) !is 0) {
            treeControl.addDisposeListener(new class DisposeListener {
                public void widgetDisposed(DisposeEvent e) {
                    treeIsDisposed = true;
                    unmapAllElements();
                }
            });
            treeControl.addListener(SWT.SetData, new class Listener {

                public void handleEvent(Event event) {
                    if (contentProviderIsLazy) {
                        TreeItem item = cast(TreeItem) event.item;
                        TreeItem parentItem = item.getParentItem();
                        int index = event.index;
                        virtualLazyUpdateWidget(
                                parentItem is null ? cast(Widget) getTree()
                                        : parentItem, index);
                    }
                }

            });
        }
    }

    protected override ColumnViewerEditor createViewerEditor() {
        return new TreeViewerEditor(this,null,new ColumnViewerEditorActivationStrategy(this),ColumnViewerEditor.DEFAULT);
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override Item newItem(Widget parent, int flags, int ix) {
        TreeItem item;

        if ( cast(TreeItem)parent ) {
            item = cast(TreeItem) createNewRowPart(getViewerRowFromItem(parent),
                    flags, ix).getItem();
        } else {
            item = cast(TreeItem) createNewRowPart(null, flags, ix).getItem();
        }

        return item;
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void removeAll(Control widget) {
        (cast(Tree) widget).removeAll();
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void setExpanded(Item node, bool expand) {
        (cast(TreeItem) node).setExpanded(expand);
        if (contentProviderIsLazy) {
            // force repaints to happen
            getControl().update();
        }
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void setSelection(List items) {

        Item[] current = getSelection(getTree());

        // Don't bother resetting the same selection
        if (isSameSelection(items, current)) {
            return;
        }

        getTree().setSelection( arraycast!(TreeItem)( items.toArray()));
    }

    /*
     * (non-Javadoc) Method declared in AbstractTreeViewer.
     */
    protected override void showItem(Item item) {
        getTree().showItem(cast(TreeItem) item);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#getChild(org.eclipse.swt.widgets.Widget,
     *      int)
     */
    protected override Item getChild(Widget widget, int index) {
        if (auto ti = cast(TreeItem)widget ) {
            return ti.getItem(index);
        }
        if (auto t = cast(Tree)widget ) {
            return t.getItem(index);
        }
        return null;
    }

    protected override void assertContentProviderType(IContentProvider provider) {
        if ( null !is cast(ILazyTreeContentProvider)provider
                || null !is cast(ILazyTreePathContentProvider)provider ) {
            return;
        }
        super.assertContentProviderType(provider);
    }

    protected override Object[] getRawChildren(Object parent) {
        if (contentProviderIsLazy) {
            return new Object[0];
        }
        return super.getRawChildren(parent);
    }

    override void preservingSelection(Runnable updateCode, bool reveal) {
        if (preservingSelection_){
            // avoid preserving the selection if called reentrantly,
            // see bug 172640
            updateCode.run();
            return;
        }
        preservingSelection_ = true;
        try {
            super.preservingSelection(updateCode, reveal);
        } finally {
            preservingSelection_ = false;
        }
    }

    /**
     * For a TreeViewer with a tree with the VIRTUAL style bit set, set the
     * number of children of the given element or tree path. To set the number
     * of children of the invisible root of the tree, you can pass the input
     * object or an empty tree path.
     *
     * @param elementOrTreePath
     *            the element, or tree path
     * @param count
     *
     * @since 3.2
     */
    public void setChildCount(Object elementOrTreePath, int count) {
        if (checkBusy())
            return;
        preservingSelection( dgRunnable((Object elementOrTreePath_, int count_) {
            if (internalIsInputOrEmptyPath(elementOrTreePath_)) {
                getTree().setItemCount(count_);
                return;
            }
            Widget[] items = internalFindItems(elementOrTreePath_);
            for (int i = 0; i < items.length; i++) {
                TreeItem treeItem = cast(TreeItem) items[i];
                treeItem.setItemCount(count_);
            }
        }, elementOrTreePath,count ));
    }

    /**
     * For a TreeViewer with a tree with the VIRTUAL style bit set, replace the
     * given parent's child at index with the given element. If the given parent
     * is this viewer's input or an empty tree path, this will replace the root
     * element at the given index.
     * <p>
     * This method should be called by implementers of ILazyTreeContentProvider
     * to populate this viewer.
     * </p>
     *
     * @param parentElementOrTreePath
     *            the parent of the element that should be updated, or the tree
     *            path to that parent
     * @param index
     *            the index in the parent's children
     * @param element
     *            the new element
     *
     * @see #setChildCount(Object, int)
     * @see ILazyTreeContentProvider
     * @see ILazyTreePathContentProvider
     *
     * @since 3.2
     */
    public void replace(Object parentElementOrTreePath, int index,
            Object element) {
        if (checkBusy())
            return;
        Item[] selectedItems = getSelection(getControl());
        TreeSelection selection = cast(TreeSelection) getSelection();
        Widget[] itemsToDisassociate;
        if (auto tp = cast(TreePath)parentElementOrTreePath ) {
            TreePath elementPath = tp
                    .createChildPath(element);
            itemsToDisassociate = internalFindItems(elementPath);
        } else {
            itemsToDisassociate = internalFindItems(element);
        }
        if (internalIsInputOrEmptyPath(parentElementOrTreePath)) {
            if (index < tree.getItemCount()) {
                TreeItem item = tree.getItem(index);
                selection = adjustSelectionForReplace(selectedItems, selection, item, element, getRoot());
                // disassociate any different item that represents the
                // same element under the same parent (the tree)
                for (int i = 0; i < itemsToDisassociate.length; i++) {
                    if (auto itemToDisassociate = cast(TreeItem)itemsToDisassociate[i]) {
                        if (itemToDisassociate !is item
                                && itemToDisassociate.getParentItem() is null) {
                            int indexToDisassociate = getTree().indexOf(
                                    itemToDisassociate);
                            disassociate(itemToDisassociate);
                            getTree().clear(indexToDisassociate, true);
                        }
                    }
                }
                Object oldData = item.getData();
                updateItem(item, element);
                if (!/+TreeViewer.this.+/opEquals(oldData, element)) {
                    item.clearAll(true);
                }
            }
        } else {
            Widget[] parentItems = internalFindItems(parentElementOrTreePath);
            for (int i = 0; i < parentItems.length; i++) {
                TreeItem parentItem = cast(TreeItem) parentItems[i];
                if (index < parentItem.getItemCount()) {
                    TreeItem item = parentItem.getItem(index);
                    selection = adjustSelectionForReplace(selectedItems, selection, item, element, parentItem.getData());
                    // disassociate any different item that represents the
                    // same element under the same parent (the tree)
                    for (int j = 0; j < itemsToDisassociate.length; j++) {
                        if ( auto itemToDisassociate = cast(TreeItem)itemsToDisassociate[j]  ) {
                            if (itemToDisassociate !is item
                                    && itemToDisassociate.getParentItem() is parentItem) {
                                int indexToDisaccociate = parentItem
                                        .indexOf(itemToDisassociate);
                                disassociate(itemToDisassociate);
                                parentItem.clear(indexToDisaccociate, true);
                            }
                        }
                    }
                    Object oldData = item.getData();
                    updateItem(item, element);
                    if (!/+TreeViewer.this.+/opEquals(oldData, element)) {
                        item.clearAll(true);
                    }
                }
            }
        }
        // Restore the selection if we are not already in a nested preservingSelection:
        if (!preservingSelection_) {
            setSelectionToWidget(selection, false);
            // send out notification if old and new differ
            ISelection newSelection = getSelection();
            if (!(cast(Object)newSelection).opEquals(cast(Object)selection)) {
                handleInvalidSelection(selection, newSelection);
            }
        }
    }

    /**
     * Fix for bug 185673: If the currently replaced item was selected, add it
     * to the selection that is being restored. Only do this if its getData() is
     * currently null
     *
     * @param selectedItems
     * @param selection
     * @param item
     * @param element
     * @return
     */
    private TreeSelection adjustSelectionForReplace(Item[] selectedItems,
            TreeSelection selection, TreeItem item, Object element, Object parentElement) {
        if (item.getData() !is null || selectedItems.length is selection.size()
                || parentElement is null) {
            // Don't do anything - we are not seeing an instance of bug 185673
            return selection;
        }
        for (int i = 0; i < selectedItems.length; i++) {
            if (item is selectedItems[i]) {
                // The current item was selected, but its data is null.
                // The data will be replaced by the given element, so to keep
                // it selected, we have to add it to the selection.
                TreePath[] originalPaths = selection.getPaths();
                int length_ = originalPaths.length;
                TreePath[] paths = new TreePath[length_ + 1];
                System.arraycopy(originalPaths, 0, paths, 0, length_);
                // set the element temporarily so that we can call getTreePathFromItem
                item.setData(element);
                paths[length_] = getTreePathFromItem(item);
                item.setData(null);
                return new TreeSelection(paths, selection.getElementComparer());
            }
        }
        // The item was not selected, return the given selection
        return selection;
    }

    public override bool isExpandable(Object element) {
        if (contentProviderIsLazy) {
            TreeItem treeItem = cast(TreeItem) internalExpand(element, false);
            if (treeItem is null) {
                return false;
            }
            virtualMaterializeItem(treeItem);
            return treeItem.getItemCount() > 0;
        }
        return super.isExpandable(element);
    }

    protected override Object getParentElement(Object element) {
        bool oldBusy = isBusy();
        setBusy(true);
        try {
            if (contentProviderIsLazy && !contentProviderIsTreeBased && !(cast(TreePath)element )) {
                ILazyTreeContentProvider lazyTreeContentProvider = cast(ILazyTreeContentProvider) getContentProvider();
                return lazyTreeContentProvider.getParent(element);
            }
            if (contentProviderIsLazy && contentProviderIsTreeBased && !(cast(TreePath)element )) {
                ILazyTreePathContentProvider lazyTreePathContentProvider = cast(ILazyTreePathContentProvider) getContentProvider();
                TreePath[] parents = lazyTreePathContentProvider
                .getParents(element);
                if (parents !is null && parents.length > 0) {
                    return parents[0];
                }
            }
            return super.getParentElement(element);
        } finally {
            setBusy(oldBusy);
        }
    }

    protected override void createChildren(Widget widget) {
        if (contentProviderIsLazy) {
            Object element = widget.getData();
            if (element is null && cast(TreeItem)widget ) {
                // parent has not been materialized
                virtualMaterializeItem(cast(TreeItem) widget);
                // try getting the element now that updateElement was called
                element = widget.getData();
            }
            if (element is  null) {
                // give up because the parent is still not materialized
                return;
            }
            Item[] children = getChildren(widget);
            if (children.length is 1 && children[0].getData() is null) {
                // found a dummy node
                virtualLazyUpdateChildCount(widget, children.length);
                children = getChildren(widget);
            }
            // touch all children to make sure they are materialized
            for (int i = 0; i < children.length; i++) {
                if (children[i].getData() is null) {
                    virtualLazyUpdateWidget(widget, i);
                }
            }
            return;
        }
        super.createChildren(widget);
    }

    protected override void internalAdd(Widget widget, Object parentElement,
            Object[] childElements) {
        if (contentProviderIsLazy) {
            if (auto ti = cast(TreeItem)widget ) {
                int count = ti.getItemCount() + childElements.length;
                ti.setItemCount(count);
                ti.clearAll(false);
            } else {
                Tree t = cast(Tree) widget;
                t.setItemCount(t.getItemCount() + childElements.length);
                t.clearAll(false);
            }
            return;
        }
        super.internalAdd(widget, parentElement, childElements);
    }

    private void virtualMaterializeItem(TreeItem treeItem) {
        if (treeItem.getData() !is null) {
            // already materialized
            return;
        }
        if (!contentProviderIsLazy) {
            return;
        }
        int index;
        Widget parent = treeItem.getParentItem();
        if (parent is null) {
            parent = treeItem.getParent();
        }
        Object parentElement = parent.getData();
        if (parentElement !is null) {
            if ( auto t = cast(Tree)parent ) {
                index = t.indexOf(treeItem);
            } else {
                index = (cast(TreeItem) parent).indexOf(treeItem);
            }
            virtualLazyUpdateWidget(parent, index);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#internalRefreshStruct(org.eclipse.swt.widgets.Widget,
     *      java.lang.Object, bool)
     */
    protected override void internalRefreshStruct(Widget widget, Object element,
            bool updateLabels) {
        if (contentProviderIsLazy) {
            // clear all starting with the given widget
            if (auto t = cast(Tree)widget ) {
                t.clearAll(true);
            } else if (cast(TreeItem)widget ) {
                (cast(TreeItem) widget).clearAll(true);
            }
            int index = 0;
            Widget parent = null;
            if (auto treeItem = cast(TreeItem)widget ) {
                parent = treeItem.getParentItem();
                if (parent is null) {
                    parent = treeItem.getParent();
                }
                if (cast(Tree)parent ) {
                    index = (cast(Tree) parent).indexOf(treeItem);
                } else {
                    index = (cast(TreeItem) parent).indexOf(treeItem);
                }
            }
            virtualRefreshExpandedItems(parent, widget, element, index);
            return;
        }
        super.internalRefreshStruct(widget, element, updateLabels);
    }

    /**
     * Traverses the visible (expanded) part of the tree and updates child
     * counts.
     *
     * @param parent the parent of the widget, or <code>null</code> if the widget is the tree
     * @param widget
     * @param element
     * @param index the index of the widget in the children array of its parent, or 0 if the widget is the tree
     */
    private void virtualRefreshExpandedItems(Widget parent, Widget widget, Object element, int index) {
        if ( cast(Tree)widget ) {
            if (element is null) {
                (cast(Tree) widget).setItemCount(0);
                return;
            }
            virtualLazyUpdateChildCount(widget, getChildren(widget).length);
        } else if ((cast(TreeItem) widget).getExpanded()) {
            // prevent SetData callback
            (cast(TreeItem)widget).setText(" "); //$NON-NLS-1$
            virtualLazyUpdateWidget(parent, index);
        } else {
            return;
        }
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            Object data = item.getData();
            virtualRefreshExpandedItems(widget, item, data, i);
        }
    }

    /*
     * To unmap elements correctly, we need to register a dispose listener with
     * the item if the tree is virtual.
     */
    protected override void mapElement(Object element, Widget item) {
        super.mapElement(element, item);
        // make sure to unmap elements if the tree is virtual
        if ((getTree().getStyle() & SWT.VIRTUAL) !is 0) {
            // only add a dispose listener if item hasn't already on assigned
            // because it is reused
            if (item.getData(VIRTUAL_DISPOSE_KEY) is null) {
                item.setData(VIRTUAL_DISPOSE_KEY, Boolean.TRUE);
                item.addDisposeListener(new class(item) DisposeListener {
                    Widget item_;
                    this(Widget a){
                        item_=a;
                    }
                    public void widgetDisposed(DisposeEvent e) {
                        if (!treeIsDisposed) {
                            Object data = item_.getData();
                            if (usingElementMap() && data !is null) {
                                unmapElement(data, item_);
                            }
                        }
                    }
                });
            }
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ColumnViewer#getRowPartFromItem(org.eclipse.swt.widgets.Widget)
     */
    protected override ViewerRow getViewerRowFromItem(Widget item) {
        if( cachedRow is null ) {
            cachedRow = new TreeViewerRow(cast(TreeItem) item);
        } else {
            cachedRow.setItem(cast(TreeItem) item);
        }

        return cachedRow;
    }

    /**
     * Create a new ViewerRow at rowIndex
     *
     * @param parent
     * @param style
     * @param rowIndex
     * @return ViewerRow
     */
    private ViewerRow createNewRowPart(ViewerRow parent, int style, int rowIndex) {
        if (parent is null) {
            if (rowIndex >= 0) {
                return getViewerRowFromItem(new TreeItem(tree, style, rowIndex));
            }
            return getViewerRowFromItem(new TreeItem(tree, style));
        }

        if (rowIndex >= 0) {
            return getViewerRowFromItem(new TreeItem(cast(TreeItem) parent.getItem(),
                    SWT.NONE, rowIndex));
        }

        return getViewerRowFromItem(new TreeItem(cast(TreeItem) parent.getItem(),
                SWT.NONE));
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#internalInitializeTree(org.eclipse.swt.widgets.Control)
     */
    protected override void internalInitializeTree(Control widget) {
        if (contentProviderIsLazy) {
            if (cast(Tree)widget && widget.getData() !is null) {
                virtualLazyUpdateChildCount(widget, 0);
                return;
            }
        }
        super.internalInitializeTree(tree);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#updatePlus(org.eclipse.swt.widgets.Item,
     *      java.lang.Object)
     */
    protected override void updatePlus(Item item, Object element) {
        if (contentProviderIsLazy) {
            Object data = item.getData();
            int itemCount = 0;
            if (data !is null) {
                // item is already materialized
                itemCount = (cast(TreeItem) item).getItemCount();
            }
            virtualLazyUpdateHasChildren(item, itemCount);
        } else {
            super.updatePlus(item, element);
        }
    }

    /**
     * Removes the element at the specified index of the parent.  The selection is updated if required.
     *
     * @param parentOrTreePath the parent element, the input element, or a tree path to the parent element
     * @param index child index
     * @since 3.3
     */
    public void remove(Object parentOrTreePath_, int index_) {
        if (checkBusy())
            return;
        preservingSelection(new class((cast(TreeSelection) getSelection()).getPaths(),parentOrTreePath_,index_) Runnable {
            List oldSelection;
            Object parentOrTreePath;
            int index;
            this(TreePath[] a,Object b,int c){
                parentOrTreePath=b;
                index=c;
                oldSelection = new LinkedList(Arrays.asList(a));
            }
            public void run() {
                TreePath removedPath = null;
                if (internalIsInputOrEmptyPath(parentOrTreePath)) {
                    Tree tree = cast(Tree) getControl();
                    if (index < tree.getItemCount()) {
                        TreeItem item = tree.getItem(index);
                        if (item.getData() !is null) {
                            removedPath = getTreePathFromItem(item);
                            disassociate(item);
                        }
                        item.dispose();
                    }
                } else {
                    Widget[] parentItems = internalFindItems(parentOrTreePath);
                    for (int i = 0; i < parentItems.length; i++) {
                        TreeItem parentItem = cast(TreeItem) parentItems[i];
                        if (parentItem.isDisposed())
                            continue;
                        if (index < parentItem.getItemCount()) {
                            TreeItem item = parentItem.getItem(index);
                            if (item.getData() !is null) {
                                removedPath = getTreePathFromItem(item);
                                disassociate(item);
                            }
                            item.dispose();
                        }
                    }
                }
                if (removedPath !is null) {
                    bool removed = false;
                    for (Iterator it = oldSelection.iterator(); it
                            .hasNext();) {
                        TreePath path = cast(TreePath) it.next();
                        if (path.startsWith(removedPath, getComparer())) {
                            it.remove();
                            removed = true;
                        }
                    }
                    if (removed) {
                        setSelection(new TreeSelection(
                                arraycast!(TreePath)( oldSelection
                                        .toArray(new TreePath[oldSelection
                                                .size()])), getComparer()),
                                false);
                    }
                }
            }
        });
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#handleTreeExpand(org.eclipse.swt.events.TreeEvent)
     */
    protected override void handleTreeExpand(TreeEvent event) {
        if (contentProviderIsLazy) {
            if (event.item.getData() !is null) {
                Item[] children = getChildren(event.item);
                if (children.length is 1 && children[0].getData() is null) {
                    // we have a dummy child node, ask for an updated child
                    // count
                    virtualLazyUpdateChildCount(event.item, children.length);
                }
                fireTreeExpanded(new TreeExpansionEvent(this, event.item
                        .getData()));
            }
            return;
        }
        super.handleTreeExpand(event);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.AbstractTreeViewer#setContentProvider(org.eclipse.jface.viewers.IContentProvider)
     */
    public override void setContentProvider(IContentProvider provider) {
        contentProviderIsLazy = (cast(ILazyTreeContentProvider)provider )
                || (cast(ILazyTreePathContentProvider)provider );
        contentProviderIsTreeBased = null !is cast(ILazyTreePathContentProvider)provider ;
        super.setContentProvider(provider);
    }

    /**
     * For a TreeViewer with a tree with the VIRTUAL style bit set, inform the
     * viewer about whether the given element or tree path has children. Avoid
     * calling this method if the number of children has already been set.
     *
     * @param elementOrTreePath
     *            the element, or tree path
     * @param hasChildren
     *
     * @since 3.3
     */
    public void setHasChildren(Object elementOrTreePath_, bool hasChildren_) {
        if (checkBusy())
            return;
        preservingSelection(new class(elementOrTreePath_,hasChildren_) Runnable {
            Object elementOrTreePath;
            bool hasChildren;
            this(Object a,bool b){
                elementOrTreePath=a;
                hasChildren=b;
            }
            public void run() {
                if (internalIsInputOrEmptyPath(elementOrTreePath)) {
                    if (hasChildren) {
                        virtualLazyUpdateChildCount(getTree(),
                                getChildren(getTree()).length);
                    } else {
                        setChildCount(elementOrTreePath, 0);
                    }
                    return;
                }
                Widget[] items = internalFindItems(elementOrTreePath);
                for (int i = 0; i < items.length; i++) {
                    TreeItem item = cast(TreeItem) items[i];
                    if (!hasChildren) {
                        item.setItemCount(0);
                    } else {
                        if (!item.getExpanded()) {
                            item.setItemCount(1);
                            TreeItem child = item.getItem(0);
                            if (child.getData() !is null) {
                                disassociate(child);
                            }
                            item.clear(0, true);
                        } else {
                            virtualLazyUpdateChildCount(item, item.getItemCount());
                        }
                    }
                }
            }
        });
    }

    /**
     * Update the widget at index.
     * @param widget
     * @param index
     */
    private void virtualLazyUpdateWidget(Widget widget, int index) {
        bool oldBusy = isBusy();
        setBusy(false);
        try {
            if (contentProviderIsTreeBased) {
                TreePath treePath;
                if ( auto i = cast(Item)widget ) {
                    if (widget.getData() is null) {
                        // we need to materialize the parent first
                        // see bug 167668
                        // however, that would be too risky
                        // see bug 182782 and bug 182598
                        // so we just ignore this call altogether
                        // and don't do this: virtualMaterializeItem((TreeItem) widget);
                        return;
                    }
                    treePath = getTreePathFromItem(i);
                } else {
                    treePath = TreePath.EMPTY;
                }
                (cast(ILazyTreePathContentProvider) getContentProvider())
                        .updateElement(treePath, index);
            } else {
                (cast(ILazyTreeContentProvider) getContentProvider()).updateElement(
                        widget.getData(), index);
            }
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Update the child count
     * @param widget
     * @param currentChildCount
     */
    private void virtualLazyUpdateChildCount(Widget widget, int currentChildCount) {
        bool oldBusy = isBusy();
        setBusy(false);
        try {
            if (contentProviderIsTreeBased) {
                TreePath treePath;
                if (cast(Item)widget ) {
                    treePath = getTreePathFromItem(cast(Item) widget);
                } else {
                    treePath = TreePath.EMPTY;
                }
                (cast(ILazyTreePathContentProvider) getContentProvider())
                .updateChildCount(treePath, currentChildCount);
            } else {
                (cast(ILazyTreeContentProvider) getContentProvider()).updateChildCount(widget.getData(), currentChildCount);
            }
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Update the item with the current child count.
     * @param item
     * @param currentChildCount
     */
    private void virtualLazyUpdateHasChildren(Item item, int currentChildCount) {
        bool oldBusy = isBusy();
        setBusy(false);
        try {
            if (contentProviderIsTreeBased) {
                TreePath treePath;
                treePath = getTreePathFromItem(item);
                if (currentChildCount is 0) {
                    // item is not expanded (but may have a plus currently)
                    (cast(ILazyTreePathContentProvider) getContentProvider())
                    .updateHasChildren(treePath);
                } else {
                    (cast(ILazyTreePathContentProvider) getContentProvider())
                    .updateChildCount(treePath, currentChildCount);
                }
            } else {
                (cast(ILazyTreeContentProvider) getContentProvider()).updateChildCount(item.getData(), currentChildCount);
            }
        } finally {
            setBusy(oldBusy);
        }
    }

    protected override void disassociate(Item item) {
        if (contentProviderIsLazy) {
            // avoid causing a callback:
            item.setText(" "); //$NON-NLS-1$
        }
        super.disassociate(item);
    }

    protected override int doGetColumnCount() {
        return tree.getColumnCount();
    }

    /**
     * Sets a new selection for this viewer and optionally makes it visible.
     * <p>
     * <b>Currently the <code>reveal</code> parameter is not honored because
     * {@link Tree} does not provide an API to only select an item without
     * scrolling it into view</b>
     * </p>
     *
     * @param selection
     *            the new selection
     * @param reveal
     *            <code>true</code> if the selection is to be made visible,
     *            and <code>false</code> otherwise
     */
    public override void setSelection(ISelection selection, bool reveal) {
        super.setSelection(selection, reveal);
    }

    public override void editElement(Object element, int column) {
        if( cast(TreePath)element ) {
            try {
                getControl().setRedraw(false);
                setSelection(new TreeSelection(cast(TreePath) element));
                TreeItem[] items = tree.getSelection();

                if( items.length is 1 ) {
                    ViewerRow row = getViewerRowFromItem(items[0]);

                    if (row !is null) {
                        ViewerCell cell = row.getCell(column);
                        if (cell !is null) {
                            triggerEditorActivationEvent(new ColumnViewerEditorActivationEvent(cell));
                        }
                    }
                }
            } finally {
                getControl().setRedraw(true);
            }
        } else {
            super.editElement(element, column);
        }
    }

}
