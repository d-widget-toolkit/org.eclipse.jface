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
 *                                               - fix in bug: 166346,167325,174355,195908,198035,215069,227421
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.ViewerRow;

import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ViewerRow;
import org.eclipse.jface.viewers.TreePath;

import org.eclipse.swt.custom.StyleRange;
import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.jface.util.Policy;

import java.lang.all;
import java.util.Set;

/**
 * ViewerRow is the abstract superclass of the part that represents items in a
 * Table or Tree. Implementors of {@link ColumnViewer} have to provide a
 * concrete implementation for the underlying widget
 *
 * @since 3.3
 *
 */
public abstract class ViewerRow : Cloneable {

    /**
     * Constant denoting the row above the current one (value is 1).
     *
     * @see #getNeighbor(int, bool)
     */
    public static const int ABOVE = 1;

    /**
     * Constant denoting the row below the current one (value is 2).
     *
     * @see #getNeighbor(int, bool)
     */
    public static const int BELOW = 2;

    private static const String KEY_TEXT_LAYOUT = Policy.JFACE ~ "styled_label_key_"; //$NON-NLS-1$

    /**
     * Get the bounds of the entry at the columnIndex,
     *
     * @param columnIndex
     * @return {@link Rectangle}
     */
    public abstract Rectangle getBounds(int columnIndex);

    /**
     * Return the bounds for the whole item.
     *
     * @return {@link Rectangle}
     */
    public abstract Rectangle getBounds();

    /**
     * Return the item for the receiver.
     *
     * @return {@link Widget}
     */
    public abstract Widget getItem();

    /**
     * Return the number of columns for the receiver.
     *
     * @return the number of columns
     */
    public abstract int getColumnCount();

    /**
     * Return the image at the columnIndex.
     *
     * @param columnIndex
     * @return {@link Image} or <code>null</code>
     */
    public abstract Image getImage(int columnIndex);

    /**
     * Set the image at the columnIndex
     *
     * @param columnIndex
     * @param image
     */
    public abstract void setImage(int columnIndex, Image image);

    /**
     * Get the text at the columnIndex.
     *
     * @param columnIndex
     * @return {@link String}
     */
    public abstract String getText(int columnIndex);

    /**
     * Set the text at the columnIndex
     *
     * @param columnIndex
     * @param text
     */
    public abstract void setText(int columnIndex, String text);

    /**
     * Get the background at the columnIndex,
     *
     * @param columnIndex
     * @return {@link Color} or <code>null</code>
     */
    public abstract Color getBackground(int columnIndex);

    /**
     * Set the background at the columnIndex.
     *
     * @param columnIndex
     * @param color
     */
    public abstract void setBackground(int columnIndex, Color color);

    /**
     * Get the foreground at the columnIndex.
     *
     * @param columnIndex
     * @return {@link Color} or <code>null</code>
     */
    public abstract Color getForeground(int columnIndex);

    /**
     * Set the foreground at the columnIndex.
     *
     * @param columnIndex
     * @param color
     */
    public abstract void setForeground(int columnIndex, Color color);

    /**
     * Get the font at the columnIndex.
     *
     * @param columnIndex
     * @return {@link Font} or <code>null</code>
     */
    public abstract Font getFont(int columnIndex);

    /**
     * Set the {@link Font} at the columnIndex.
     *
     * @param columnIndex
     * @param font
     */
    public abstract void setFont(int columnIndex, Font font);

    /**
     * Get the ViewerCell at point.
     *
     * @param point
     * @return {@link ViewerCell}
     */
    public ViewerCell getCell(Point point) {
        int index = getColumnIndex(point);
        return getCell(index);
    }

    /**
     * Get the columnIndex of the point.
     *
     * @param point
     * @return int or -1 if it cannot be found.
     */
    public int getColumnIndex(Point point) {
        int count = getColumnCount();

        // If there are no columns the column-index is 0
        if (count is 0) {
            return 0;
        }

        for (int i = 0; i < count; i++) {
            if (getBounds(i).contains(point)) {
                return i;
            }
        }

        return -1;
    }

    /**
     * Get a ViewerCell for the column at index.
     *
     * @param column
     * @return {@link ViewerCell} or <code>null</code> if the index is
     *         negative.
     */
    public ViewerCell getCell(int column) {
        if (column >= 0)
            return new ViewerCell(cast(ViewerRow) clone(), column, getElement());

        return null;
    }

    /**
     * Get the Control for the receiver.
     *
     * @return {@link Control}
     */
    public abstract Control getControl();

