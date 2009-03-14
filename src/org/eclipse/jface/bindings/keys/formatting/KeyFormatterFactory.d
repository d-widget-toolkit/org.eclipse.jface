/*******************************************************************************
 * Copyright (c) 2004, 2006 IBM Corporation and others.
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

module org.eclipse.jface.bindings.keys.formatting.KeyFormatterFactory;

import org.eclipse.jface.bindings.keys.formatting.FormalKeyFormatter;
import org.eclipse.jface.bindings.keys.formatting.EmacsKeyFormatter;
import org.eclipse.jface.bindings.keys.formatting.IKeyFormatter;

import java.lang.all;
import java.util.Set;

/**
 * <p>
 * A cache for formatters. It keeps a few instances of pre-defined instances of
 * <code>IKeyFormatter</code> available for use. It also allows the default
 * formatter to be changed.
 * </p>
 *
 * @since 3.1
 * @see org.eclipse.jface.bindings.keys.formatting.IKeyFormatter
 */
public final class KeyFormatterFactory {

    /**
     * The formatter that renders key bindings in a platform-dependent manner.
     */
    private static /+const+/ IKeyFormatter FORMAL_KEY_FORMATTER;

    /**
     * The formatter that renders key bindings in a form similar to XEmacs
     */
    private static /+const+/ IKeyFormatter EMACS_KEY_FORMATTER;

    /**
     * The default formatter. This is normally the formal key formatter, but can
     * be changed by users of this API.
     */
    private static IKeyFormatter defaultKeyFormatter;

    private static void check_static_init(){
        if( FORMAL_KEY_FORMATTER is null ){
            synchronized if( FORMAL_KEY_FORMATTER is null ){
                FORMAL_KEY_FORMATTER = new FormalKeyFormatter();
                EMACS_KEY_FORMATTER = new EmacsKeyFormatter();
                defaultKeyFormatter = FORMAL_KEY_FORMATTER;
            }
        }
    }

    /**
     * An accessor for the current default key formatter.
     *
     * @return The default formatter; never <code>null</code>.
     */
    public static final IKeyFormatter getDefault() {
        check_static_init();
        return defaultKeyFormatter;
    }

    /**
     * Provides an instance of <code>EmacsKeyFormatter</code>.
     *
     * @return The Xemacs formatter; never <code>null</code>.
     */
    public static final IKeyFormatter getEmacsKeyFormatter() {
        check_static_init();
        return EMACS_KEY_FORMATTER;
    }

    /**
     * Provides an instance of <code>FormalKeyFormatter</code>.
     *
     * @return The formal formatter; never <code>null</code>.
     */
    public static final IKeyFormatter getFormalKeyFormatter() {
        check_static_init();
        return FORMAL_KEY_FORMATTER;
    }

    /**
     * Sets the default key formatter.
     *
     * @param defaultKeyFormatter
     *            the default key formatter. Must not be <code>null</code>.
     */
    public static final void setDefault(IKeyFormatter defaultKeyFormatter) {
        check_static_init();
        if (defaultKeyFormatter is null) {
            throw new NullPointerException();
        }

        KeyFormatterFactory.defaultKeyFormatter = defaultKeyFormatter;
    }

    /**
     * This class should not be instantiated.
     */
    private this() {
        // Not to be constructred.
    }
}
