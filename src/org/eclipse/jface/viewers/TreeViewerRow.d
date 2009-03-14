/*******************************************************************************
 * Copyright (c) 2006, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - initial API and implementation
 *                                               - fix in bug: 174355,171126,,195908,198035,215069,227421
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TreeViewerRow;

import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.TreePath;


import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.LinkedList;
import java.util.Set;

/**
 * TreeViewerRow is the Tree implementation of ViewerRow.
 *
 * @since 3.3
 *
 */
public class TreeViewerRow : ViewerRow {
    private TreeItem item;

    /**
     * Create a new instance of the receiver.
     *
     * @param item
     */
    this(TreeItem item) {
        this.item = item;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getBounds(int)
     */
    public override Rectangle getBounds(int columnIndex) {
        return item.getBounds(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getBounds()
     */
    public override Rectangle getBounds() {
        return item.getBounds();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getColumnCount()
     */
    public override int getColumnCount() {
        return item.getParent().getColumnCount();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getItem()
     */
    public override Widget getItem() {
        return item;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getBackground(int)
     */
    public override Color getBackground(int columnIndex) {
        return item.getBackground(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getFont(int)
     */
    public override Font getFont(int columnIndex) {
        return item.getFont(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getForeground(int)
     */
    public override Color getForeground(int columnIndex) {
        return item.getForeground(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getImage(int)
     */
    public override Image getImage(int columnIndex) {
        return item.getImage(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getText(int)
     */
    public override String getText(int columnIndex) {
        return item.getText(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#setBackground(int,
     *      org.eclipse.swt.graphics.Color)
     */
    public override void setBackground(int columnIndex, Color color) {
        item.setBackground(columnIndex, color);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#setFont(int,
     *      org.eclipse.swt.graphics.Font)
     */
    public override void setFont(int columnIndex, Font font) {
        item.setFont(columnIndex, font);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#setForeground(int,
     *      org.eclipse.swt.graphics.Color)
     */
    public override void setForeground(int columnIndex, Color color) {
        item.setForeground(columnIndex, color);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#setImage(int,
     *      org.eclipse.swt.graphics.Image)
     */
    public override void setImage(int columnIndex, Image image) {
        Image oldImage = item.getImage(columnIndex);
        if (image !is oldImage) {
            item.setImage(columnIndex, image);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#setText(int, java.lang.String)
     */
    public override void setText(int columnIndex, String text) {
        item.setText(columnIndex, text is null ? "" : text); //$NON-NLS-1$
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ViewerRow#getControl()
     */
    public override Control getControl() {
        return item.getParent();
    }


    public override ViewerRow getNeighbor(int direction, bool sameLevel) {
        if (direction is ViewerRow.ABOVE) {
            return getRowAbove(sameLevel);
        } else if (direction is ViewerRow.BELOW) {
            return getRowBelow(sameLevel);
        } else {
            throw new IllegalArgumentException(
                    "Illegal value of direction argument."); //$NON-NLS-1$
        }
    }

    private ViewerRow getRowBelow(bool sameLevel) {
        Tree tree = item.getParent();

        // This means we have top-level item
        if (item.getParentItem() is null) {
            if (sameLevel || !item.getExpanded()) {
                int index = tree.indexOf(item) + 1;

                if (index < tree.getItemCount()) {
                    return new TreeViewerRow(tree.getItem(index));
                }
            } else if (item.getExpanded() && item.getItemCount() > 0) {
                return new TreeViewerRow(item.getItem(0));
            }
        } else {
            if (sameLevel || !item.getExpanded()) {
                TreeItem parentItem = item.getParentItem();

                int nextIndex = parentItem.indexOf(item) + 1;
                int totalIndex = parentItem.getItemCount();

                TreeItem itemAfter;

                // This would mean that it was the last item
                if (nextIndex is totalIndex) {
                    itemAfter = findNextItem(parentItem);
                } else {
                    itemAfter = parentItem.getItem(nextIndex);
                }

                if (itemAfter !is null) {
                    return new TreeViewerRow(itemAfter);
                }

            } else if (item.getExpanded() && item.getItemCount() > 0) {
                return new TreeViewerRow(item.getItem(0));
            }
        }

        return null;
    }

    private ViewerRow getRowAbove(bool sameLevel) {
        Tree tree = item.getParent();

        // This means we have top-level item
        if (item.getParentItem() is null) {
            int index = tree.indexOf(item) - 1;
            TreeItem nextTopItem = null;

            if (index >= 0) {
                nextTopItem = tree.getItem(index);
            }

            if (nextTopItem !is null) {
                if (sameLevel) {
                    return new TreeViewerRow(nextTopItem);
                }

                return new TreeViewerRow(findLastVisibleItem(nextTopItem));
            }
        } else {
            TreeItem parentItem = item.getParentItem();
            int previousIndex = parentItem.indexOf(item) - 1;

            TreeItem itemBefore;
            if (previousIndex >= 0) {
                if (sameLevel) {
                    itemBefore = parentItem.getItem(previousIndex);
                } else {
                    itemBefore = findLastVisibleItem(parentItem
                            .getItem(previousIndex));
                }
            } else {
                itemBefore = parentItem;
            }

            if (itemBefore !is null) {
                return new TreeViewerRow(itemBefore);
            }
        }

        return null;
    }

    private TreeItem findLastVisibleItem(TreeItem parentItem) {
        TreeItem rv = parentItem;

        while (rv.getExpanded() && rv.getItemCount() > 0) {
            rv = rv.getItem(rv.getItemCount() - 1);
        }

        return rv;
    }

    private TreeItem findNextItem(TreeItem item) {
        TreeItem rv = null;
        Tree tree = item.getParent();
        TreeItem parentItem = item.getParentItem();

        int nextIndex;
        int totalItems;

        if (parentItem is null) {
            nextIndex = tree.indexOf(item) + 1;
            totalItems = tree.getItemCount();
        } else {
            nextIndex = parentItem.indexOf(item) + 1;
            totalItems = parentItem.getItemCount();
        }

        // This is once more the last item in the tree
        // Search on
        if (nextIndex is totalItems) {
            if (item.getParentItem() !is null) {
                rv = findNextItem(item.getParentItem());
            }
        } else {
            if (parentItem is null) {
                rv = tree.getItem(nextIndex);
            } else {
                rv = parentItem.getItem(nextIndex);
            }
        }

        return rv;
    }

    public override TreePath getTreePath() {
        TreeItem tItem = item;
        LinkedList segments = new LinkedList();
        while (tItem !is null) {
            Object segment = tItem.getData();
            Assert.isNotNull(segment);
            segments.addFirst(segment);
            tItem = tItem.getParentItem();
        }

        return new TreePath(segments.toArray());
    }

    void setItem(TreeItem item) {
        this.item = item;
    }

    public override Object clone() {
        return new TreeViewerRow(item);
    }

    public override Object getElement() {
        return item.getData();
    }

    public int getVisualIndex(int creationIndex) {
        int[] order = item.getParent().getColumnOrder();

        for (int i = 0; i < order.length; i++) {
            if (order[i] is creationIndex) {
                return i;
            }
        }

        return super.getVisualIndex(creationIndex);
    }

    public int getCreationIndex(int visualIndex) {
        if( item !is null && ! item.isDisposed() && hasColumns() && isValidOrderIndex(visualIndex) ) {
            return item.getParent().getColumnOrder()[visualIndex];
        }
        return super.getCreationIndex(visualIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getTextBounds(int)
     */
    public Rectangle getTextBounds(int index) {
        return item.getTextBounds(index);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getImageBounds(int)
     */
    public Rectangle getImageBounds(int index) {
        return item.getImageBounds(index);
    }

    private bool hasColumns() {
        return this.item.getParent().getColumnCount() !is 0;
    }

    private bool isValidOrderIndex(int currentIndex) {
        return currentIndex < this.item.getParent().getColumnOrder().length;
    }

    int getWidth(int columnIndex) {
        return item.getParent().getColumn(columnIndex).getWidth();
    }
}
