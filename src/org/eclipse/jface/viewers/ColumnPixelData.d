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
module org.eclipse.jface.viewers.ColumnPixelData;

import java.lang.all;

import org.eclipse.jface.viewers.ColumnLayoutData;

import org.eclipse.core.runtime.Assert;

/**
 * Describes the width of a table column in pixels, and
 * whether the column is resizable.
 * <p>
 * This class may be instantiated; it is not intended to be subclassed.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class ColumnPixelData : ColumnLayoutData {

   /**
     * The column's width in pixels.
     */
    public int width;

    /**
     * Whether to allocate extra width to the column to account for
     * trim taken by the column itself.
     * The default is <code>false</code> for backwards compatibility, but
     * the recommended practice is to specify <code>true</code>, and
     * specify the desired width for the content of the column, rather
     * than adding a fudge factor to the specified width.
     *
     * @since 3.1
     */
    public bool addTrim = false;

    /**
     * Creates a resizable column width of the given number of pixels.
     *
     * @param widthInPixels the width of column in pixels
     */
    public this(int widthInPixels) {
        this(widthInPixels, true, false);
    }

    /**
     * Creates a column width of the given number of pixels.
     *
     * @param widthInPixels the width of column in pixels
     * @param resizable <code>true</code> if the column is resizable,
     *   and <code>false</code> if size of the column is fixed
     */
    public this(int widthInPixels, bool resizable) {
        this(widthInPixels, resizable, false);
    }

    /**
     * Creates a column width of the given number of pixels.
     *
     * @param widthInPixels
     *            the width of column in pixels
     * @param resizable
     *            <code>true</code> if the column is resizable, and
     *            <code>false</code> if size of the column is fixed
     * @param addTrim
     *            <code>true</code> to allocate extra width to the column to
     *            account for trim taken by the column itself,
     *            <code>false</code> to use the given width exactly
     * @since 3.1
     */
    public this(int widthInPixels, bool resizable, bool addTrim) {
        super(resizable);
        Assert.isTrue(widthInPixels >= 0);
        this.width = widthInPixels;
        this.addTrim = addTrim;
    }
}
