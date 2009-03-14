/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - bug 153993, bug 167323, bug 175192
 *     Lasse Knudsen, bug 205700
 *     Micah Hainline, bug 210448
 *     Michael Schneider, bug 210747
 *     Bruce Sutton, bug 221768
 *     Matthew Hall, bug 221988
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.AbstractTreeViewer;

import org.eclipse.jface.viewers.ColumnViewer;
import org.eclipse.jface.viewers.TreePath;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.jface.viewers.ITreeViewerListener;
import org.eclipse.jface.viewers.TreeExpansionEvent;
import org.eclipse.jface.viewers.CustomHashtable;
import org.eclipse.jface.viewers.IContentProvider;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.ColumnViewerEditor;
import org.eclipse.jface.viewers.ViewerLabel;
import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.TreePathViewerSorter;
import org.eclipse.jface.viewers.ViewerFilter;
import org.eclipse.jface.viewers.ViewerColumn;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ITreePathContentProvider;
import org.eclipse.jface.viewers.ITreeContentProvider;
import org.eclipse.jface.viewers.TreeSelection;
import org.eclipse.jface.viewers.DoubleClickEvent;
import org.eclipse.jface.viewers.IElementComparer;
import org.eclipse.jface.viewers.ITreeSelection;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.ITreePathLabelProvider;



import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.BusyIndicator;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.events.SelectionListener;
import org.eclipse.swt.events.TreeEvent;
import org.eclipse.swt.events.TreeListener;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.ListenerList;
import org.eclipse.jface.util.SafeRunnable;

import java.lang.all;
import java.util.Arrays;
import java.util.List;
import java.util.LinkedList;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

/**
 * Abstract base implementation for tree-structure-oriented viewers (trees and
 * table trees).
 * <p>
 * Nodes in the tree can be in either an expanded or a collapsed state,
 * depending on whether the children on a node are visible. This class
 * introduces public methods for controlling the expanding and collapsing of
 * nodes.
 * </p>
 * <p>
 * As of 3.2, AbstractTreeViewer supports multiple equal elements (each with a
 * different parent chain) in the tree. This support requires that clients
 * enable the element map by calling <code>setUseHashLookup(true)</code>.
 * </p>
 * <p>
 * Content providers for abstract tree viewers must implement one of the
 * interfaces <code>ITreeContentProvider</code> or (as of 3.2, to support
 * multiple equal elements) <code>ITreePathContentProvider</code>.
 * </p>
 *
 * @see TreeViewer
 */
public abstract class AbstractTreeViewer : ColumnViewer {
    alias ColumnViewer.buildLabel buildLabel;
    alias ColumnViewer.filter filter;
    alias ColumnViewer.setSelection setSelection;

    /**
     * Constant indicating that all levels of the tree should be expanded or
     * collapsed.
     *
     * @see #expandToLevel(int)
     * @see #collapseToLevel(Object, int)
     */
    public static const int ALL_LEVELS = -1;

    /**
     * List of registered tree listeners (element type:
     * <code>TreeListener</code>).
     */
    private ListenerList treeListeners;

    /**
     * The level to which the tree is automatically expanded each time the
     * viewer's input is changed (that is, by <code>setInput</code>). A value
     * of 0 means that auto-expand is off.
     *
     * @see #setAutoExpandLevel
     */
    private int expandToLevel_ = 0;

    /**
     * Safe runnable used to update an item.
     */
    class UpdateItemSafeRunnable : SafeRunnable {
        private Object element;

        private Item item;

        this(Item item, Object element) {
            this.item = item;
            this.element = element;
        }

        public void run() {
            doUpdateItem(item, element);
        }

    }

    /**
     * Creates an abstract tree viewer. The viewer has no input, no content
     * provider, a default label provider, no sorter, no filters, and has
     * auto-expand turned off.
     */
    protected this() {
        treeListeners = new ListenerList();
        // do nothing
    }

    /**
     * Adds the given child elements to this viewer as children of the given
     * parent element. If this viewer does not have a sorter, the elements are
     * added at the end of the parent's list of children in the order given;
     * otherwise, the elements are inserted at the appropriate positions.
     * <p>
     * This method should be called (by the content provider) when elements have
     * been added to the model, in order to cause the viewer to accurately
     * reflect the model. This method only affects the viewer, not the model.
     * </p>
     *
     * @param parentElementOrTreePath
     *            the parent element
     * @param childElements
     *            the child elements to add
     */
    public void add(Object parentElementOrTreePath, Object[] childElements) {
        Assert.isNotNull(parentElementOrTreePath);
        assertElementsNotNull(childElements);
        if (checkBusy())
            return;
        Widget[] widgets = internalFindItems(parentElementOrTreePath);
        // If parent hasn't been realized yet, just ignore the add.
        if (widgets.length is 0) {
            return;
        }

        for (int i = 0; i < widgets.length; i++) {
            internalAdd(widgets[i], parentElementOrTreePath, childElements);
        }
    }

    /**
     * Find the items for the given element of tree path
     *
     * @param parentElementOrTreePath
     *            the element or tree path
     * @return the items for that element
     *
     * @since 3.3
     */
    final protected Widget[] internalFindItems(Object parentElementOrTreePath) {
        Widget[] widgets;
        if ( auto path = cast(TreePath) parentElementOrTreePath ) {
            Widget w = internalFindItem(path);
            if (w is null) {
                widgets = null;
            } else {
                widgets = [ w ];
            }
        } else {
            widgets = findItems(parentElementOrTreePath);
        }
        return widgets;
    }

    /**
     * Return the item at the given path or <code>null</code>
     *
     * @param path
     *            the path
     * @return {@link Widget} the item at that path
     */
    private Widget internalFindItem(TreePath path) {
        Widget[] widgets = findItems(path.getLastSegment());
        for (int i = 0; i < widgets.length; i++) {
            Widget widget = widgets[i];
            if ( auto item = cast(Item)widget ) {
                TreePath p = getTreePathFromItem(item);
                if (p.opEquals(path)) {
                    return widget;
                }
            }
        }
        return null;
    }

    /**
     * Adds the given child elements to this viewer as children of the given
     * parent element.
     * <p>
     * EXPERIMENTAL. Not to be used except by JDT. This method was added to
     * support JDT's explorations into grouping by working sets, which requires
     * viewers to support multiple equal elements. See bug 76482 for more
     * details. This support will likely be removed in Eclipse 3.2 in favor of
     * proper support for multiple equal elements.
     * </p>
     *
     * @param widget
     *            the widget for the parent element
     * @param parentElementOrTreePath
     *            the parent element
     * @param childElements
     *            the child elements to add
     * @since 3.1
     */
    protected void internalAdd(Widget widget, Object parentElementOrTreePath,
            Object[] childElements) {
        Object parent;
        TreePath path;
        if ( auto path = cast(TreePath) parentElementOrTreePath ) {
            parent = path.getLastSegment();
        } else {
            parent = parentElementOrTreePath;
            path = null;
        }

        // optimization!
        // if the widget is not expanded we just invalidate the subtree
        if ( auto ti = cast(Item)widget ) {
            if (!getExpanded(ti)) {
                bool needDummy = isExpandable(ti, path, parent);
                bool haveDummy = false;
                // remove all children
                Item[] items = getItems(ti);
                for (int i = 0; i < items.length; i++) {
                    if (items[i].getData() !is null) {
                        disassociate(items[i]);
                        items[i].dispose();
                    } else {
                        if (needDummy && !haveDummy) {
                            haveDummy = true;
                        } else {
                            items[i].dispose();
                        }
                    }
                }
                // append a dummy if necessary
                if (needDummy && !haveDummy) {
                    newItem(ti, SWT.NULL, -1);
                }
                return;
            }
        }

        if (childElements.length > 0) {
            // TODO: Add filtering back?
            Object[] filtered = filter(parentElementOrTreePath, childElements);
            ViewerComparator comparator = getComparator();
            if (comparator !is null) {
                if ( auto tpvs = cast(TreePathViewerSorter) comparator ) {
                    if (path is null) {
                        path = internalGetSorterParentPath(widget, comparator);
                    }
                    tpvs.sort(this, path, filtered);
                } else {
                    comparator.sort(this, filtered);
                }
            }
            createAddedElements(widget, filtered);
        }
    }

    /**
     * Filter the children elements.
     *
     * @param parentElementOrTreePath
     *            the parent element or path
     * @param elements
     *            the child elements
     * @return the filter list of children
     */
    private Object[] filter(Object parentElementOrTreePath, Object[] elements) {
        ViewerFilter[] filters = getFilters();
        if (filters !is null) {
            ArrayList filtered = new ArrayList(elements.length);
            for (int i = 0; i < elements.length; i++) {
                bool add = true;
                for (int j = 0; j < filters.length; j++) {
                    add = filters[j].select(this, parentElementOrTreePath,
                            elements[i]);
                    if (!add) {
                        break;
                    }
                }
                if (add) {
                    filtered.add(elements[i]);
                }
            }
            return filtered.toArray();
        }
        return elements;
    }

    /**
     * Create the new elements in the parent widget. If the child already exists
     * do nothing.
     *
     * @param widget
     * @param elements
     *            Sorted list of elements to add.
     */
    private void createAddedElements(Widget widget, Object[] elements) {

        if (elements.length is 1) {
            if (opEquals(elements[0], widget.getData())) {
                return;
            }
        }

        ViewerComparator comparator = getComparator();
        TreePath parentPath = internalGetSorterParentPath(widget, comparator);
        Item[] items = getChildren(widget);

        // Optimize for the empty case
        if (items.length is 0) {
            for (int i = 0; i < elements.length; i++) {
                createTreeItem(widget, elements[i], -1);
            }
            return;
        }

        // Optimize for no comparator
        if (comparator is null) {
            for (int i = 0; i < elements.length; i++) {
                Object element = elements[i];
                if (itemExists(items, element)) {
                    internalRefresh(element);
                } else {
                    createTreeItem(widget, element, -1);
                }
            }
            return;
        }
        // As the items are sorted already we optimize for a
        // start position. This is the insertion position relative to the
        // original item array.
        int indexInItems = 0;

        // Count of elements we have added. See bug 205700 for why this is needed.
        int newItems = 0;

        elementloop: for (int i = 0; i < elements.length; i++) {
            Object element = elements[i];
            // update the index relative to the original item array
            indexInItems = insertionPosition(items, comparator,
                    indexInItems, element, parentPath);
            if (indexInItems is items.length) {
                createTreeItem(widget, element, -1);
                newItems++;
            } else {
                // Search for an item for the element. The comparator might
                // regard elements as equal when they are not.

                // Use a separate index variable to search within the existing
                // elements that compare equally, see
                // TreeViewerTestBug205700.testAddEquallySortedElements.
                int insertionIndexInItems = indexInItems;
                while( insertionIndexInItems < items.length
                        && internalCompare(comparator, parentPath, element,
                                items[insertionIndexInItems].getData()) is 0) {
                    // As we cannot assume the sorter is consistent with
                    // equals() - therefore we can
                    // just check against the item prior to this index (if
                    // any)
                    if (items[insertionIndexInItems].getData().opEquals(element)) {
                        // Found the item for the element.
                        // Refresh the element in case it has new children.
                        internalRefresh(element);
                        // Do not create a new item - continue with the next element.
                        continue elementloop;
                    }
                    insertionIndexInItems++;
                }
                // Did we get to the end?
                if (insertionIndexInItems is items.length) {
                    createTreeItem(widget, element, -1);
                    newItems++;
                } else {
                    // InsertionIndexInItems is the index in the original array. We
                    // need to correct by the number of new items we have
                    // created. See bug 205700.
                    createTreeItem(widget, element, insertionIndexInItems + newItems);
                    newItems++;
                }
            }
        }
    }

