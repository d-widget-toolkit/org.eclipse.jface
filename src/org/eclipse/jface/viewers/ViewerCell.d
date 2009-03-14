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
 *                                               - fix in bug: 195908,198035,215069,215735,227421
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.ViewerCell;

import org.eclipse.swt.custom.StyleRange;
import org.eclipse.jface.viewers.ViewerRow;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Widget;

import java.lang.all;
import java.util.Set;

/**
 * The ViewerCell is the JFace representation of a cell entry in a ViewerRow.
 *
 * @since 3.3
 *
 */
public class ViewerCell {
    private int columnIndex;

    private ViewerRow row;

    private Object element;

    /**
     * Constant denoting the cell above current one (value is 1).
     */
    public static const int ABOVE = 1;

    /**
     * Constant denoting the cell below current one (value is 2).
     */
    public static const int BELOW = 1 << 1;

    /**
     * Constant denoting the cell to the left of the current one (value is 4).
     */
    public static const int LEFT = 1 << 2;

    /**
     * Constant denoting the cell to the right of the current one (value is 8).
     */
    public static const int RIGHT = 1 << 3;


    /**
     * Create a new instance of the receiver on the row.
     *
     * @param row
     * @param columnIndex
     */
    this(ViewerRow row, int columnIndex, Object element) {
        this.row = row;
        this.columnIndex = columnIndex;
        this.element = element;
    }

    /**
     * Get the index of the cell.
     *
     * @return the index
     */
    public int getColumnIndex() {
        return columnIndex;
    }

    /**
     * Get the bounds of the cell.
     *
     * @return {@link Rectangle}
     */
    public Rectangle getBounds() {
        return row.getBounds(columnIndex);
    }

    /**
     * Get the element this row represents.
     *
     * @return {@link Object}
     */
    public Object getElement() {
        if (element !is null) {
            return element;
        }

        if (row !is null) {
            return row.getElement();
        }

        return null;
    }

    /**
     * Return the text for the cell.
     *
     * @return {@link String}
     */
    public String getText() {
        return row.getText(columnIndex);
    }

    /**
     * Return the Image for the cell.
     *
     * @return {@link Image} or <code>null</code>
     */
    public Image getImage() {
        return row.getImage(columnIndex);
    }

    /**
     * Set the background color of the cell.
     *
     * @param background
     */
    public void setBackground(Color background) {
        row.setBackground(columnIndex, background);

    }

    /**
     * Set the foreground color of the cell.
     *
     * @param foreground
     */
    public void setForeground(Color foreground) {
        row.setForeground(columnIndex, foreground);

    }

    /**
     * Set the font of the cell.
     *
     * @param font
     */
    public void setFont(Font font) {
        row.setFont(columnIndex, font);

    }

    /**
     * Set the text for the cell.
     *
     * @param text
     */
    public void setText(String text) {
        row.setText(columnIndex, text);

    }

    /**
     * Set the Image for the cell.
     *
     * @param image
     */
    public void setImage(Image image) {
        row.setImage(columnIndex, image);

    }

    /**
     * Set the style ranges to be applied on the text label
     * Note: Requires {@link StyledCellLabelProvider} with owner draw enabled.
     *
     * @param styleRanges the styled ranges
     *
     * @since 3.4
     */
    public void setStyleRanges(StyleRange[] styleRanges) {
        row.setStyleRanges(columnIndex, styleRanges);
    }


    /**
     * Returns the style ranges to be applied on the text label or <code>null</code> if no
     * style ranges have been set.
     *
     * @return styleRanges the styled ranges
     *
     * @since 3.4
     */
    public StyleRange[] getStyleRanges() {
        return row.getStyleRanges(columnIndex);
    }

    /**
     * Set the columnIndex.
     *
     * @param column
     */
    void setColumn(int column) {
        columnIndex = column;

    }

    /**
     * Set the row to rowItem and the columnIndex to column.
     *
     * @param rowItem
     * @param column
     */
    void update(ViewerRow rowItem, int column, Object element) {
        row = rowItem;
        columnIndex = column;
        this.element = element;
    }

    /**
     * Return the item for the receiver.
     *
     * @return {@link Item}
     */
    public Widget getItem() {
        return row.getItem();
    }

    /**
     * Get the control for this cell.
     *
     * @return {@link Control}
     */
    public Control getControl() {
        return row.getControl();
    }

