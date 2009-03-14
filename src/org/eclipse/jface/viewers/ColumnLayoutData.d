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
module org.eclipse.jface.viewers.ColumnLayoutData;

import java.lang.all;

/**
 * An abstract column layout data describing the information needed
 * (by <code>TableLayout</code>) to properly lay out a table.
 * <p>
 * This class is not intended to be subclassed outside the framework.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public abstract class ColumnLayoutData {

    /**
     * Indicates whether the column is resizable.
     */
    public bool resizable;

    /**
     * Creates a new column layout data object.
     *
     * @param resizable <code>true</code> if the column is resizable, and <code>false</code> if not
     */
    protected this(bool resizable) {
        this.resizable = resizable;
    }
}
