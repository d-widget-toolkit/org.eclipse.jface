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
module org.eclipse.jface.action.ContributionManager;

import org.eclipse.jface.action.ActionContributionItem;

import org.eclipse.jface.action.IContributionManager;
import org.eclipse.jface.action.IContributionItem;
import org.eclipse.jface.action.IContributionManagerOverrides;
import org.eclipse.jface.action.IAction;


import org.eclipse.core.runtime.Assert;
import org.eclipse.jface.util.Policy;

import java.lang.all;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

/**
 * Abstract base class for all contribution managers, and standard
 * implementation of <code>IContributionManager</code>. This class provides
 * functionality common across the specific managers defined by this framework.
 * <p>
 * This class maintains a list of contribution items and a dirty flag, both as
 * internal state. In addition to providing implementations of most
 * <code>IContributionManager</code> methods, this class automatically
 * coalesces adjacent separators, hides beginning and ending separators, and
 * deals with dynamically changing sets of contributions. When the set of
 * contributions does change dynamically, the changes are propagated to the
 * control via the <code>update</code> method, which subclasses must
 * implement.
 * </p>
 * <p>
 * Note: A <code>ContributionItem</code> cannot be shared between different
 * <code>ContributionManager</code>s.
 * </p>
 */
public abstract class ContributionManager : IContributionManager {

    // Internal debug flag.
    // protected static final bool DEBUG = false;

    /**
     * The list of contribution items.
     */
    private List contributions;

    /**
     * Indicates whether the widgets are in sync with the contributions.
     */
    private bool isDirty_ = true;

    /**
     * Number of dynamic contribution items.
     */
    private int dynamicItems = 0;

    /**
     * The overrides for items of this manager
     */
    private IContributionManagerOverrides overrides;