    /**
     * Get the current index. This can be different from the original index when
     * columns are reordered
     *
     * @return the current index (as shown in the UI)
     * @since 3.4
     */
    public int getVisualIndex() {
        return row.getVisualIndex_package(getColumnIndex());
    }

    /**
     * Returns the specified neighbor of this cell, or <code>null</code> if no
     * neighbor exists in the given direction. Direction constants can be
     * combined by bitwise OR; for example, this method will return the cell to
     * the upper-left of the current cell by passing {@link #ABOVE} |
     * {@link #LEFT}. If <code>sameLevel</code> is <code>true</code>, only
     * cells in sibling rows (under the same parent) will be considered.
     *
     * @param directionMask
     *            the direction mask used to identify the requested neighbor
     *            cell
     * @param sameLevel
     *            if <code>true</code>, only consider cells from sibling rows
     * @return the requested neighbor cell, or <code>null</code> if not found
     */
    public ViewerCell getNeighbor(int directionMask, bool sameLevel) {
        ViewerRow row;

        if ((directionMask & ABOVE) is ABOVE) {
            row = this.row.getNeighbor(ViewerRow.ABOVE, sameLevel);
        } else if ((directionMask & BELOW) is BELOW) {
            row = this.row.getNeighbor(ViewerRow.BELOW, sameLevel);
        } else {
            row = this.row;
        }

        if (row !is null) {
            int columnIndex;
            columnIndex = getVisualIndex();

            int modifier = 0;

            if ((directionMask & LEFT) is LEFT) {
                modifier = -1;
            } else if ((directionMask & RIGHT) is RIGHT) {
                modifier = 1;
            }

            columnIndex += modifier;

            if (columnIndex >= 0 && columnIndex < row.getColumnCount()) {
                ViewerCell cell = row.getCellAtVisualIndex(columnIndex);
                if( cell !is null ) {
                    while( cell !is null && columnIndex < row.getColumnCount() - 1  && columnIndex > 0 ) {
                        if( cell.isVisible() ) {
                            break;
                        }

                        columnIndex += modifier;
                        cell = row.getCellAtVisualIndex(columnIndex);
                        if( cell is null ) {
                            break;
                        }
                    }
                }

                return cell;
            }
        }

        return null;
    }

    /**
     * @return the row
     */
    public ViewerRow getViewerRow() {
        return row;
    }

    /**
     * The location and bounds of the area where the text is drawn depends on
     * various things (image displayed, control with SWT.CHECK)
     *
     * @return The bounds of the of the text area. May return <code>null</code>
     *         if the underlying widget implementation doesn't provide this
     *         information
     * @since 3.4
     */
    public Rectangle getTextBounds() {
        return row.getTextBounds(columnIndex);
    }

    /**
     * Returns the location and bounds of the area where the image is drawn
     *
     * @return The bounds of the of the image area. May return <code>null</code>
     *         if the underlying widget implementation doesn't provide this
     *         information
     * @since 3.4
     */
    public Rectangle getImageBounds() {
        return row.getImageBounds(columnIndex);
    }

    /**
     * Gets the foreground color of the cell.
     *
     * @return the foreground of the cell or <code>null</code> for the default foreground
     *
     * @since 3.4
     */
    public Color getForeground() {
        return row.getForeground(columnIndex);
    }

    /**
     * Gets the background color of the cell.
     *
     * @return the background of the cell or <code>null</code> for the default background
     *
     * @since 3.4
     */
    public Color getBackground() {
        return row.getBackground(columnIndex);
    }

    /**
     * Gets the font of the cell.
     *
     * @return the font of the cell or <code>null</code> for the default font
     *
     * @since 3.4
     */
    public Font getFont() {
        return row.getFont(columnIndex);
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Object#hashCode()
     */
    public override hash_t toHash() {
        const int prime = 31;
        int result = 1;
        result = prime * result + columnIndex;
        result = prime * result + ((row is null) ? 0 : row.toHash());
        return result;
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Object#equals(java.lang.Object)
     */
    public override int opEquals(Object obj) {
        if (this is obj)
            return true;
        if (obj is null)
            return false;
        if (this.classinfo !is obj.classinfo )
            return false;
        ViewerCell other = cast(ViewerCell) obj;
        if (columnIndex !is other.columnIndex)
            return false;
        if (row is null) {
            if (other.row !is null)
                return false;
        } else if (!row.opEquals(other.row))
            return false;
        return true;
    }
    
    private int getWidth() {
        return row.getWidth(columnIndex);
    }
    
    private bool isVisible() {
        return getWidth() > 0;
    }
}
