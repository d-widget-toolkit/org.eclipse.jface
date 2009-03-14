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
module org.eclipse.jface.viewers.CheckboxTreeViewer;

import org.eclipse.jface.viewers.TreeViewer;
import org.eclipse.jface.viewers.ICheckable;
import org.eclipse.jface.viewers.ICheckStateListener;
import org.eclipse.jface.viewers.CustomHashtable;
import org.eclipse.jface.viewers.CheckStateChangedEvent;


import org.eclipse.swt.SWT;
import org.eclipse.swt.events.SelectionEvent;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.ListenerList;
import org.eclipse.jface.util.SafeRunnable;

import java.lang.all;
import java.util.List;
import java.util.ArrayList;
import java.util.Set;

/**
 * A concrete tree-structured viewer based on an SWT <code>Tree</code>
 * control with checkboxes on each node.
 * <p>
 * This class is not intended to be subclassed outside the viewer framework.
 * It is designed to be instantiated with a pre-existing SWT tree control and configured
 * with a domain-specific content provider, label provider, element filter (optional),
 * and element sorter (optional).
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class CheckboxTreeViewer : TreeViewer, ICheckable {
    alias TreeViewer.preservingSelection preservingSelection;

    /**
     * List of check state listeners (element type: <code>ICheckStateListener</code>).
     */
    private ListenerList checkStateListeners;

    /**
     * Last item clicked on, or <code>null</code> if none.
     */
    private TreeItem lastClickedItem = null;

    /**
     * Creates a tree viewer on a newly-created tree control under the given parent.
     * The tree control is created using the SWT style bits: <code>CHECK</code> and <code>BORDER</code>.
     * The viewer has no input, no content provider, a default label provider,
     * no sorter, and no filters.
     *
     * @param parent the parent control
     */
    public this(Composite parent) {
        this(parent, SWT.BORDER);
    }

    /**
     * Creates a tree viewer on a newly-created tree control under the given parent.
     * The tree control is created using the given SWT style bits, plus the <code>CHECK</code> style bit.
     * The viewer has no input, no content provider, a default label provider,
     * no sorter, and no filters.
     *
     * @param parent the parent control
     * @param style the SWT style bits
     */
    public this(Composite parent, int style) {
        this(new Tree(parent, SWT.CHECK | style));
    }

    /**
     * Creates a tree viewer on the given tree control.
     * The <code>SWT.CHECK</code> style bit must be set on the given tree control.
     * The viewer has no input, no content provider, a default label provider,
     * no sorter, and no filters.
     *
     * @param tree the tree control
     */
    public this(Tree tree) {
        checkStateListeners = new ListenerList();
        super(tree);
    }

    /* (non-Javadoc)
     * Method declared on ICheckable.
     */
    public void addCheckStateListener(ICheckStateListener listener) {
        checkStateListeners.add(cast(Object)listener);
    }

    /**
     * Applies the checked and grayed states of the given widget and its
     * descendents.
     *
     * @param checked a set of elements (element type: <code>Object</code>)
     * @param grayed a set of elements (element type: <code>Object</code>)
     * @param widget the widget
     */
    private void applyState(CustomHashtable checked, CustomHashtable grayed,
            Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            if ( auto ti = cast(TreeItem) item ) {
                Object data = item.getData();
                if (data !is null) {
                    ti.setChecked(checked.containsKey(data));
                    ti.setGrayed(grayed.containsKey(data));
                }
            }
            applyState(checked, grayed, item);
        }
    }

    /**
     * Notifies any check state listeners that the check state of an element has changed.
     * Only listeners registered at the time this method is called are notified.
     *
     * @param event a check state changed event
     *
     * @see ICheckStateListener#checkStateChanged
     */
    protected void fireCheckStateChanged(CheckStateChangedEvent event) {
        Object[] array = checkStateListeners.getListeners();
        for (int i = 0; i < array.length; i++) {
            SafeRunnable.run( dgSafeRunnable( (ICheckStateListener l){
                l.checkStateChanged(event);
            }, cast(ICheckStateListener) array[i]));
        }

    }

    /**
     * Gathers the checked and grayed states of the given widget and its
     * descendents.
     *
     * @param checked a writable set of elements (element type: <code>Object</code>)
     * @param grayed a writable set of elements (element type: <code>Object</code>)
     * @param widget the widget
     */
    private void gatherState(CustomHashtable checked, CustomHashtable grayed,
            Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            if ( auto ti = cast(TreeItem) item ) {
                Object data = item.getData();
                if (data !is null) {
                    if (ti.getChecked()) {
                        checked.put(data, data);
                    }
                    if (ti.getGrayed()) {
                        grayed.put(data, data);
                    }
                }
            }
            gatherState(checked, grayed, item);
        }
    }

    /* (non-Javadoc)
     * Method declared on ICheckable.
     */
    public bool getChecked(Object element) {
        Widget widget = findItem(element);
        if ( auto ti = cast(TreeItem) widget ) {
            return ti.getChecked();
        }
        return false;
    }

    /**
     * Returns a list of checked elements in this viewer's tree,
     * including currently hidden ones that are marked as
     * checked but are under a collapsed ancestor.
     * <p>
     * This method is typically used when preserving the interesting
     * state of a viewer; <code>setCheckedElements</code> is used during the restore.
     * </p>
     *
     * @return the array of checked elements
     *
     * @see #setCheckedElements
     */
    public Object[] getCheckedElements() {
        ArrayList v = new ArrayList();
        Control tree = getControl();
        internalCollectChecked(v, tree);
        return v.toArray();
    }

    /**
     * Returns the grayed state of the given element.
     *
     * @param element the element
     * @return <code>true</code> if the element is grayed,
     *   and <code>false</code> if not grayed
     */
    public bool getGrayed(Object element) {
        Widget widget = findItem(element);
        if ( auto ti = cast(TreeItem) widget ) {
            return ti.getGrayed();
        }
        return false;
    }

    /**
     * Returns a list of grayed elements in this viewer's tree,
     * including currently hidden ones that are marked as
     * grayed but are under a collapsed ancestor.
     * <p>
     * This method is typically used when preserving the interesting
     * state of a viewer; <code>setGrayedElements</code> is used during the restore.
     * </p>
     *
     * @return the array of grayed elements
     *
     * @see #setGrayedElements
     */
    public Object[] getGrayedElements() {
        List result = new ArrayList();
        internalCollectGrayed(result, getControl());
        return result.toArray();
    }

    /* (non-Javadoc)
     * Method declared on StructuredViewer.
     */
    protected override void handleDoubleSelect(SelectionEvent event) {

        if (lastClickedItem !is null) {
            TreeItem item = lastClickedItem;
            Object data = item.getData();
            if (data !is null) {
                bool state = item.getChecked();
                setChecked(data, !state);
                fireCheckStateChanged(new CheckStateChangedEvent(this, data,
                        !state));
            }
            lastClickedItem = null;
        } else {
            super.handleDoubleSelect(event);
        }
    }

    /* (non-Javadoc)
     * Method declared on StructuredViewer.
     */
    protected override void handleSelect(SelectionEvent event) {

        lastClickedItem = null;
        if (event.detail is SWT.CHECK) {
            TreeItem item = cast(TreeItem) event.item;
            lastClickedItem = item;
            super.handleSelect(event);

            Object data = item.getData();
            if (data !is null) {
                fireCheckStateChanged(new CheckStateChangedEvent(this, data,
                        item.getChecked()));
            }
        } else {
            super.handleSelect(event);
        }
    }

    /**
     * Gathers the checked states of the given widget and its
     * descendents, following a pre-order traversal of the tree.
     *
     * @param result a writable list of elements (element type: <code>Object</code>)
     * @param widget the widget
     */
    private void internalCollectChecked(List result, Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            if ( null !is cast(TreeItem)item && (cast(TreeItem) item).getChecked()) {
                Object data = item.getData();
                if (data !is null) {
                    result.add(data);
                }
            }
            internalCollectChecked(result, item);
        }
    }

    /**
     * Gathers the grayed states of the given widget and its
     * descendents, following a pre-order traversal of the tree.
     *
     * @param result a writable list of elements (element type: <code>Object</code>)
     * @param widget the widget
     */
    private void internalCollectGrayed(List result, Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            Item item = items[i];
            if (null !is cast(TreeItem)item && (cast(TreeItem) item).getGrayed()) {
                Object data = item.getData();
                if (data !is null) {
                    result.add(data);
                }
            }
            internalCollectGrayed(result, item);
        }
    }

    /**
     * Sets the checked state of all items to correspond to the given set of checked elements.
     *
     * @param checkedElements the set (element type: <code>Object</code>) of elements which are checked
     * @param widget the widget
     */
    private void internalSetChecked(CustomHashtable checkedElements,
            Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            TreeItem item = cast(TreeItem) items[i];
            Object data = item.getData();
            if (data !is null) {
                bool checked = checkedElements.containsKey(data);
                if (checked !is item.getChecked()) {
                    item.setChecked(checked);
                }
            }
            internalSetChecked(checkedElements, item);
        }
    }

    /**
     * Sets the grayed state of all items to correspond to the given set of grayed elements.
     *
     * @param grayedElements the set (element type: <code>Object</code>) of elements which are grayed
     * @param widget the widget
     */
    private void internalSetGrayed(CustomHashtable grayedElements, Widget widget) {
        Item[] items = getChildren(widget);
        for (int i = 0; i < items.length; i++) {
            TreeItem item = cast(TreeItem) items[i];
            Object data = item.getData();
            if (data !is null) {
                bool grayed = grayedElements.containsKey(data);
                if (grayed !is item.getGrayed()) {
                    item.setGrayed(grayed);
                }
            }
            internalSetGrayed(grayedElements, item);
        }
    }

    /* (non-Javadoc)
     * Method declared on Viewer.
     */
    protected override void preservingSelection(Runnable updateCode) {

        int n = getItemCount(getControl());
        CustomHashtable checkedNodes = newHashtable(n * 2 + 1);
        CustomHashtable grayedNodes = newHashtable(n * 2 + 1);

        gatherState(checkedNodes, grayedNodes, getControl());

        super.preservingSelection(updateCode);

        applyState(checkedNodes, grayedNodes, getControl());
    }

    /* (non-Javadoc)
     * Method declared on ICheckable.
     */
    public void removeCheckStateListener(ICheckStateListener listener) {
        checkStateListeners.remove(cast(Object)listener);
    }

    /* (non-Javadoc)
     * Method declared on ICheckable.
     */
    public bool setChecked(Object element, bool state) {
        Assert.isNotNull(element);
        Widget widget = internalExpand(element, false);
        if ( auto ti = cast(TreeItem) widget ) {
            ti.setChecked(state);
            return true;
        }
        return false;
    }

    /**
     * Sets the checked state for the children of the given item.
     *
     * @param item the item
     * @param state <code>true</code> if the item should be checked,
     *  and <code>false</code> if it should be unchecked
     */
    private void setCheckedChildren(Item item, bool state) {
        createChildren(item);
        Item[] items = getChildren(item);
        if (items !is null) {
            for (int i = 0; i < items.length; i++) {
                Item it = items[i];
                if (it.getData() !is null && (null !is cast(TreeItem)it )) {
                    TreeItem treeItem = cast(TreeItem) it;
                    treeItem.setChecked(state);
                    setCheckedChildren(treeItem, state);
                }
            }
        }
    }

    /**
     * Sets which elements are checked in this viewer's tree.
     * The given list contains the elements that are to be checked;
     * all other elements are to be unchecked.
     * Does not fire events to check state listeners.
     * <p>
     * This method is typically used when restoring the interesting
     * state of a viewer captured by an earlier call to <code>getCheckedElements</code>.
     * </p>
     *
     * @param elements the array of checked elements
     * @see #getCheckedElements
     */
    public void setCheckedElements(Object[] elements) {
        assertElementsNotNull(elements);
        CustomHashtable checkedElements = newHashtable(elements.length * 2 + 1);
        for (int i = 0; i < elements.length; ++i) {
            Object element = elements[i];
            // Ensure item exists for element
            internalExpand(element, false);
            checkedElements.put(element, element);
        }
        Control tree = getControl();
        tree.setRedraw(false);
        internalSetChecked(checkedElements, tree);
        tree.setRedraw(true);
    }

    /**
     * Sets the grayed state for the given element in this viewer.
     *
     * @param element the element
     * @param state <code>true</code> if the item should be grayed,
     *  and <code>false</code> if it should be ungrayed
     * @return <code>true</code> if the gray state could be set,
     *  and <code>false</code> otherwise
     */
    public bool setGrayed(Object element, bool state) {
        Assert.isNotNull(element);
        Widget widget = internalExpand(element, false);
        if ( auto ti = cast(TreeItem) widget ) {
            ti.setGrayed(state);
            return true;
        }
        return false;
    }

    /**
     * Check and gray the selection rather than calling both
     * setGrayed and setChecked as an optimization.
     * Does not fire events to check state listeners.
     * @param element the item being checked
     * @param state a bool indicating selection or deselection
     * @return bool indicating success or failure.
     */
    public bool setGrayChecked(Object element, bool state) {
        Assert.isNotNull(element);
        Widget widget = internalExpand(element, false);
        if (auto item = cast(TreeItem)widget ) {
            item.setChecked(state);
            item.setGrayed(state);
            return true;
        }
        return false;
    }

    /**
     * Sets which elements are grayed in this viewer's tree.
     * The given list contains the elements that are to be grayed;
     * all other elements are to be ungrayed.
     * <p>
     * This method is typically used when restoring the interesting
     * state of a viewer captured by an earlier call to <code>getGrayedElements</code>.
     * </p>
     *
     * @param elements the array of grayed elements
     *
     * @see #getGrayedElements
     */
    public void setGrayedElements(Object[] elements) {
        assertElementsNotNull(elements);
        CustomHashtable grayedElements = newHashtable(elements.length * 2 + 1);
        for (int i = 0; i < elements.length; ++i) {
            Object element = elements[i];
            // Ensure item exists for element
            internalExpand(element, false);
            grayedElements.put(element, element);
        }
        Control tree = getControl();
        tree.setRedraw(false);
        internalSetGrayed(grayedElements, tree);
        tree.setRedraw(true);
    }

    /**
     * Sets the grayed state for the given element and its parents
     * in this viewer.
     *
     * @param element the element
     * @param state <code>true</code> if the item should be grayed,
     *  and <code>false</code> if it should be ungrayed
     * @return <code>true</code> if the element is visible and the gray
     *  state could be set, and <code>false</code> otherwise
     * @see #setGrayed
     */
    public bool setParentsGrayed(Object element, bool state) {
        Assert.isNotNull(element);
        Widget widget = internalExpand(element, false);
        if (auto item = cast(TreeItem) widget ) {
            item.setGrayed(state);
            item = item.getParentItem();
            while (item !is null) {
                item.setGrayed(state);
                item = item.getParentItem();
            }
            return true;
        }
        return false;
    }

    /**
     * Sets the checked state for the given element and its visible
     * children in this viewer.
     * Assumes that the element has been expanded before. To enforce
     * that the item is expanded, call <code>expandToLevel</code>
     * for the element.
     * Does not fire events to check state listeners.
     *
     * @param element the element
     * @param state <code>true</code> if the item should be checked,
     *  and <code>false</code> if it should be unchecked
     * @return <code>true</code> if the checked state could be set,
     *  and <code>false</code> otherwise
     */
    public bool setSubtreeChecked(Object element, bool state) {
        Widget widget = internalExpand(element, false);
        if (auto item = cast(TreeItem) widget ) {
            item.setChecked(state);
            setCheckedChildren(item, state);
            return true;
        }
        return false;
    }

    /**
     * Sets to the given value the checked state for all elements in this viewer.
     * Does not fire events to check state listeners.
     * Assumes that the element has been expanded before. To enforce
     * that the item is expanded, call <code>expandToLevel</code>
     * for the element.
     *
     * @param state <code>true</code> if the element should be checked,
     *  and <code>false</code> if it should be unchecked
     * @deprecated as this method only checks or unchecks visible items
     * is is recommended that {@link #setSubtreeChecked(Object, bool)}
     * is used instead.
     * @see #setSubtreeChecked(Object, bool)
     *
     *  @since 3.2
     */
    public void setAllChecked(bool state) {
        setAllChecked(state,  getTree().getItems());

    }

    /**
     * Set the checked state of the visible items and their children to state.
     * @param state
     * @param items
     * @deprecated
     * @see #setAllChecked(bool)
     */
    private void setAllChecked(bool state, TreeItem[] items) {
        for (int i = 0; i < items.length; i++) {
            items[i].setChecked(state);
            TreeItem[] children = items[i].getItems();
            setAllChecked(state, children);
        }
    }
}
