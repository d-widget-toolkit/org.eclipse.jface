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
module org.eclipse.jface.viewers.ColumnWeightData;

import org.eclipse.jface.viewers.ColumnLayoutData;

import org.eclipse.core.runtime.Assert;

import java.lang.all;

/**
 * Describes the width of a table column in terms of a weight,
 * a minimum width, and whether the column is resizable.
 * <p>
 * This class may be instantiated; it is not intended to be subclassed.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class ColumnWeightData : ColumnLayoutData {

    /**
     * Default width of a column (in pixels).
     */
    public static const int MINIMUM_WIDTH = 20;

    /**
     * The column's minimum width in pixels.
     */
    public int minimumWidth;

    /**
     * The column's weight.
     */
    public int weight;

    /**
     * Creates a resizable column width with the given weight and a default
     * minimum width.
     *
     * @param weight the weight of the column
     */
    public this(int weight) {
        this(weight, true);
    }

    /**
     * Creates a resizable column width with the given weight and minimum width.
     *
     * @param weight the weight of the column
     * @param minimumWidth the minimum width of the column in pixels
     */
    public this(int weight, int minimumWidth) {
        this(weight, minimumWidth, true);
    }

    /**
     * Creates a column width with the given weight and minimum width.
     *
     * @param weight the weight of the column
     * @param minimumWidth the minimum width of the column in pixels
     * @param resizable <code>true</code> if the column is resizable,
     *   and <code>false</code> if size of the column is fixed
     */
    public this(int weight, int minimumWidth, bool resizable) {
        super(resizable);
        Assert.isTrue(weight >= 0);
        Assert.isTrue(minimumWidth >= 0);
        this.weight = weight;
        this.minimumWidth = minimumWidth;
    }

    /**
     * Creates a column width with the given weight and a default
     * minimum width.
     *
     * @param weight the weight of the column
     * @param resizable <code>true</code> if the column is resizable,
     *   and <code>false</code> if size of the column is fixed
     */
    public this(int weight, bool resizable) {
        this(weight, MINIMUM_WIDTH, resizable);
    }
}
