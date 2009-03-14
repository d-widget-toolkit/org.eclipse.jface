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
 *                                               - fix in bug: 174355,195908,198035,215069,227421
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TableViewerRow;

import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.TreePath;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.TableItem;
import org.eclipse.swt.widgets.Widget;

import java.lang.all;
import java.util.Set;

/**
 * TableViewerRow is the Table specific implementation of ViewerRow
 * @since 3.3
 *
 */
public class TableViewerRow : ViewerRow {
    private TableItem item;

    /**
     * Create a new instance of the receiver from item.
     * @param item
     */
    this(TableItem item) {
        this.item = item;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getBounds(int)
     */
    public override Rectangle getBounds(int columnIndex) {
        return item.getBounds(columnIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getBounds()
     */
    public override Rectangle getBounds() {
        return item.getBounds();
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getItem()
     */
    public Widget getItem() {
        return item;
    }

    void setItem(TableItem item) {
        this.item = item;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getColumnCount()
     */
    public override int getColumnCount() {
        return item.getParent().getColumnCount();
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getBackground(int)
     */
    public override Color getBackground(int columnIndex) {
        return item.getBackground(columnIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getFont(int)
     */
    public override Font getFont(int columnIndex) {
        return item.getFont(columnIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getForeground(int)
     */
    public override Color getForeground(int columnIndex) {
        return item.getForeground(columnIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getImage(int)
     */
    public override Image getImage(int columnIndex) {
        return item.getImage(columnIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getText(int)
     */
    public override String getText(int columnIndex) {
        return item.getText(columnIndex);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#setBackground(int, org.eclipse.swt.graphics.Color)
     */
    public override void setBackground(int columnIndex, Color color) {
        item.setBackground(columnIndex, color);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#setFont(int, org.eclipse.swt.graphics.Font)
     */
    public override void setFont(int columnIndex, Font font) {
        item.setFont(columnIndex, font);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#setForeground(int, org.eclipse.swt.graphics.Color)
     */
    public override void setForeground(int columnIndex, Color color) {
        item.setForeground(columnIndex, color);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#setImage(int, org.eclipse.swt.graphics.Image)
     */
    public override void setImage(int columnIndex, Image image) {
        Image oldImage = item.getImage(columnIndex);
        if (oldImage !is image) {
            item.setImage(columnIndex,image);
        }
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#setText(int, java.lang.String)
     */
    public override void setText(int columnIndex, String text) {
        item.setText(columnIndex, text is null ? "" : text); //$NON-NLS-1$
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ViewerRow#getControl()
     */
    public override Control getControl() {
        return item.getParent();
    }

    public override ViewerRow getNeighbor(int direction, bool sameLevel) {
        if( direction is ViewerRow.ABOVE ) {
            return getRowAbove();
        } else if( direction is ViewerRow.BELOW ) {
            return getRowBelow();
        } else {
            throw new IllegalArgumentException("Illegal value of direction argument."); //$NON-NLS-1$
        }
    }


    private ViewerRow getRowAbove() {
        int index = item.getParent().indexOf(item) - 1;

        if( index >= 0 ) {
            return new TableViewerRow(item.getParent().getItem(index));
        }

        return null;
    }

    private ViewerRow getRowBelow() {
        int index = item.getParent().indexOf(item) + 1;

        if( index < item.getParent().getItemCount() ) {
            TableItem tmp = item.getParent().getItem(index);
            //TODO NULL can happen in case of VIRTUAL => How do we deal with that
            if( tmp !is null ) {
                return new TableViewerRow(tmp);
            }
        }

        return null;
    }

    public override TreePath getTreePath() {
        return new TreePath([item.getData()]);
    }

    public override Object clone() {
        return new TableViewerRow(item);
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