    /**
     * See if element is the data of one of the elements in items.
     *
     * @param items
     * @param element
     * @return <code>true</code> if the element matches.
     */
    private bool itemExists(Item[] items, Object element) {
        if (usingElementMap()) {
            Widget[] existingItems = findItems(element);
            // optimization for two common cases
            if (existingItems.length is 0) {
                return false;
            } else if (existingItems.length is 1) {
                if (items.length > 0 && null !is cast(Item)existingItems[0] ) {
                    Item existingItem = cast(Item) existingItems[0];
                    return getParentItem(existingItem) is getParentItem(items[0]);
                }
            }
        }
        for (int i = 0; i < items.length; i++) {
            if (items[i].getData().opEquals(element)) {
                return true;
            }
        }
        return false;
    }

    /**
     * Returns the index where the item should be inserted. It uses sorter to
     * determine the correct position, if sorter is not assigned, returns the
     * index of the element after the last.
     *
     * @param items
     *            the items to search
     * @param comparator
     *            The comparator to use.
     * @param lastInsertion
     *            the start index to start search for position from this allows
     *            optimizing search for multiple elements that are sorted
     *            themselves.
     * @param element
     *            element to find position for.
     * @param parentPath
     *            the tree path for the element's parent or <code>null</code>
     *            if the element is a root element or the sorter is not a
     *            {@link TreePathViewerSorter}
     * @return the index to use when inserting the element.
     *
     */

    private int insertionPosition(Item[] items, ViewerComparator comparator,
            int lastInsertion, Object element, TreePath parentPath) {

        int size = items.length;
        if (comparator is null) {
            return size;
        }
        int min = lastInsertion, max = size - 1;

        while (min <= max) {
            int mid = (min + max) / 2;
            Object data = items[mid].getData();
            int compare = internalCompare(comparator, parentPath, data, element);
            if (compare is 0) {
                return mid;// Return if we already match
            }
            if (compare < 0) {
                min = mid + 1;
            } else {
                max = mid - 1;
            }
        }
        return min;

    }

    /**
     * Returns the index where the item should be inserted. It uses sorter to
     * determine the correct position, if sorter is not assigned, returns the
     * index of the element after the last.
     *
     * @param parent
     *            The parent widget
     * @param sorter
     *            The sorter to use.
     * @param startIndex
     *            the start index to start search for position from this allows
     *            optimizing search for multiple elements that are sorted
     *            themselves.
     * @param element
     *            element to find position for.
     * @param currentSize
     *            the current size of the collection
     * @return the index to use when inserting the element.
     *
     */