    /**
     * Creates a new contribution manager.
     */
    protected this() {
        contributions = new ArrayList();
        // Do nothing.
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void add(IAction action) {
        Assert.isNotNull( cast(Object)action, "Action must not be null"); //$NON-NLS-1$
        add(new ActionContributionItem(action));
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void add(IContributionItem item) {
        Assert.isNotNull( cast(Object)item, "Item must not be null"); //$NON-NLS-1$
        if (allowItem(item)) {
            contributions.add(cast(Object)item);
            itemAdded(item);
        }
    }

    /**
     * Adds a contribution item to the start or end of the group with the given
     * name.
     *
     * @param groupName
     *            the name of the group
     * @param item
     *            the contribution item
     * @param append
     *            <code>true</code> to add to the end of the group, and
     *            <code>false</code> to add the beginning of the group
     * @exception IllegalArgumentException
     *                if there is no group with the given name
     */
    private void addToGroup(String groupName, IContributionItem item,
            bool append) {
        int i;
        auto items = contributions.iterator();
        for (i = 0; items.hasNext(); i++) {
            IContributionItem o = cast(IContributionItem) items.next();
            if (o.isGroupMarker()) {
                String id = o.getId();
                if (id !is null && id.equalsIgnoreCase(groupName)) {
                    i++;
                    if (append) {
                        for (; items.hasNext(); i++) {
                            IContributionItem ci = cast(IContributionItem) items
                                    .next();
                            if (ci.isGroupMarker()) {
                                break;
                            }
                        }
                    }
                    if (allowItem(item)) {
                        contributions.add(i, cast(Object)item);
                        itemAdded(item);
                    }
                    return;
                }
            }
        }
        throw new IllegalArgumentException("Group not found: " ~ groupName);//$NON-NLS-1$
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void appendToGroup(String groupName, IAction action) {
        addToGroup(groupName, new ActionContributionItem(action), true);
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void appendToGroup(String groupName, IContributionItem item) {
        addToGroup(groupName, item, true);
    }

    /**
     * This method allows subclasses of <code>ContributionManager</code> to
     * prevent certain items in the contributions list.
     * <code>ContributionManager</code> will either block or allow an addition
     * based on the result of this method call. This can be used to prevent
     * duplication, for example.
     *
     * @param itemToAdd
     *            The contribution item to be added; may be <code>null</code>.
     * @return <code>true</code> if the addition should be allowed;
     *         <code>false</code> otherwise. The default implementation allows
     *         all items.
     * @since 3.0
     */
    protected bool allowItem(IContributionItem itemToAdd) {
        return true;
    }

    /**
     * Internal debug method for printing statistics about this manager to
     * <code>System.out</code>.
     */
    protected void dumpStatistics() {
        int size = 0;
        if (contributions !is null) {
            size = contributions.size();
        }

        getDwtLogger().info( __FILE__, __LINE__, "{}", this.toString());
        getDwtLogger().info( __FILE__, __LINE__, "   Number of elements: {}", size);//$NON-NLS-1$
        int sum = 0;
        for (int i = 0; i < size; i++) {
            if ((cast(IContributionItem) contributions.get(i)).isVisible()) {
                sum++;
            }
        }
        getDwtLogger().info( __FILE__, __LINE__, "   Number of visible elements: {}", sum);//$NON-NLS-1$
        getDwtLogger().info( __FILE__, __LINE__, "   Is dirty: {}", isDirty()); //$NON-NLS-1$
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public IContributionItem find(String id) {
        auto e = contributions.iterator();
        while (e.hasNext()) {
            IContributionItem item = cast(IContributionItem) e.next();
            String itemId = item.getId();
            if (itemId !is null && itemId.equalsIgnoreCase(id)) {
                return item;
            }
        }
        return null;
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public IContributionItem[] getItems() {
        IContributionItem[] items = arraycast!(IContributionItem)(contributions.toArray());
        return items;
    }

    /**
     * Return the number of contributions in this manager.
     *
     * @return the number of contributions in this manager
     * @since 3.3
     */
    public int getSize() {
        return contributions.size();
    }

    /**
     * The <code>ContributionManager</code> implementation of this method
     * declared on <code>IContributionManager</code> returns the current
     * overrides. If there is no overrides it lazily creates one which overrides
     * no item state.
     *
     * @since 2.0
     */
    public IContributionManagerOverrides getOverrides() {
        if (overrides is null) {
            overrides = new class IContributionManagerOverrides {
                public Boolean getEnabled(IContributionItem item) {
                    return null;
                }

                public Integer getAccelerator(IContributionItem item) {
                    return null;
                }

                public String getAcceleratorText(IContributionItem item) {
                    return null;
                }

                public String getText(IContributionItem item) {
                    return null;
                }
            };
        }
        return overrides;
    }

    /**
     * Returns whether this contribution manager contains dynamic items. A
     * dynamic contribution item contributes items conditionally, dependent on
     * some internal state.
     *
     * @return <code>true</code> if this manager contains dynamic items, and
     *         <code>false</code> otherwise
     */
    protected bool hasDynamicItems() {
        return (dynamicItems > 0);
    }

    /**
     * Returns the index of the item with the given id.
     *
     * @param id
     *            The id of the item whose index is requested.
     *
     * @return <code>int</code> the index or -1 if the item is not found
     */
    public int indexOf(String id) {
        for (int i = 0; i < contributions.size(); i++) {
            IContributionItem item = cast(IContributionItem) contributions.get(i);
            String itemId = item.getId();
            if (itemId !is null && itemId.equalsIgnoreCase(id)) {
                return i;
            }
        }
        return -1;
    }

    /**
     * Returns the index of the object in the internal structure. This is
     * different from <code>indexOf(String id)</code> since some contribution
     * items may not have an id.
     *
     * @param item
     *            The contribution item
     * @return the index, or -1 if the item is not found
     * @since 3.0
     */
    protected int indexOf(IContributionItem item) {
        return contributions.indexOf(cast(Object)item);
    }

    /**
     * Insert the item at the given index.
     *
     * @param index
     *            The index to be used for insertion
     * @param item
     *            The item to be inserted
     */
    public void insert(int index, IContributionItem item) {
        if (index > contributions.size()) {
            throw new IndexOutOfBoundsException( Format(
                    "inserting {} at {}", item.getId(), index)); //$NON-NLS-1$ //$NON-NLS-2$
        }
        if (allowItem(item)) {
            contributions.add(index, cast(Object)item);
            itemAdded(item);
        }
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void insertAfter(String ID, IAction action) {
        insertAfter(ID, new ActionContributionItem(action));
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void insertAfter(String ID, IContributionItem item) {
        IContributionItem ci = find(ID);
        if (ci is null) {
            throw new IllegalArgumentException(Format("can't find ID{}", ID));//$NON-NLS-1$
        }
        int ix = contributions.indexOf(cast(Object)ci);
        if (ix >= 0) {
            // System.out.println("insert after: " + ix);
            if (allowItem(item)) {
                contributions.add(ix + 1,cast(Object) item);
                itemAdded(item);
            }
        }
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void insertBefore(String ID, IAction action) {
        insertBefore(ID, new ActionContributionItem(action));
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void insertBefore(String ID, IContributionItem item) {
        IContributionItem ci = find(ID);
        if (ci is null) {
            throw new IllegalArgumentException(Format("can't find ID {}", ID));//$NON-NLS-1$
        }
        int ix = contributions.indexOf(cast(Object)ci);
        if (ix >= 0) {
            // System.out.println("insert before: " + ix);
            if (allowItem(item)) {
                contributions.add(ix, cast(Object)item);
                itemAdded(item);
            }
        }
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public bool isDirty() {
        if (isDirty_) {
            return true;
        }
        if (hasDynamicItems()) {
            for (Iterator iter = contributions.iterator(); iter.hasNext();) {
                IContributionItem item = cast(IContributionItem) iter.next();
                if (item.isDirty()) {
                    return true;
                }
            }
        }
        return false;
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public bool isEmpty() {
        return contributions.isEmpty();
    }

    /**
     * The given item was added to the list of contributions. Marks the manager
     * as dirty and updates the number of dynamic items, and the memento.
     *
     * @param item
     *            the item to be added
     *
     */
    protected void itemAdded(IContributionItem item) {
        item.setParent(this);
        markDirty();
        if (item.isDynamic()) {
            dynamicItems++;
        }
    }

    /**
     * The given item was removed from the list of contributions. Marks the
     * manager as dirty and updates the number of dynamic items.
     *
     * @param item
     *            remove given parent from list of contributions
     */
    protected void itemRemoved(IContributionItem item) {
        item.setParent(null);
        markDirty();
        if (item.isDynamic()) {
            dynamicItems--;
        }
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void markDirty() {
        setDirty(true);
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void prependToGroup(String groupName, IAction action) {
        addToGroup(groupName, new ActionContributionItem(action), false);
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void prependToGroup(String groupName, IContributionItem item) {
        addToGroup(groupName, item, false);
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public IContributionItem remove(String ID) {
        IContributionItem ci = find(ID);
        if (ci is null) {
            return null;
        }
        return remove(ci);
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public IContributionItem remove(IContributionItem item) {
        if (contributions.remove(cast(Object)item)) {
            itemRemoved(item);
            return item;
        }
        return null;
    }

    /*
     * (non-Javadoc) Method declared on IContributionManager.
     */
    public void removeAll() {
        IContributionItem[] items = getItems();
        contributions.clear();
        for (int i = 0; i < items.length; i++) {
            IContributionItem item = items[i];
            itemRemoved(item);
        }
        dynamicItems = 0;
        markDirty();
    }

    /**
     * Replaces the item of the given identifier with another contribution item.
     * This can be used, for example, to replace large contribution items with
     * placeholders to avoid memory leaks. If the identifier cannot be found in
     * the current list of items, then this does nothing. If multiple
     * occurrences are found, then the replacement items is put in the first
     * position and the other positions are removed.
     *
     * @param identifier
     *            The identifier to look for in the list of contributions;
     *            should not be <code>null</code>.
     * @param replacementItem
     *            The contribution item to replace the old item; must not be
     *            <code>null</code>. Use
     *            {@link org.eclipse.jface.action.ContributionManager#remove(java.lang.String) remove}
     *            if that is what you want to do.
     * @return <code>true</code> if the given identifier can be; <code>
     * @since 3.0
     */
    public bool replaceItem(String identifier,
            IContributionItem replacementItem) {
        if (identifier is null) {
            return false;
        }

        int index = indexOf(identifier);
        if (index < 0) {
            return false; // couldn't find the item.
        }

        // Remove the old item.
        IContributionItem oldItem = cast(IContributionItem) contributions
                .get(index);
        itemRemoved(oldItem);

        // Add the new item.
        contributions.set(index, cast(Object)replacementItem);
        itemAdded(replacementItem); // throws NPE if (replacementItem is null)

        // Go through and remove duplicates.
        for (int i = contributions.size() - 1; i > index; i--) {
            IContributionItem item = cast(IContributionItem) contributions.get(i);
            if ((item !is null) && (identifier.equals(item.getId()))) {
                if (Policy.TRACE_TOOLBAR) {
                    getDwtLogger().info( __FILE__, __LINE__, "Removing duplicate on replace: {}", identifier); //$NON-NLS-1$
                }
                contributions.remove(i);
                itemRemoved(item);
            }
        }

        return true; // success
    }

    /**
     * Sets whether this manager is dirty. When dirty, the list of contributions
     * is not accurately reflected in the corresponding widgets.
     *
     * @param dirty
     *            <code>true</code> if this manager is dirty, and
     *            <code>false</code> if it is up-to-date
     */
    protected void setDirty(bool dirty) {
        isDirty_ = dirty;
    }

    /**
     * Sets the overrides for this contribution manager
     *
     * @param newOverrides
     *            the overrides for the items of this manager
     * @since 2.0
     */
    public void setOverrides(IContributionManagerOverrides newOverrides) {
        overrides = newOverrides;
    }

    /**
     * An internal method for setting the order of the contribution items.
     *
     * @param items
     *            the contribution items in the specified order
     * @since 3.0
     */
    protected void internalSetItems(IContributionItem[] items) {
        contributions.clear();
        for (int i = 0; i < items.length; i++) {
            if (allowItem(items[i])) {
                contributions.add(cast(Object)items[i]);
            }
        }
    }
}