    /**
     * Returns a neighboring row, or <code>null</code> if no neighbor exists
     * in the given direction. If <code>sameLevel</code> is <code>true</code>,
     * only sibling rows (under the same parent) will be considered.
     *
     * @param direction
     *            the direction {@link #BELOW} or {@link #ABOVE}
     *
     * @param sameLevel
     *            if <code>true</code>, search only within sibling rows
     * @return the row above/below, or <code>null</code> if not found
     */
    public abstract ViewerRow getNeighbor(int direction, bool sameLevel);

    /**
     * The tree path used to identify an element by the unique path
     *
     * @return the path
     */
    public abstract TreePath getTreePath();

    public /+override+/ abstract Object clone();

    /**
     * @return the model element
     */
    public abstract Object getElement();

    public override hash_t toHash() {
        final int prime = 31;
        int result = 1;
        result = prime * result
                + ((getItem() is null) ? 0 : getItem().toHash());
        return result;
    }

    public override int opEquals(Object obj) {
        if (this is obj)
            return true;
        if (obj is null)
            return false;
        if (this.classinfo !is obj.classinfo)
            return false;
        ViewerRow other = cast(ViewerRow) obj;
        if (getItem() is null) {
            if (other.getItem() !is null)
                return false;
        } else if (!getItem().opEquals(other.getItem()))
            return false;
        return true;
    }

    /**
     * The cell at the current index (as shown in the UI). This can be different
     * to the original index when columns are reordered.
     *
     * @param visualIndex
     *            the current index (as shown in the UI)
     * @return the cell at the currently visible index
     */
    ViewerCell getCellAtVisualIndex(int visualIndex) {
        return getCell(getCreationIndex(visualIndex));
    }

    /**
     * Translate the original column index to the actual one.
     * <p>
     * <b>Because of backwards API compatibility the default implementation
     * returns the original index. Implementators of {@link ColumnViewer} should
     * overwrite this method if their widget supports reordered columns</b>
     * </p>
     *
     * @param creationIndex
     *            the original index
     * @return the current index (as shown in the UI)
     * @since 3.4
     */
    protected int getVisualIndex(int creationIndex) {
        return creationIndex;
    }
    package int getVisualIndex_package(int creationIndex) {
        return getVisualIndex(creationIndex);
    }

    /**
     * Translate the current column index (as shown in the UI) to the original
     * one.
     * <p>
     * <b>Because of backwards API compatibility the default implementation
     * returns the original index. Implementators of {@link ColumnViewer} should
     * overwrite this method if their widget supports reordered columns</b>
     * </p>
     *
     * @param visualIndex
     *            the current index (as shown in the UI)
     * @return the original index
     * @since 3.4
     */
    protected int getCreationIndex(int visualIndex) {
        return visualIndex;
    }
    package int getCreationIndex_package(int visualIndex) {
        return getCreationIndex(visualIndex);
    }

    /**
     * The location and bounds of the area where the text is drawn depends on
     * various things (image displayed, control with SWT.CHECK)
     *
     * @param index
     *            the column index
     * @return the bounds of the of the text area. May return <code>null</code>
     *         if the underlying widget implementation doesn't provide this
     *         information
     * @since 3.4
     */
    public Rectangle getTextBounds(int index) {
        return null;
    }


    /**
     * Returns the location and bounds of the area where the image is drawn.
     *
     * @param index
     *            the column index
     * @return the bounds of the of the image area. May return <code>null</code>
     *         if the underlying widget implementation doesn't provide this
     *         information
     * @since 3.4
     */
    public Rectangle getImageBounds(int index) {
        return null;
    }

    /**
     * Set the style ranges to be applied on the text label at the column index
     * Note: Requires {@link StyledCellLabelProvider} with owner draw enabled.
     *
     * @param columnIndex the index of the column
     * @param styleRanges the styled ranges
     *
     * @since 3.4
     */
    public void setStyleRanges(int columnIndex, StyleRange[] styleRanges) {
        getItem().setData(KEY_TEXT_LAYOUT ~ String_valueOf(columnIndex), new ArrayWrapperT!(StyleRange)(styleRanges));
    }


    /**
     * Returns the style ranges to be applied on the text label at the column index or <code>null</code> if no
     * style ranges have been set.
     *
     * @param columnIndex the index of the column
     * @return styleRanges the styled ranges
     *
     * @since 3.4
     */
    public StyleRange[] getStyleRanges(int columnIndex) {
        return (cast(ArrayWrapperT!(StyleRange)) getItem().getData(KEY_TEXT_LAYOUT ~ String_valueOf(columnIndex))).array;
    }
    
    int getWidth(int columnIndex) {
        return getBounds(columnIndex).width;
    }
}