    /**
     * Returns the index where the item should be inserted.
     *
     * @param parent
     *            The parent widget the element will be inserted into.
     * @param element
     *            The element to insert.
     * @return the index of the element
     */
    protected int indexForElement(Widget parent, Object element) {
        ViewerComparator comparator = getComparator();
        TreePath parentPath = internalGetSorterParentPath(parent, comparator);

        Item[] items = getChildren(parent);
        int count = items.length;

        if (comparator is null) {
            return count;
        }
        int min = 0, max = count - 1;

        while (min <= max) {
            int mid = (min + max) / 2;
            Object data = items[mid].getData();
            int compare = internalCompare(comparator, parentPath, data, element);
            if (compare is 0) {
                // find first item > element
                while (compare is 0) {
                    ++mid;
                    if (mid >= count) {
                        break;
                    }
                    data = items[mid].getData();
                    compare = internalCompare(comparator, parentPath, data,
                            element);
                }
                return mid;
            }
            if (compare < 0) {
                min = mid + 1;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    /**
     * Return the tree path that should be used as the parent path for the given
     * widget and sorter. A <code>null</code> is returned if either the sorter
     * is not a {@link TreePathViewerSorter} or if the parent widget is not an
     * {@link Item} (i.e. is the root of the tree).
     *
     * @param parent
     *            the parent widget
     * @param comparator
     *            the sorter
     * @return the tree path that should be used as the parent path for the
     *         given widget and sorter
     */
    private TreePath internalGetSorterParentPath(Widget parent,
            ViewerComparator comparator) {
        TreePath path;
        if ( null !is cast(TreePathViewerSorter)comparator
                && null !is cast(Item)parent ) {
            Item item = cast(Item) parent;
            path = getTreePathFromItem(item);
        } else {
            path = null;
        }
        return path;
    }

    /**
     * Compare the two elements using the given sorter. If the sorter is a
     * {@link TreePathViewerSorter}, the provided tree path will be used. If
     * the tree path is null and the sorter is a tree path sorter, then the
     * elements are root elements
     *
     * @param comparator
     *            the sorter
     * @param parentPath
     *            the path of the elements' parent
     * @param e1
     *            the first element
     * @param e2
     *            the second element
     * @return the result of comparing the two elements
     */
    private int internalCompare(ViewerComparator comparator,
            TreePath parentPath, Object e1, Object e2) {
        if ( auto tpvs = cast(TreePathViewerSorter) comparator ) {
            return tpvs.compare(this, parentPath, e1, e2);
        }
        return comparator.compare(this, e1, e2);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.StructuredViewer#getSortedChildren(java.lang.Object)
     */
    protected override Object[] getSortedChildren(Object parentElementOrTreePath) {
        Object[] result = getFilteredChildren(parentElementOrTreePath);
        ViewerComparator comparator = getComparator();
        if (parentElementOrTreePath !is null
                && null !is cast(TreePathViewerSorter) comparator ) {
            TreePathViewerSorter tpvs = cast(TreePathViewerSorter) comparator;

            // be sure we're not modifying the original array from the model
            result = result.dup;

            TreePath path = null;
            if ( auto p = cast(TreePath) parentElementOrTreePath ) {
                path = p;
            } else {
                Object parent = parentElementOrTreePath;
                Widget w = internalGetWidgetToSelect(parent);
                if (w !is null) {
                    path = internalGetSorterParentPath(w, comparator);
                }
            }
            tpvs.sort(this, path, result);
        } else if (comparator !is null) {
            // be sure we're not modifying the original array from the model
            result = result.dup;
            comparator.sort(this, result);
        }
        return result;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.StructuredViewer#getFilteredChildren(java.lang.Object)
     */
    protected override Object[] getFilteredChildren(Object parentElementOrTreePath) {
        Object[] result = getRawChildren(parentElementOrTreePath);
        ViewerFilter[] filters = getFilters();
        for (int i = 0; i < filters.length; i++) {
            ViewerFilter filter = filters[i];
            result = filter.filter(this, parentElementOrTreePath, result);
        }
        return result;
    }

    /**
     * Adds the given child element to this viewer as a child of the given
     * parent element. If this viewer does not have a sorter, the element is
     * added at the end of the parent's list of children; otherwise, the element
     * is inserted at the appropriate position.
     * <p>
     * This method should be called (by the content provider) when a single
     * element has been added to the model, in order to cause the viewer to
     * accurately reflect the model. This method only affects the viewer, not
     * the model. Note that there is another method for efficiently processing
     * the simultaneous addition of multiple elements.
     * </p>
     *
     * @param parentElementOrTreePath
     *            the parent element or path
     * @param childElement
     *            the child element
     */
    public void add(Object parentElementOrTreePath, Object childElement) {
        add(parentElementOrTreePath, [ childElement ]);
    }

    /**
     * Adds the given SWT selection listener to the given SWT control.
     *
     * @param control
     *            the SWT control
     * @param listener
     *            the SWT selection listener
     * @deprecated
     */
    protected void addSelectionListener(Control control,
            SelectionListener listener) {
        // do nothing
    }

    /**
     * Adds a listener for expand and collapse events in this viewer. Has no
     * effect if an identical listener is already registered.
     *
     * @param listener
     *            a tree viewer listener
     */
    public void addTreeListener(ITreeViewerListener listener) {
        treeListeners.add(cast(Object)listener);
    }

    /**
     * Adds the given SWT tree listener to the given SWT control.
     *
     * @param control
     *            the SWT control
     * @param listener
     *            the SWT tree listener
     */
    protected abstract void addTreeListener(Control control,
            TreeListener listener);

    /*
     * (non-Javadoc)
     *
     * @see StructuredViewer#associate(Object, Item)
     */
    protected override void associate(Object element, Item item) {
        Object data = item.getData();
        if (data !is null && data !is element && opEquals(data, element)) {
            // workaround for PR 1FV62BT
            // assumption: elements are equal but not identical
            // -> remove from map but don't touch children
            unmapElement(data, item);
            item.setData(element);
            mapElement(element, item);
        } else {
            // recursively disassociate all
            super.associate(element, item);
        }
    }

    /**
     * Collapses all nodes of the viewer's tree, starting with the root. This
     * method is equivalent to <code>collapseToLevel(ALL_LEVELS)</code>.
     */
    public void collapseAll() {
        Object root = getRoot();
        if (root !is null) {
            collapseToLevel(root, ALL_LEVELS);
        }
    }

    /**
     * Collapses the subtree rooted at the given element or tree path to the
     * given level.
     *
     * @param elementOrTreePath
     *            the element or tree path
     * @param level
     *            non-negative level, or <code>ALL_LEVELS</code> to collapse
     *            all levels of the tree
     */
    public void collapseToLevel(Object elementOrTreePath, int level) {
        Assert.isNotNull(elementOrTreePath);
        Widget w = internalGetWidgetToSelect(elementOrTreePath);
        if (w !is null) {
            internalCollapseToLevel(w, level);
        }
    }

    /**
     * Creates all children for the given widget.
     * <p>
     * The default implementation of this framework method assumes that
     * <code>widget.getData()</code> returns the element corresponding to the
     * node. Note: the node is not visually expanded! You may have to call
     * <code>parent.setExpanded(true)</code>.
     * </p>
     *
     * @param widget
     *            the widget
     */
    protected void createChildren(Widget widget) {
        bool oldBusy = isBusy();
        setBusy(true);
        try {
            Item[] tis = getChildren(widget);
            if (tis !is null && tis.length > 0) {
                Object data = tis[0].getData();
                if (data !is null) {
                    return; // children already there!
                }
            }

            BusyIndicator.showWhile(widget.getDisplay(), dgRunnable( (Widget widget_, Item[] tis_){
                // fix for PR 1FW89L7:
                // don't complain and remove all "dummies" ...
                if (tis_ !is null) {
                    for (int i = 0; i < tis_.length; i++) {
                        if (tis_[i].getData() !is null) {
                            disassociate(tis_[i]);
                            Assert.isTrue(tis_[i].getData() is null,
                                    "Second or later child is non -null");//$NON-NLS-1$

                        }
                        tis_[i].dispose();
                    }
                }
                Object d = widget_.getData();
                if (d !is null) {
                    Object parentElement = d;
                    Object[] children;
                    if (isTreePathContentProvider() && (null !is cast(Item)widget_) ) {
                        TreePath path = getTreePathFromItem(cast(Item) widget_);
                        children = getSortedChildren(path);
                    } else {
                        children = getSortedChildren(parentElement);
                    }
                    for (int i = 0; i < children.length; i++) {
                        createTreeItem(widget_, children[i], -1);
                    }
                }
            }, widget,tis ));
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Creates a single item for the given parent and synchronizes it with the
     * given element.
     *
     * @param parent
     *            the parent widget
     * @param element
     *            the element
     * @param index
     *            if non-negative, indicates the position to insert the item
     *            into its parent
     */
    protected void createTreeItem(Widget parent, Object element, int index) {
        Item item = newItem(parent, SWT.NULL, index);
        updateItem(item, element);
        updatePlus(item, element);
    }

    /**
     * The <code>AbstractTreeViewer</code> implementation of this method also
     * recurses over children of the corresponding element.
     */
    protected override void disassociate(Item item) {
        super.disassociate(item);
        // recursively unmapping the items is only required when
        // the hash map is used. In the other case disposing
        // an item will recursively dispose its children.
        if (usingElementMap()) {
            disassociateChildren(item);
        }
    }

    /**
     * Disassociates the children of the given SWT item from their corresponding
     * elements.
     *
     * @param item
     *            the widget
     */
    private void disassociateChildren(Item item) {
        Item[] items = getChildren(item);
        for (int i = 0; i < items.length; i++) {
            if (items[i].getData() !is null) {
                disassociate(items[i]);
            }
        }
    }

    /* (non-Javadoc) Method declared on StructuredViewer. */
    protected override Widget doFindInputItem(Object element) {
        // compare with root
        Object root = getRoot();
        if (root is null) {
            return null;
        }

        if (opEquals(root, element)) {
            return getControl();
        }
        return null;
    }

    /* (non-Javadoc) Method declared on StructuredViewer. */
    protected override Widget doFindItem(Object element) {
        // compare with root
        Object root = getRoot();
        if (root is null) {
            return null;
        }

        Item[] items = getChildren(getControl());
        if (items !is null) {
            for (int i = 0; i < items.length; i++) {
                Widget o = internalFindItem(items[i], element);
                if (o !is null) {
                    return o;
                }
            }
        }
        return null;
    }

    /**
     * Copies the attributes of the given element into the given SWT item.
     *
     * @param item
     *            the SWT item
     * @param element
     *            the element
     */
    protected void doUpdateItem(Item item, Object element) {
        if (item.isDisposed()) {
            unmapElement(element, item);
            return;
        }

        int columnCount = doGetColumnCount();
        if (columnCount is 0)// If no columns are created then fake one
            columnCount = 1;

        ViewerRow viewerRowFromItem = getViewerRowFromItem(item);

        bool isVirtual = (getControl().getStyle() & SWT.VIRTUAL) !is 0;

        // If the control is virtual, we cannot use the cached viewer row object. See bug 188663.
        if (isVirtual) {
            viewerRowFromItem = cast(ViewerRow) viewerRowFromItem.clone();
        }

        for (int column = 0; column < columnCount; column++) {
            ViewerColumn columnViewer = getViewerColumn(column);
            ViewerCell cellToUpdate = updateCell(viewerRowFromItem, column,
                    element);

            // If the control is virtual, we cannot use the cached cell object. See bug 188663.
            if (isVirtual) {
                cellToUpdate = new ViewerCell(cellToUpdate.getViewerRow(), cellToUpdate.getColumnIndex(), element);
            }

            columnViewer.refresh(cellToUpdate);

            // clear cell (see bug 201280)
            updateCell(null, 0, null);

            // As it is possible for user code to run the event
            // loop check here.
            if (item.isDisposed()) {
                unmapElement(element, item);
                return;
            }

        }
    }

    /**
     * Returns <code>true</code> if the given list and array of items refer to
     * the same model elements. Order is unimportant.
     * <p>
     * This method is not intended to be overridden by subclasses.
     * </p>
     *
     * @param items
     *            the list of items
     * @param current
     *            the array of items
     * @return <code>true</code> if the refer to the same elements,
     *         <code>false</code> otherwise
     *
     * @since 3.1 in TreeViewer, moved to AbstractTreeViewer in 3.3
     */
    protected bool isSameSelection(List items, Item[] current) {
        // If they are not the same size then they are not equivalent
        int n = items.size();
        if (n !is current.length) {
            return false;
        }

        CustomHashtable itemSet = newHashtable(n * 2 + 1);
        for (Iterator i = items.iterator(); i.hasNext();) {
            Item item = cast(Item) i.next();
            Object element = item.getData();
            itemSet.put(element, element);
        }

        // Go through the items of the current collection
        // If there is a mismatch return false
        for (int i = 0; i < current.length; i++) {
            if (current[i].getData() is null
                    || !itemSet.containsKey(current[i].getData())) {
                return false;
            }
        }

        return true;
    }



    /* (non-Javadoc) Method declared on StructuredViewer. */
    protected override void doUpdateItem(Widget widget, Object element, bool fullMap) {
        bool oldBusy = isBusy();
        setBusy(true);
        try {
            if ( auto item = cast(Item)widget ) {

                // ensure that back pointer is correct
                if (fullMap) {
                    associate(element, item);
                } else {
                    Object data = item.getData();
                    if (data !is null) {
                        unmapElement(data, item);
                    }
                    item.setData(element);
                    mapElement(element, item);
                }

                // update icon and label
                SafeRunnable.run(new UpdateItemSafeRunnable(item, element));
            }
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Expands all nodes of the viewer's tree, starting with the root. This
     * method is equivalent to <code>expandToLevel(ALL_LEVELS)</code>.
     */
    public void expandAll() {
        expandToLevel(ALL_LEVELS);
    }

    /**
     * Expands the root of the viewer's tree to the given level.
     *
     * @param level
     *            non-negative level, or <code>ALL_LEVELS</code> to expand all
     *            levels of the tree
     */
    public void expandToLevel(int level) {
        expandToLevel(getRoot(), level);
    }

    /**
     * Expands all ancestors of the given element or tree path so that the given
     * element becomes visible in this viewer's tree control, and then expands
     * the subtree rooted at the given element to the given level.
     *
     * @param elementOrTreePath
     *            the element
     * @param level
     *            non-negative level, or <code>ALL_LEVELS</code> to expand all
     *            levels of the tree
     */
    public void expandToLevel(Object elementOrTreePath, int level) {
        if (checkBusy())
            return;
        Widget w = internalExpand(elementOrTreePath, true);
        if (w !is null) {
            internalExpandToLevel(w, level);
        }
    }

    /**
     * Fires a tree collapsed event. Only listeners registered at the time this
     * method is called are notified.
     *
     * @param event
     *            the tree expansion event
     * @see ITreeViewerListener#treeCollapsed
     */
    protected void fireTreeCollapsed(TreeExpansionEvent event) {
        Object[] listeners = treeListeners.getListeners();
        bool oldBusy = isBusy();
        setBusy(true);
        try {
            for (int i = 0; i < listeners.length; ++i) {
                SafeRunnable.run(new class(event,cast(ITreeViewerListener) listeners[i]) SafeRunnable {
                    TreeExpansionEvent event_;
                    ITreeViewerListener l;
                    this(TreeExpansionEvent a,ITreeViewerListener b){
                        event_=a;
                        l = b;
                    }
                    public void run() {
                        l.treeCollapsed(event_);
                    }
                });
            }
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Fires a tree expanded event. Only listeners registered at the time this
     * method is called are notified.
     *
     * @param event
     *            the tree expansion event
     * @see ITreeViewerListener#treeExpanded
     */
    protected void fireTreeExpanded(TreeExpansionEvent event) {
        Object[] listeners = treeListeners.getListeners();
        bool oldBusy = isBusy();
        setBusy(true);
        try {
            for (int i = 0; i < listeners.length; ++i) {
                SafeRunnable.run(new class( event, cast(ITreeViewerListener) listeners[i]) SafeRunnable {
                    TreeExpansionEvent event_;
                    ITreeViewerListener l;
                    this(TreeExpansionEvent a,ITreeViewerListener b){
                        event_=a;
                        l = b;
                    }
                    public void run() {
                        l.treeExpanded(event_);
                    }
                });
            }
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Returns the auto-expand level.
     *
     * @return non-negative level, or <code>ALL_LEVELS</code> if all levels of
     *         the tree are expanded automatically
     * @see #setAutoExpandLevel
     */
    public int getAutoExpandLevel() {
        return expandToLevel_;
    }

    /**
     * Returns the SWT child items for the given SWT widget.
     *
     * @param widget
     *            the widget
     * @return the child items
     */
    protected abstract Item[] getChildren(Widget widget);

    /**
     * Get the child for the widget at index. Note that the default
     * implementation is not very efficient and should be overridden if this
     * class is implemented.
     *
     * @param widget
     *            the widget to check
     * @param index
     *            the index of the widget
     * @return Item or <code>null</code> if widget is not a type that can
     *         contain items.
     *
     * @throws ArrayIndexOutOfBoundsException
     *             if the index is not valid.
     * @since 3.1
     */
    protected Item getChild(Widget widget, int index) {
        return getChildren(widget)[index];
    }

    /**
     * Returns whether the given SWT item is expanded or collapsed.
     *
     * @param item
     *            the item
     * @return <code>true</code> if the item is considered expanded and
     *         <code>false</code> if collapsed
     */
    protected abstract bool getExpanded(Item item);

    /**
     * Returns a list of elements corresponding to expanded nodes in this
     * viewer's tree, including currently hidden ones that are marked as
     * expanded but are under a collapsed ancestor.
     * <p>
     * This method is typically used when preserving the interesting state of a
     * viewer; <code>setExpandedElements</code> is used during the restore.
     * </p>
     *
     * @return the array of expanded elements
     * @see #setExpandedElements
     */
    public Object[] getExpandedElements() {
        ArrayList items = new ArrayList();
        internalCollectExpandedItems(items, getControl());
        ArrayList result = new ArrayList(items.size());
        for (Iterator it = items.iterator(); it.hasNext();) {
            Item item = cast(Item) it.next();
            Object data = item.getData();
            if (data !is null) {
                result.add(data);
            }
        }
        return result.toArray();
    }

    /**
     * Returns whether the node corresponding to the given element or tree path
     * is expanded or collapsed.
     *
     * @param elementOrTreePath
     *            the element
     * @return <code>true</code> if the node is expanded, and
     *         <code>false</code> if collapsed
     */
    public bool getExpandedState(Object elementOrTreePath) {
        Assert.isNotNull(elementOrTreePath);
        Widget item = internalGetWidgetToSelect(elementOrTreePath);
        if ( auto i = cast(Item)item ) {
            return getExpanded(i);
        }
        return false;
    }

    /**
     * Returns the number of child items of the given SWT control.
     *
     * @param control
     *            the control
     * @return the number of children
     */
    protected abstract int getItemCount(Control control);

    /**
     * Returns the number of child items of the given SWT item.
     *
     * @param item
     *            the item
     * @return the number of children
     */
    protected abstract int getItemCount(Item item);

    /**
     * Returns the child items of the given SWT item.
     *
     * @param item
     *            the item
     * @return the child items
     */
    protected abstract Item[] getItems(Item item);

    /**
     * Returns the item after the given item in the tree, or <code>null</code>
     * if there is no next item.
     *
     * @param item
     *            the item
     * @param includeChildren
     *            <code>true</code> if the children are considered in
     *            determining which item is next, and <code>false</code> if
     *            subtrees are ignored
     * @return the next item, or <code>null</code> if none
     */
    protected Item getNextItem(Item item, bool includeChildren) {
        if (item is null) {
            return null;
        }
        if (includeChildren && getExpanded(item)) {
            Item[] children = getItems(item);
            if (children !is null && children.length > 0) {
                return children[0];
            }
        }

        // next item is either next sibling or next sibling of first
        // parent that has a next sibling.
        Item parent = getParentItem(item);
        if (parent is null) {
            return null;
        }
        Item[] siblings = getItems(parent);
        if (siblings !is null) {
            if (siblings.length <= 1) {
                return getNextItem(parent, false);
            }

            for (int i = 0; i < siblings.length; i++) {
                if (siblings[i] is item && i < (siblings.length - 1)) {
                    return siblings[i + 1];
                }
            }
        }
        return getNextItem(parent, false);
    }

    /**
     * Returns the parent item of the given item in the tree, or
     * <code>null</code> if there is no parent item.
     *
     * @param item
     *            the item
     * @return the parent item, or <code>null</code> if none
     */
    protected abstract Item getParentItem(Item item);

    /**
     * Returns the item before the given item in the tree, or <code>null</code>
     * if there is no previous item.
     *
     * @param item
     *            the item
     * @return the previous item, or <code>null</code> if none
     */
    protected Item getPreviousItem(Item item) {
        // previous item is either right-most visible descendent of previous
        // sibling or parent
        Item parent = getParentItem(item);
        if (parent is null) {
            return null;
        }
        Item[] siblings = getItems(parent);
        if (siblings.length is 0 || siblings[0] is item) {
            return parent;
        }
        Item previous = siblings[0];
        for (int i = 1; i < siblings.length; i++) {
            if (siblings[i] is item) {
                return rightMostVisibleDescendent(previous);
            }
            previous = siblings[i];
        }
        return null;
    }

    /* (non-Javadoc) Method declared on StructuredViewer. */
    protected override Object[] getRawChildren(Object parentElementOrTreePath) {
        bool oldBusy = isBusy();
        setBusy(true);
        try {
            Object parent;
            TreePath path;
            if ( auto p = cast(TreePath)parentElementOrTreePath ) {
                path = p;
                parent = path.getLastSegment();
            } else {
                parent = parentElementOrTreePath;
                path = null;
            }
            if (parent !is null) {
                if (opEquals(parent, getRoot())) {
                    return super.getRawChildren(parent);
                }
                IContentProvider cp = getContentProvider();
                if ( auto tpcp = cast(ITreePathContentProvider)cp ) {
                    if (path is null) {
                        // A path was not provided so try and find one
                        Widget w = findItem(parent);
                        if ( auto item = cast(Item)w ) {
                            path = getTreePathFromItem(item);
                        }
                        if (path is null) {
                            path = new TreePath([parent ]);
                        }
                    }
                    Object[] result = tpcp.getChildren(path);
                    if (result !is null) {
                        return result;
                    }
                } else if ( auto tcp = cast(ITreeContentProvider)cp ) {
                    Object[] result = tcp.getChildren(parent);
                    if (result !is null) {
                        return result;
                    }
                }
            }
            return null;
        } finally {
            setBusy(oldBusy);
        }
    }

    /**
     * Returns all selected items for the given SWT control.
     *
     * @param control
     *            the control
     * @return the list of selected items
     */
    protected abstract Item[] getSelection(Control control);

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.StructuredViewer#getSelectionFromWidget()
     */
    protected override List getSelectionFromWidget() {
        Widget[] items = getSelection(getControl());
        ArrayList list = new ArrayList(items.length);
        for (int i = 0; i < items.length; i++) {
            Widget item = items[i];
            Object e = item.getData();
            if (e !is null) {
                list.add(e);
            }
        }
        return list;
    }

    /*
     * Overridden in AbstractTreeViewer to fix bug 108102 (code copied from
     * StructuredViewer to avoid introducing new API) (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.StructuredViewer#handleDoubleSelect(org.eclipse.swt.events.SelectionEvent)
     */
    protected override void handleDoubleSelect(SelectionEvent event) {
        // handle case where an earlier selection listener disposed the control.
        Control control = getControl();
        if (control !is null && !control.isDisposed()) {
            // If the double-clicked element can be obtained from the event, use
            // it
            // otherwise get it from the control. Some controls like List do
            // not have the notion of item.
            // For details, see bug 90161 [Navigator] DefaultSelecting folders
            // shouldn't always expand first one
            ISelection selection;
            if (event.item !is null && event.item.getData() !is null) {

                // changes to fix bug 108102 follow
                TreePath treePath = getTreePathFromItem(cast(Item) event.item);
                selection = new TreeSelection(treePath);
                // end of changes

            } else {
                selection = getSelection();
                updateSelection(selection);
            }
            fireDoubleClick(new DoubleClickEvent(this, selection));
        }
    }

    /**
     * Handles a tree collapse event from the SWT widget.
     *
     * @param event
     *            the SWT tree event
     */
    protected void handleTreeCollapse(TreeEvent event) {
        if (event.item.getData() !is null) {
            fireTreeCollapsed(new TreeExpansionEvent(this, event.item.getData()));
        }
    }

    /**
     * Handles a tree expand event from the SWT widget.
     *
     * @param event
     *            the SWT tree event
     */
    protected void handleTreeExpand(TreeEvent event) {
        createChildren(event.item);
        if (event.item.getData() !is null) {
            fireTreeExpanded(new TreeExpansionEvent(this, event.item.getData()));
        }
    }

    /* (non-Javadoc) Method declared on Viewer. */
    protected override void hookControl(Control control) {
        super.hookControl(control);
        addTreeListener(control, new class TreeListener {
            public void treeExpanded(TreeEvent event) {
                handleTreeExpand(event);
            }

            public void treeCollapsed(TreeEvent event) {
                handleTreeCollapse(event);
            }
        });
    }

    /*
     * (non-Javadoc) Method declared on StructuredViewer. Builds the initial
     * tree and handles the automatic expand feature.
     */
    protected override void inputChanged(Object input, Object oldInput) {
        preservingSelection(new class Runnable {
            public void run() {
                Control tree = getControl();
                tree.setRedraw(false);
                try {
                    removeAll(tree);
                    tree.setData(getRoot());
                    internalInitializeTree(tree);
                } finally {
                    tree.setRedraw(true);
                }
            }
        });
    }

    /**
     * Initializes the tree with root items, expanding to the appropriate
     * level if necessary.
     *
     * @param tree the tree control
     * @since 3.3
     */
    protected void internalInitializeTree(Control tree) {
        createChildren(tree);
        internalExpandToLevel(tree, expandToLevel_);
    }

    /**
     * Recursively collapses the subtree rooted at the given widget to the given
     * level.
     * <p>
     * </p>
     * Note that the default implementation of this method does not call
     * <code>setRedraw</code>.
     *
     * @param widget
     *            the widget
     * @param level
     *            non-negative level, or <code>ALL_LEVELS</code> to collapse
     *            all levels of the tree
     */
    protected void internalCollapseToLevel(Widget widget, int level) {
        if (level is ALL_LEVELS || level > 0) {

            if ( auto i = cast(Item)widget ) {
                setExpanded(i, false);
            }

            if (level is ALL_LEVELS || level > 1) {
                Item[] children = getChildren(widget);
                if (children !is null) {
                    int nextLevel = (level is ALL_LEVELS ? ALL_LEVELS
                            : level - 1);
                    for (int i = 0; i < children.length; i++) {
                        internalCollapseToLevel(children[i], nextLevel);
                    }
                }
            }
        }
    }

    /**
     * Recursively collects all expanded items from the given widget.
     *
     * @param result
     *            a list (element type: <code>Item</code>) into which to
     *            collect the elements
     * @param widget
     *            the widget
     */
    private void internalCollectExpandedItems(List result, Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            if (getExpanded(item)) {
                result.add(item);
            }
            internalCollectExpandedItems(result, item);
        }
    }

    /**
     * Tries to create a path of tree items for the given element or tree path.
     * This method recursively walks up towards the root of the tree and in the
     * case of an element (rather than a tree path) assumes that
     * <code>getParent</code> returns the correct parent of an element.
     *
     * @param elementOrPath
     *            the element
     * @param expand
     *            <code>true</code> if all nodes on the path should be
     *            expanded, and <code>false</code> otherwise
     * @return Widget
     */
    protected Widget internalExpand(Object elementOrPath, bool expand) {

        if (elementOrPath is null) {
            return null;
        }

        Widget w = internalGetWidgetToSelect(elementOrPath);
        if (w is null) {
            if (opEquals(elementOrPath, getRoot())) { // stop at root
                return null;
            }
            // my parent has to create me
            Object parent = getParentElement(elementOrPath);
            if (parent !is null) {
                Widget pw = internalExpand(parent, false);
                if (pw !is null) {
                    // let my parent create me
                    createChildren(pw);
                    Object element = internalToElement(elementOrPath);
                    w = internalFindChild(pw, element);
                    if (expand && null !is cast(Item)pw ) {
                        // expand parent items top-down
                        Item item = cast(Item) pw;
                        LinkedList toExpandList = new LinkedList();
                        while (item !is null && !getExpanded(item)) {
                            toExpandList.addFirst(item);
                            item = getParentItem(item);
                        }
                        for (Iterator it = toExpandList.iterator(); it
                                .hasNext();) {
                            Item toExpand = cast(Item) it.next();
                            setExpanded(toExpand, true);
                        }
                    }
                }
            }
        }
        return w;
    }

    /**
     * If the argument is a tree path, returns its last segment, otherwise
     * return the argument
     *
     * @param elementOrPath
     *            an element or a tree path
     * @return the element, or the last segment of the tree path
     */
    private Object internalToElement(Object elementOrPath) {
        if (auto tp = cast(TreePath)elementOrPath ) {
            return tp.getLastSegment();
        }
        return elementOrPath;
    }

    /**
     * This method takes a tree path or an element. If the argument is not a
     * tree path, returns the parent of the given element or <code>null</code>
     * if the parent is not known. If the argument is a tree path with more than
     * one segment, returns its parent tree path, otherwise returns
     * <code>null</code>.
     *
     * @param elementOrTreePath
     * @return the parent element, or parent path, or <code>null</code>
     *
     * @since 3.2
     */
    protected Object getParentElement(Object elementOrTreePath) {
        if (auto tp = cast(TreePath)elementOrTreePath) {
            return tp.getParentPath();
        }
        IContentProvider cp = getContentProvider();
        if ( auto tpcp = cast(ITreePathContentProvider)cp ) {
            TreePath[] paths = tpcp.getParents(elementOrTreePath);
            if (paths.length > 0) {
                if (paths[0].getSegmentCount() is 0) {
                    return getRoot();
                }
                return paths[0].getLastSegment();
            }
        }
        if ( auto tcp = cast(ITreeContentProvider) cp ) {
            return tcp.getParent(elementOrTreePath);
        }
        return null;
    }

    /**
     * Returns the widget to be selected for the given element or tree path.
     *
     * @param elementOrTreePath
     *            the element or tree path to select
     * @return the widget to be selected, or <code>null</code> if not found
     *
     * @since 3.1
     */
    protected Widget internalGetWidgetToSelect(Object elementOrTreePath) {
        if ( auto treePath = cast(TreePath) elementOrTreePath ) {
            if (treePath.getSegmentCount() is 0) {
                return getControl();
            }
            Widget[] candidates = findItems(treePath.getLastSegment());
            for (int i = 0; i < candidates.length; i++) {
                Widget candidate = candidates[i];
                if (!(cast(Item)candidate )) {
                    continue;
                }
                if (treePath.opEquals(getTreePathFromItem(cast(Item) candidate),
                        getComparer())) {
                    return candidate;
                }
            }
            return null;
        }
        return findItem(elementOrTreePath);
    }

    /**
     * Recursively expands the subtree rooted at the given widget to the given
     * level.
     * <p>
     * </p>
     * Note that the default implementation of this method does not call
     * <code>setRedraw</code>.
     *
     * @param widget
     *            the widget
     * @param level
     *            non-negative level, or <code>ALL_LEVELS</code> to collapse
     *            all levels of the tree
     */
    protected void internalExpandToLevel(Widget widget, int level) {
        if (level is ALL_LEVELS || level > 0) {
            if ( cast(Item)widget && widget.getData() !is null
                    && !isExpandable(cast(Item) widget, null, widget.getData())) {
                return;
            }
            createChildren(widget);
            if ( auto i = cast(Item)widget ) {
                setExpanded(i, true);
            }
            if (level is ALL_LEVELS || level > 1) {
                Item[] children = getChildren(widget);
                if (children !is null) {
                    int newLevel = (level is ALL_LEVELS ? ALL_LEVELS
                            : level - 1);
                    for (int i = 0; i < children.length; i++) {
                        internalExpandToLevel(children[i], newLevel);
                    }
                }
            }
        }
    }

    /**
     * Non-recursively tries to find the given element as a child of the given
     * parent (item or tree).
     *
     * @param parent
     *            the parent item
     * @param element
     *            the element
     * @return Widget
     */
    private Widget internalFindChild(Widget parent, Object element) {
        Item[] items = getChildren(parent);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            Object data = item.getData();
            if (data !is null && opEquals(data, element)) {
                return item;
            }
        }
        return null;
    }

    /**
     * Recursively tries to find the given element.
     *
     * @param parent
     *            the parent item
     * @param element
     *            the element
     * @return Widget
     */
    private Widget internalFindItem(Item parent, Object element) {

        // compare with node
        Object data = parent.getData();
        if (data !is null) {
            if (opEquals(data, element)) {
                return parent;
            }
        }
        // recurse over children
        Item[] items = getChildren(parent);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            Widget o = internalFindItem(item, element);
            if (o !is null) {
                return o;
            }
        }
        return null;
    }

    /* (non-Javadoc) Method declared on StructuredViewer. */
    protected override void internalRefresh(Object element) {
        internalRefresh(element, true);
    }

    /* (non-Javadoc) Method declared on StructuredViewer. */
    protected override void internalRefresh(Object element, bool updateLabels) {
        // If element is null, do a full refresh.
        if (element is null) {
            internalRefresh(getControl(), getRoot(), true, updateLabels);
            return;
        }
        Widget[] items = findItems(element);
        if (items.length !is 0) {
            for (int i = 0; i < items.length; i++) {
                // pick up structure changes too
                internalRefresh(items[i], element, true, updateLabels);
            }
        }
    }

    /**
     * Refreshes the tree starting at the given widget.
     * <p>
     * EXPERIMENTAL. Not to be used except by JDT. This method was added to
     * support JDT's explorations into grouping by working sets, which requires
     * viewers to support multiple equal elements. See bug 76482 for more
     * details. This support will likely be removed in Eclipse 3.2 in favor of
     * proper support for multiple equal elements.
     * </p>
     *
     * @param widget
     *            the widget
     * @param element
     *            the element
     * @param doStruct
     *            <code>true</code> if structural changes are to be picked up,
     *            and <code>false</code> if only label provider changes are of
     *            interest
     * @param updateLabels
     *            <code>true</code> to update labels for existing elements,
     *            <code>false</code> to only update labels as needed, assuming
     *            that labels for existing elements are unchanged.
     * @since 3.1
     */
    protected void internalRefresh(Widget widget, Object element,
            bool doStruct, bool updateLabels) {

        if ( auto i = cast(Item)widget ) {
            if (doStruct) {
                updatePlus(i, element);
            }
            if (updateLabels || !opEquals(element, widget.getData())) {
                doUpdateItem(widget, element, true);
            } else {
                associate(element, cast(Item) widget);
            }
        }

        if (doStruct) {
            internalRefreshStruct(widget, element, updateLabels);
        } else {
            Item[] children = getChildren(widget);
            if (children !is null) {
                for (int i = 0; i < children.length; i++) {
                    Widget item = children[i];
                    Object data = item.getData();
                    if (data !is null) {
                        internalRefresh(item, data, doStruct, updateLabels);
                    }
                }
            }
        }
    }

    /**
     * Update the structure and recurse. Items are updated in updateChildren, as
     * needed.
     *
     * @param widget
     * @param element
     * @param updateLabels
     */
    /* package */void internalRefreshStruct(Widget widget, Object element,
            bool updateLabels) {
        updateChildren(widget, element, null, updateLabels);
        Item[] children = getChildren(widget);
        if (children !is null) {
            for (int i = 0; i < children.length; i++) {
                Widget item = children[i];
                Object data = item.getData();
                if (data !is null) {
                    internalRefreshStruct(item, data, updateLabels);
                }
            }
        }
    }

    /**
     * Removes the given elements from this viewer.
     * <p>
     * EXPERIMENTAL. Not to be used except by JDT. This method was added to
     * support JDT's explorations into grouping by working sets, which requires
     * viewers to support multiple equal elements. See bug 76482 for more
     * details. This support will likely be removed in Eclipse 3.2 in favor of
     * proper support for multiple equal elements.
     * </p>
     *
     * @param elementsOrPaths
     *            the elements or element paths to remove
     * @since 3.1
     */
    protected void internalRemove(Object[] elementsOrPaths) {
        Object input = getInput();
        for (int i = 0; i < elementsOrPaths.length; ++i) {
            Object element = elementsOrPaths[i];
            if (opEquals(element, input)) {
                setInput(null);
                return;
            }
            Widget[] childItems = internalFindItems(element);
            if (childItems.length > 0) {
                for (int j = 0; j < childItems.length; j++) {
                    Widget childItem = childItems[j];
                    if ( auto it = cast(Item)childItem ) {
                        disassociate(it);
                        childItem.dispose();
                    }
                }
            } else {
                // see https://bugs.eclipse.org/bugs/show_bug.cgi?id=210747
                Object parent = getParentElement(element);
                if (parent !is null
                        && !opEquals(parent, getRoot())
                        && !((null !is cast(TreePath)parent) && (cast(TreePath) parent)
                                .getSegmentCount() is 0)) {
                    Widget[] parentItems = internalFindItems(parent);
                    for (int j = 0; j < parentItems.length; j++) {
                        Widget parentItem = parentItems[j];
                        if (null !is cast(Item)parentItem ) {
                            updatePlus(cast(Item) parentItem, parent);
                        }
                    }
                }
            }
        }
    }

    /**
     * Removes the given elements from this viewer, whenever those elements
     * appear as children of the given parent.
     *
     * @param parent the parent element
     * @param elements
     *            the elements to remove
     * @since 3.1
     */
    protected void internalRemove(Object parent, Object[] elements) {

        CustomHashtable toRemove = new CustomHashtable(getComparer());
        for (int i = 0; i < elements.length; i++) {
            toRemove.put(elements[i], elements[i]);
        }

        // Find each place the parent appears in the tree
        Widget[] parentItemArray = findItems(parent);
        for (int i = 0; i < parentItemArray.length; i++) {
            Widget parentItem = parentItemArray[i];

            // May happen if parent element is a descendent of of a previously
            // removed element
            if (parentItem.isDisposed())
                continue;

            // Iterate over the child items and remove each one
            Item[] children = getChildren(parentItem);

            if (children.length is 1 && children[0].getData() is null &&
                    (null !is cast(Item)parentItem )) { // dummy node
                // Remove plus if parent element has no children
                updatePlus(cast(Item) parentItem, parent);
            } else {
                for (int j = 0; j < children.length; j++) {
                    Item child = children[j];

                    Object data = child.getData();
                    if (data !is null && toRemove.containsKey(data)) {
                        disassociate(child);
                        child.dispose();
                    }
                }
            }
        }
    }

    /**
     * Sets the expanded state of all items to correspond to the given set of
     * expanded elements.
     *
     * @param expandedElements
     *            the set (element type: <code>Object</code>) of elements
     *            which are expanded
     * @param widget
     *            the widget
     */
    private void internalSetExpanded(CustomHashtable expandedElements,
            Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            Object data = item.getData();
            if (data !is null) {
                // remove the element to avoid an infinite loop
                // if the same element appears on a child item
                bool expanded = expandedElements.remove(data) !is null;
                if (expanded !is getExpanded(item)) {
                    if (expanded) {
                        createChildren(item);
                    }
                    setExpanded(item, expanded);
                }
            }
            if (expandedElements.size() > 0) {
                internalSetExpanded(expandedElements, item);
            }
        }
    }

    /**
     * Sets the expanded state of all items to correspond to the given set of
     * expanded tree paths.
     *
     * @param expandedTreePaths
     *            the set (element type: <code>TreePath</code>) of elements
     *            which are expanded
     * @param widget
     *            the widget
     */
    private void internalSetExpandedTreePaths(
            CustomHashtable expandedTreePaths, Widget widget,
            TreePath currentPath) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            Object data = item.getData();
            TreePath childPath = data is null ? null : currentPath
                    .createChildPath(data);
            if (data !is null && childPath !is null) {
                // remove the element to avoid an infinite loop
                // if the same element appears on a child item
                bool expanded = expandedTreePaths.remove(childPath) !is null;
                if (expanded !is getExpanded(item)) {
                    if (expanded) {
                        createChildren(item);
                    }
                    setExpanded(item, expanded);
                }
            }
            internalSetExpandedTreePaths(expandedTreePaths, item, childPath);
        }
    }

    /**
     * Return whether the tree node representing the given element or path can
     * be expanded. Clients should query expandability by path if the viewer's
     * content provider is an {@link ITreePathContentProvider}.
     * <p>
     * The default implementation of this framework method calls
     * <code>hasChildren</code> on this viewer's content provider. It may be
     * overridden if necessary.
     * </p>
     *
     * @param elementOrTreePath
     *            the element or path
     * @return <code>true</code> if the tree node representing the given
     *         element can be expanded, or <code>false</code> if not
     */
    public bool isExpandable(Object elementOrTreePath) {
        Object element;
        TreePath path;
        if (auto p = cast(TreePath)elementOrTreePath) {
            path = p;
            element = path.getLastSegment();
        } else {
            element = elementOrTreePath;
            path = null;
        }
        IContentProvider cp = getContentProvider();
        if ( auto tpcp = cast(ITreePathContentProvider) cp ) {
            if (path is null) {
                // A path was not provided so try and find one
                Widget w = findItem(element);
                if ( auto item = cast(Item)w ) {
                    path = getTreePathFromItem(item);
                }
                if (path is null) {
                    path = new TreePath([ element ]);
                }
            }
            return tpcp.hasChildren(path);
        }
        if (auto tcp = cast(ITreeContentProvider)cp ) {
            return tcp.hasChildren(element);
        }
        return false;
    }

    /**
     * Return whether the given element is expandable.
     *
     * @param item
     *            the tree item for the element
     * @param parentPath
     *            the parent path if it is known or <code>null</code> if it
     *            needs to be determines
     * @param element
     *            the element
     * @return whether the given element is expandable
     */
    private bool isExpandable(Item item, TreePath parentPath, Object element) {
        Object elementOrTreePath = element;
        if (isTreePathContentProvider()) {
            if (parentPath !is null) {
                elementOrTreePath = parentPath.createChildPath(element);
            } else {
                elementOrTreePath = getTreePathFromItem(item);
            }
        }
        return isExpandable(elementOrTreePath);
    }

    /* (non-Javadoc) Method declared on Viewer. */
    protected override void labelProviderChanged() {
        // we have to walk the (visible) tree and update every item
        Control tree = getControl();
        tree.setRedraw(false);
        // don't pick up structure changes, but do force label updates
        internalRefresh(tree, getRoot(), false, true);
        tree.setRedraw(true);
    }

    /**
     * Creates a new item.
     *
     * @param parent
     *            the parent widget
     * @param style
     *            SWT style bits
     * @param index
     *            if non-negative, indicates the position to insert the item
     *            into its parent
     * @return the newly-created item
     */
    protected abstract Item newItem(Widget parent, int style, int index);

    /**
     * Removes the given elements from this viewer. The selection is updated if
     * required.
     * <p>
     * This method should be called (by the content provider) when elements have
     * been removed from the model, in order to cause the viewer to accurately
     * reflect the model. This method only affects the viewer, not the model.
     * </p>
     *
     * @param elementsOrTreePaths
     *            the elements to remove
     */
    public void remove(Object[] elementsOrTreePaths) {
        assertElementsNotNull(elementsOrTreePaths);
        if (elementsOrTreePaths.length is 0) {
            return;
        }
        if (checkBusy())
            return;
        preservingSelection( dgRunnable( (Object[] elementsOrTreePaths_){
            internalRemove(elementsOrTreePaths_);
        }, elementsOrTreePaths));
    }

    /**
     * Removes the given elements from this viewer whenever they appear as
     * children of the given parent element. If the given elements also appear
     * as children of some other parent, the other parent will remain unchanged.
     * The selection is updated if required.
     * <p>
     * This method should be called (by the content provider) when elements have
     * been removed from the model, in order to cause the viewer to accurately
     * reflect the model. This method only affects the viewer, not the model.
     * </p>
     *
     * @param parent
     *            the parent of the elements to remove
     * @param elements
     *            the elements to remove
     *
     * @since 3.2
     */
    public void remove(Object parent, Object[] elements) {
        assertElementsNotNull(elements);
        if (elements.length is 0) {
            return;
        }
        if (checkBusy())
            return;
        preservingSelection( dgRunnable( (Object parent_,Object[] elements_){
            internalRemove(parent_, elements_);
        }, parent, elements ));
    }

    /**
     * Removes the given element from the viewer. The selection is updated if
     * necessary.
     * <p>
     * This method should be called (by the content provider) when a single
     * element has been removed from the model, in order to cause the viewer to
     * accurately reflect the model. This method only affects the viewer, not
     * the model. Note that there is another method for efficiently processing
     * the simultaneous removal of multiple elements.
     * </p>
     *
     * @param elementsOrTreePaths
     *            the element
     */
    public void remove(Object elementsOrTreePaths) {
        remove([ elementsOrTreePaths ]);
    }

    /**
     * Removes all items from the given control.
     *
     * @param control
     *            the control
     */
    protected abstract void removeAll(Control control);

    /**
     * Removes a listener for expand and collapse events in this viewer. Has no
     * affect if an identical listener is not registered.
     *
     * @param listener
     *            a tree viewer listener
     */
    public void removeTreeListener(ITreeViewerListener listener) {
        treeListeners.remove(cast(Object)listener);
    }

    /**
     * This implementation of reveal() reveals the given element or tree path.
     */
    public override void reveal(Object elementOrTreePath) {
        Assert.isNotNull(elementOrTreePath);
        Widget w = internalExpand(elementOrTreePath, true);
        if ( auto item = cast(Item)w ) {
            showItem(item);
        }
    }

    /**
     * Returns the rightmost visible descendent of the given item. Returns the
     * item itself if it has no children.
     *
     * @param item
     *            the item to compute the descendent of
     * @return the rightmost visible descendent or the item itself if it has no
     *         children
     */
    private Item rightMostVisibleDescendent(Item item) {
        Item[] children = getItems(item);
        if (getExpanded(item) && children !is null && children.length > 0) {
            return rightMostVisibleDescendent(children[children.length - 1]);
        }
        return item;
    }

    /* (non-Javadoc) Method declared on Viewer. */
    public override Item scrollDown(int x, int y) {
        Item current = getItem(x, y);
        if (current !is null) {
            Item next = getNextItem(current, true);
            showItem(next is null ? current : next);
            return next;
        }
        return null;
    }

    /* (non-Javadoc) Method declared on Viewer. */
    public override Item scrollUp(int x, int y) {
        Item current = getItem(x, y);
        if (current !is null) {
            Item previous = getPreviousItem(current);
            showItem(previous is null ? current : previous);
            return previous;
        }
        return null;
    }

    /**
     * Sets the auto-expand level to be used when the input of the viewer is set
     * using {@link #setInput(Object)}. The value 0 means that there is no
     * auto-expand; 1 means that the invisible root element is expanded (since
     * most concrete subclasses do not show the root element, there is usually
     * no practical difference between using the values 0 and 1); 2 means that
     * top-level elements are expanded, but not their children; 3 means that
     * top-level elements are expanded, and their children, but not
     * grandchildren; and so on.
     * <p>
     * The value <code>ALL_LEVELS</code> means that all subtrees should be
     * expanded.
     * </p>
     * <p>
     * Note that in previous releases, the Javadoc for this method had an off-by
     * one error. See bug 177669 for details.
     * </p>
     *
     * @param level
     *            non-negative level, or <code>ALL_LEVELS</code> to expand all
     *            levels of the tree
     */
    public void setAutoExpandLevel(int level) {
        expandToLevel_ = level;
    }

    /**
     * The <code>AbstractTreeViewer</code> implementation of this method
     * checks to ensure that the content provider is an
     * <code>ITreeContentProvider</code>.
     */
    public override void setContentProvider(IContentProvider provider) {
        // the actual check is in assertContentProviderType
        super.setContentProvider(provider);
    }

    protected override void assertContentProviderType(IContentProvider provider) {
        Assert.isTrue(cast(ITreeContentProvider)provider
                || cast(ITreePathContentProvider)provider );
    }

    /**
     * Sets the expand state of the given item.
     *
     * @param item
     *            the item
     * @param expand
     *            the expand state of the item
     */
    protected abstract void setExpanded(Item item, bool expand);

    /**
     * Sets which nodes are expanded in this viewer's tree. The given list
     * contains the elements that are to be expanded; all other nodes are to be
     * collapsed.
     * <p>
     * This method is typically used when restoring the interesting state of a
     * viewer captured by an earlier call to <code>getExpandedElements</code>.
     * </p>
     *
     * @param elements
     *            the array of expanded elements
     * @see #getExpandedElements
     */
    public void setExpandedElements(Object[] elements) {
        assertElementsNotNull(elements);
        if (checkBusy()) {
            return;
        }
        CustomHashtable expandedElements = newHashtable(elements.length * 2 + 1);
        for (int i = 0; i < elements.length; ++i) {
            Object element = elements[i];
            // Ensure item exists for element. This will materialize items for
            // each element and their parents, if possible. This is important
            // to support expanding of inner tree nodes without necessarily
            // expanding their parents.
            internalExpand(element, false);
            expandedElements.put(element, element);
        }
        // this will traverse all existing items, and create children for
        // elements that need to be expanded. If the tree contains multiple
        // equal elements, and those are in the set of elements to be expanded,
        // only the first item found for each element will be expanded.
        internalSetExpanded(expandedElements, getControl());
    }

    /**
     * Sets which nodes are expanded in this viewer's tree. The given list
     * contains the tree paths that are to be expanded; all other nodes are to
     * be collapsed.
     * <p>
     * This method is typically used when restoring the interesting state of a
     * viewer captured by an earlier call to <code>getExpandedTreePaths</code>.
     * </p>
     *
     * @param treePaths
     *            the array of expanded tree paths
     * @see #getExpandedTreePaths()
     *
     * @since 3.2
     */
    public void setExpandedTreePaths(TreePath[] treePaths) {
        assertElementsNotNull(treePaths);
        if (checkBusy())
            return;
        IElementComparer treePathComparer = new class(getComparer()) IElementComparer {
            IElementComparer comparer;
            this(IElementComparer c){
                comparer = c;
            }
            public int opEquals(Object a, Object b) {
                return (cast(TreePath) a).opEquals((cast(TreePath) b), comparer);
            }

            public hash_t toHash(Object element) {
                return (cast(TreePath) element).toHash(comparer);
            }
        };
        CustomHashtable expandedTreePaths = new CustomHashtable(
                treePaths.length * 2 + 1, treePathComparer);
        for (int i = 0; i < treePaths.length; ++i) {
            TreePath treePath = treePaths[i];
            // Ensure item exists for element. This will materialize items for
            // each element and their parents, if possible. This is important
            // to support expanding of inner tree nodes without necessarily
            // expanding their parents.
            internalExpand(treePath, false);
            expandedTreePaths.put(treePath, treePath);
        }
        // this will traverse all existing items, and create children for
        // elements that need to be expanded. If the tree contains multiple
        // equal elements, and those are in the set of elements to be expanded,
        // only the first item found for each element will be expanded.
        internalSetExpandedTreePaths(expandedTreePaths, getControl(),
                new TreePath(new Object[0]));
    }

    /**
     * Sets whether the node corresponding to the given element or tree path is
     * expanded or collapsed.
     *
     * @param elementOrTreePath
     *            the element
     * @param expanded
     *            <code>true</code> if the node is expanded, and
     *            <code>false</code> if collapsed
     */
    public void setExpandedState(Object elementOrTreePath, bool expanded) {
        Assert.isNotNull(elementOrTreePath);
        if (checkBusy())
            return;
        Widget item = internalExpand(elementOrTreePath, false);
        if ( cast(Item)item ) {
            if (expanded) {
                createChildren(item);
            }
            setExpanded(cast(Item) item, expanded);
        }
    }

    /**
     * Sets the selection to the given list of items.
     *
     * @param items
     *            list of items (element type:
     *            <code>org.eclipse.swt.widgets.Item</code>)
     */
    protected abstract void setSelection(List items);

    /**
     * This implementation of setSelectionToWidget accepts a list of elements or
     * a list of tree paths.
     */
    protected override void setSelectionToWidget(List v, bool reveal) {
        if (v is null) {
            setSelection(new ArrayList(0));
            return;
        }
        int size = v.size();
        List newSelection = new ArrayList(size);
        for (int i = 0; i < size; ++i) {
            Object elementOrTreePath = v.get(i);
            // Use internalExpand since item may not yet be created. See
            // 1G6B1AR.
            Widget w = internalExpand(elementOrTreePath, false);
            if ( auto it = cast(Item)w ) {
                newSelection.add(it);
            } else if (w is null && null !is cast(TreePath)elementOrTreePath ) {
                TreePath treePath = cast(TreePath) elementOrTreePath;
                Object element = treePath.getLastSegment();
                if (element !is null) {
                    w = internalExpand(element, false);
                    if ( auto it = cast(Item)w ) {
                        newSelection.add(it);
                    }
                }
            }
        }
        setSelection(newSelection);

        // Although setting the selection in the control should reveal it,
        // setSelection may be a no-op if the selection is unchanged,
        // so explicitly reveal items in the selection here.
        // See bug 100565 for more details.
        if (reveal && newSelection.size() > 0) {
            // Iterate backwards so the first item in the list
            // is the one guaranteed to be visible
            for (int i = (newSelection.size()-1); i >= 0; i--) {
                showItem(cast(Item) newSelection.get(i));
            }
        }
    }

    /**
     * Shows the given item.
     *
     * @param item
     *            the item
     */
    protected abstract void showItem(Item item);

    /**
     * Updates the tree items to correspond to the child elements of the given
     * parent element. If null is passed for the children, this method obtains
     * them (only if needed).
     *
     * @param widget
     *            the widget
     * @param parent
     *            the parent element
     * @param elementChildren
     *            the child elements, or null
     * @deprecated this is no longer called by the framework
     */
    protected void updateChildren(Widget widget, Object parent,
            Object[] elementChildren) {
        updateChildren(widget, parent, elementChildren, true);
    }

    /**
     * Updates the tree items to correspond to the child elements of the given
     * parent element. If null is passed for the children, this method obtains
     * them (only if needed).
     *
     * @param widget
     *            the widget
     * @param parent
     *            the parent element
     * @param elementChildren
     *            the child elements, or null
     * @param updateLabels
     *            <code>true</code> to update labels for existing elements,
     *            <code>false</code> to only update labels as needed, assuming
     *            that labels for existing elements are unchanged.
     * @since 2.1
     */
    private void updateChildren(Widget widget, Object parent,
            Object[] elementChildren, bool updateLabels) {
        // optimization! prune collapsed subtrees
        if (auto ti = cast(Item)widget ) {
            if (!getExpanded(ti)) {
                // need a dummy node if element is expandable;
                // but try to avoid recreating the dummy node
                bool needDummy = isExpandable(ti, null, parent);
                bool haveDummy = false;
                // remove all children
                Item[] items = getItems(ti);
                for (int i = 0; i < items.length; i++) {
                    if (items[i].getData() !is null) {
                        disassociate(items[i]);
                        items[i].dispose();
                    } else {
                        if (needDummy && !haveDummy) {
                            haveDummy = true;
                        } else {
                            items[i].dispose();
                        }
                    }
                }
                if (needDummy && !haveDummy) {
                    newItem(ti, SWT.NULL, -1);
                }

                return;
            }
        }

        // If the children weren't passed in, get them now since they're needed
        // below.
        if (elementChildren is null) {
            if (isTreePathContentProvider() && null !is cast(Item) widget ) {
                TreePath path = getTreePathFromItem(cast(Item) widget);
                elementChildren = getSortedChildren(path);
            } else {
                elementChildren = getSortedChildren(parent);
            }
        }

        Control tree = getControl();

        // WORKAROUND
        int oldCnt = -1;
        if (widget is tree) {
            oldCnt = getItemCount(tree);
        }

        Item[] items = getChildren(widget,elementChildren);

        // save the expanded elements
        CustomHashtable expanded = newHashtable(CustomHashtable.DEFAULT_CAPACITY); // assume
                                                                                    // num
                                                                                    // expanded
                                                                                    // is
                                                                                    // small
        for (int i = 0; i < items.length; ++i) {
            if (getExpanded(items[i])) {
                Object element = items[i].getData();
                if (element !is null) {
                    expanded.put(element, element);
                }
            }
        }

        int min = Math.min(elementChildren.length, items.length);

        // dispose of surplus items, optimizing for the case where elements have
        // been deleted but not reordered, or all elements have been removed.
        int numItemsToDispose = items.length - min;
        if (numItemsToDispose > 0) {
            CustomHashtable children = newHashtable(elementChildren.length * 2);
            for (int i = 0; i < elementChildren.length; i++) {
                Object elementChild = elementChildren[i];
                children.put(elementChild, elementChild);
            }
            int i = 0;
            while (numItemsToDispose > 0 && i < items.length) {
                Object data = items[i].getData();
                if (data is null || items.length - i <= numItemsToDispose || !children.containsKey(data)) {
                    if (data !is null) {
                        disassociate(items[i]);
                    }
                    items[i].dispose();
                    if (i + 1 < items.length) {
                        // The components at positions i+1 through
                        // items.length-1 in the source array are copied into
                        // positions i through items.length-2
                        System.arraycopy(items, i + 1, items, i, items.length - (i+1));
                    }
                    numItemsToDispose--;
                } else {
                    i++;
                }
            }
        }

        // compare first min items, and update item if necessary
        // need to do it in two passes:
        // 1: disassociate old items
        // 2: associate new items
        // because otherwise a later disassociate can remove a mapping made for
        // a previous associate,
        // making the map inconsistent
        for (int i = 0; i < min; ++i) {
            Item item = items[i];
            Object oldElement = item.getData();
            if (oldElement !is null) {
                Object newElement = elementChildren[i];
                if (newElement !is oldElement) {
                    if (opEquals(newElement, oldElement)) {
                        // update the data to be the new element, since
                        // although the elements
                        // may be equal, they may still have different labels
                        // or children
                        Object data = item.getData();
                        if (data !is null) {
                            unmapElement(data, item);
                        }
                        item.setData(newElement);
                        mapElement(newElement, item);
                    } else {
                        disassociate(item);
                        // Clear the text and image to force a label update
                        item.setImage(null);
                        item.setText("");//$NON-NLS-1$

                    }
                }
            }
        }

        for (int i = 0; i < min; ++i) {
            Item item = items[i];
            Object newElement = elementChildren[i];
            if (item.getData() is null) {
                // old and new elements are not equal
                associate(newElement, item);
                updatePlus(item, newElement);
                updateItem(item, newElement);
            } else {
                // old and new elements are equal
                updatePlus(item, newElement);
                if (updateLabels) {
                    updateItem(item, newElement);
                }
            }
        }

        // Restore expanded state for items that changed position.
        // Make sure setExpanded is called after updatePlus, since
        // setExpanded(false) fails if item has no children.
        // Need to call setExpanded for both expanded and unexpanded
        // cases since the expanded state can change either way.
        // This needs to be done in a second loop, see bug 148025.
        for (int i = 0; i < min; ++i) {
            Item item = items[i];
            Object newElement = elementChildren[i];
            setExpanded(item, expanded.containsKey(newElement));
        }

        // add any remaining elements
        if (min < elementChildren.length) {
            for (int i = min; i < elementChildren.length; ++i) {
                createTreeItem(widget, elementChildren[i], i);
            }

            // Need to restore expanded state in a separate pass
            // because createTreeItem does not return the new item.
            // Avoid doing this unless needed.
            if (expanded.size() > 0) {
                // get the items again, to include the new items
                items = getChildren(widget);
                for (int i = min; i < elementChildren.length; ++i) {
                    // Restore expanded state for items that changed position.
                    // Make sure setExpanded is called after updatePlus (called
                    // in createTreeItem), since
                    // setExpanded(false) fails if item has no children.
                    // Only need to call setExpanded if element was expanded
                    // since new items are initially unexpanded.
                    if (expanded.containsKey(elementChildren[i])) {
                        setExpanded(items[i], true);
                    }
                }
            }
        }

        // WORKAROUND
        if (widget is tree && oldCnt is 0 && getItemCount(tree) !is 0) {
            // System.out.println("WORKAROUND setRedraw");
            tree.setRedraw(false);
            tree.setRedraw(true);
        }
    }

    /**
     * Return the items to be refreshed as part of an update. elementChildren are the
     * new elements.
     * @param widget
     * @param elementChildren
     * @since 3.4
     * @return Item[]
     * <strong>NOTE:</strong> This API is experimental and may be deleted
     * before 3.4 is released.
     */
    public Item[] getChildren(Widget widget,  Object[] elementChildren) {
        return getChildren(widget);
    }

    /**
     * Updates the "+"/"-" icon of the tree node from the given element. It
     * calls <code>isExpandable</code> to determine whether an element is
     * expandable.
     *
     * @param item
     *            the item
     * @param element
     *            the element
     */
    protected void updatePlus(Item item, Object element) {
        bool hasPlus = getItemCount(item) > 0;
        bool needsPlus = isExpandable(item, null, element);
        bool removeAll = false;
        bool addDummy = false;
        Object data = item.getData();
        if (data !is null && opEquals(element, data)) {
            // item shows same element
            if (hasPlus !is needsPlus) {
                if (needsPlus) {
                    addDummy = true;
                } else {
                    removeAll = true;
                }
            }
        } else {
            // item shows different element
            removeAll = true;
            addDummy = needsPlus;

            // we cannot maintain expand state so collapse it
            setExpanded(item, false);
        }
        if (removeAll) {
            // remove all children
            Item[] items = getItems(item);
            for (int i = 0; i < items.length; i++) {
                if (items[i].getData() !is null) {
                    disassociate(items[i]);
                }
                items[i].dispose();
            }
        }
        if (addDummy) {
            newItem(item, SWT.NULL, -1); // append a dummy
        }
    }

    /**
     * Gets the expanded elements that are visible to the user. An expanded
     * element is only visible if the parent is expanded.
     *
     * @return the visible expanded elements
     * @since 2.0
     */
    public Object[] getVisibleExpandedElements() {
        ArrayList v = new ArrayList();
        internalCollectVisibleExpanded(v, getControl());
        return v.toArray();
    }

    private void internalCollectVisibleExpanded(ArrayList result, Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            if (getExpanded(item)) {
                Object data = item.getData();
                if (data !is null) {
                    result.add(data);
                }
                // Only recurse if it is expanded - if
                // not then the children aren't visible
                internalCollectVisibleExpanded(result, item);
            }
        }
    }

    /**
     * Returns the tree path for the given item.
     * @param item
     * @return {@link TreePath}
     *
     * @since 3.2
     */
    protected TreePath getTreePathFromItem(Item item) {
        LinkedList segments = new LinkedList();
        while (item !is null) {
            Object segment = item.getData();
            Assert.isNotNull(segment);
            segments.addFirst(segment);
            item = getParentItem(item);
        }
        return new TreePath(segments.toArray());
    }
    package TreePath getTreePathFromItem_package(Item item) {
        return getTreePathFromItem_package(item);
    }

    /**
     * This implementation of getSelection() returns an instance of
     * ITreeSelection.
     *
     * @since 3.2
     */
    public override ISelection getSelection() {
        Control control = getControl();
        if (control is null || control.isDisposed()) {
            return TreeSelection.EMPTY;
        }
        Widget[] items = getSelection(getControl());
        ArrayList list = new ArrayList(items.length);
        for (int i = 0; i < items.length; i++) {
            Widget item = items[i];
            if (item.getData() !is null) {
                list.add(getTreePathFromItem(cast(Item) item));
            }
        }
        return new TreeSelection( arraycast!(TreePath)(list.toArray()), getComparer());
    }

    protected override void setSelectionToWidget(ISelection selection, bool reveal) {
        if ( auto treeSelection = cast(ITreeSelection)selection ) {
            setSelectionToWidget(Arrays.asList(treeSelection.getPaths()),
                    reveal);
        } else {
            super.setSelectionToWidget(selection, reveal);
        }
    }

    /**
     * Returns a list of tree paths corresponding to expanded nodes in this
     * viewer's tree, including currently hidden ones that are marked as
     * expanded but are under a collapsed ancestor.
     * <p>
     * This method is typically used when preserving the interesting state of a
     * viewer; <code>setExpandedElements</code> is used during the restore.
     * </p>
     *
     * @return the array of expanded tree paths
     * @see #setExpandedElements
     *
     * @since 3.2
     */
    public TreePath[] getExpandedTreePaths() {
        ArrayList items = new ArrayList();
        internalCollectExpandedItems(items, getControl());
        ArrayList result = new ArrayList(items.size());
        for (Iterator it = items.iterator(); it.hasNext();) {
            Item item = cast(Item) it.next();
            TreePath treePath = getTreePathFromItem(item);
            if (treePath !is null) {
                result.add(treePath);
            }
        }
        return arraycast!(TreePath)(result.toArray());
    }

    private bool isTreePathContentProvider() {
        return null !is cast(ITreePathContentProvider)getContentProvider() ;
    }

    /**
     * Inserts the given element as a new child element of the given parent
     * element at the given position. If this viewer has a sorter, the position
     * is ignored and the element is inserted at the correct position in the
     * sort order.
     * <p>
     * This method should be called (by the content provider) when elements have
     * been added to the model, in order to cause the viewer to accurately
     * reflect the model. This method only affects the viewer, not the model.
     * </p>
     *
     * @param parentElementOrTreePath
     *            the parent element, or the tree path to the parent
     * @param element
     *            the element
     * @param position
     *            a 0-based position relative to the model, or -1 to indicate
     *            the last position
     *
     * @since 3.2
     */
    public void insert(Object parentElementOrTreePath, Object element,
            int position) {
        Assert.isNotNull(parentElementOrTreePath);
        Assert.isNotNull(element);
        if (checkBusy())
            return;
        if (getComparator() !is null || hasFilters()) {
            add(parentElementOrTreePath, [ element ]);
            return;
        }
        Widget[] items;
        if (internalIsInputOrEmptyPath(parentElementOrTreePath)) {
            items = [ getControl() ];
        } else {
            items = internalFindItems(parentElementOrTreePath);
        }

        for (int i = 0; i < items.length; i++) {
            Widget widget = items[i];
            if (auto item = cast(Item)widget ) {

                Item[] childItems = getChildren(item);
                if (getExpanded(item)
                        || (childItems.length > 0 && childItems[0].getData() !is null)) {
                    // item has real children, go ahead and add
                    int insertionPosition = position;
                    if (insertionPosition is -1) {
                        insertionPosition = getItemCount(item);
                    }

                    createTreeItem(item, element, insertionPosition);
                } else {
                    Object parentElement = parentElementOrTreePath;
                    if (null !is cast(TreePath)element )
                        parentElement = (cast(TreePath) parentElement).getLastSegment();
                    updatePlus(item, parentElement);
                }
            } else {
                int insertionPosition = position;
                if (insertionPosition is -1) {
                    insertionPosition = getItemCount(cast(Control) widget);
                }

                createTreeItem(widget, element, insertionPosition);
            }
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ColumnViewer#getColumnViewerOwner(int)
     */
    protected override Widget getColumnViewerOwner(int columnIndex) {
        // Return null by default
        return null;
    }

    /**
     * This implementation of {@link #getItemAt(Point)} returns null to ensure
     * API backwards compatibility. Subclasses should override.
     *
     * @since 3.3
     */
    protected override Item getItemAt(Point point) {
        return null;
    }

    /**
     * This implementation of {@link #createViewerEditor()} returns null to ensure
     * API backwards compatibility. Subclasses should override.
     *
     * @since 3.3
     */
    protected override ColumnViewerEditor createViewerEditor() {
        return null;
    }

    /**
     * Returns the number of columns of this viewer.
     * <p><b>Subclasses should overwrite this method, which has a default
     * implementation (returning 0) for API backwards compatility reasons</b></p>
     *
     * @return the number of columns
     *
     * @since 3.3
     */
    protected override int doGetColumnCount() {
        return 0;
    }


    /**
     * This implementation of buildLabel handles tree paths as well as elements.
     *
     * @param updateLabel
     *            the ViewerLabel to collect the result in
     * @param elementOrPath
     *            the element or tree path for which a label should be built
     *
     * @see org.eclipse.jface.viewers.StructuredViewer#buildLabel(org.eclipse.jface.viewers.ViewerLabel,
     *      java.lang.Object)
     */
    protected override void buildLabel(ViewerLabel updateLabel, Object elementOrPath) {
        Object element;
        if (auto path = cast(TreePath)elementOrPath ) {
            IBaseLabelProvider provider = getLabelProvider();
            if ( auto pprov = cast(ITreePathLabelProvider) provider ) {
                buildLabel(updateLabel, path, pprov);
                return;
            }
            element = path.getLastSegment();
        } else {
            element = elementOrPath;
        }
        super.buildLabel(updateLabel, element);
    }

    /**
     * Returns true if the given object is either the input or an empty tree path.
     *
     * @param elementOrTreePath an element which could either be the viewer's input, or a tree path
     *
     * @return <code>true</code> if the given object is either the input or an empty tree path,
     * <code>false</code> otherwise.
     * @since 3.3
     */
    final protected bool internalIsInputOrEmptyPath(Object elementOrTreePath) {
        if (elementOrTreePath.opEquals(getRoot()))
            return true;
        if (!(cast(TreePath)elementOrTreePath ))
            return false;
        return (cast(TreePath) elementOrTreePath).getSegmentCount() is 0;
    }

    /*
     * Subclasses should implement
     */
    protected override ViewerRow getViewerRowFromItem(Widget item) {
        return null;
    }
}
