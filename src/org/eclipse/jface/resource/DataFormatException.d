/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
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
module org.eclipse.jface.resource.DataFormatException;

import java.lang.all;

/**
 * An exception indicating that a string value could not be
 * converted into the requested data type.
 *
 * @see StringConverter
 */
public class DataFormatException : IllegalArgumentException {

    /**
     * Generated serial version UID for this class.
     * @since 3.1
     */
    private static const long serialVersionUID = 3544955467404031538L;

    /**
     * Creates a new exception.
     */
    public this() {
        super("");
    }

    /**
     * Creates a new exception.
     *
     * @param message the message
     */
    public this(String message) {
        super(message);
    }
}
