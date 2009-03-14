/*******************************************************************************
 * Copyright (c) 2004, 2005 IBM Corporation and others.
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

module org.eclipse.jface.bindings.keys.ParseException;

import java.lang.all;
import java.text.ParseException;

/**
 * <p>
 * An exception indicating problems while parsing formal string representations
 * of either <code>KeyStroke</code> or <code>KeySequence</code> objects.
 * </p>
 * <p>
 * <code>ParseException</code> objects are immutable. Clients are not
 * permitted to extend this class.
 * </p>
 *
 * @since 3.1
 */
public final class ParseException : Exception {

    /**
     * Generated serial version UID for this class.
     *
     * @since 3.1
     */
    private static const long serialVersionUID = 3257009864814376241L;

    /**
     * Constructs a <code>ParseException</code> with the specified detail
     * message.
     *
     * @param s
     *            the detail message.
     */
    public this(String s) {
        super(s);
    }
}
