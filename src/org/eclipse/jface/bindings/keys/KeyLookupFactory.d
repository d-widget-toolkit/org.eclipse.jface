/*******************************************************************************
 * Copyright (c) 2005, 2006 IBM Corporation and others.
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
module org.eclipse.jface.bindings.keys.KeyLookupFactory;

import org.eclipse.jface.bindings.keys.SWTKeyLookup;
import org.eclipse.jface.bindings.keys.IKeyLookup;

import java.lang.all;
import java.util.Set;

/**
 * <p>
 * A factory class for <code>ILookup</code> instances. This factory can be
 * used to retrieve instances of look-ups defined by this package. It also
 * allows you to define your own look-up for use in the classes.
 * </p>
 *
 * @since 3.1
 */
public final class KeyLookupFactory {

    /**
     * The SWT key look-up defined by this package.
     */
    private static SWTKeyLookup SWT_KEY_LOOKUP;

    /**
     * The instance that should be used by <code>KeyStroke</code> in
     * converting string representations to instances.
     */
    private static IKeyLookup defaultLookup;

    private static void check_staticthis(){
        if( SWT_KEY_LOOKUP is null ){
            synchronized{
                if( SWT_KEY_LOOKUP is null ){
                    SWT_KEY_LOOKUP = new SWTKeyLookup();
                    defaultLookup = SWT_KEY_LOOKUP;
                }
            }
        }
    }

    /**
     * Provides an instance of <code>SWTKeyLookup</code>.
     *
     * @return The SWT look-up table for key stroke format information; never
     *         <code>null</code>.
     */
    public static final IKeyLookup getSWTKeyLookup() {
        check_staticthis();
        return SWT_KEY_LOOKUP;
    }

    /**
     * An accessor for the current default look-up.
     *
     * @return The default look-up; never <code>null</code>.
     */
    public static final IKeyLookup getDefault() {
        check_staticthis();
        return defaultLookup;
    }

    /**
     * Sets the default look-up.
     *
     * @param defaultLookup
     *            the default look-up. Must not be <code>null</code>.
     */
    public static final void setDefault(IKeyLookup defaultLookup) {
        check_staticthis();
        if (defaultLookup is null) {
            throw new NullPointerException("The look-up must not be null"); //$NON-NLS-1$
        }

        KeyLookupFactory.defaultLookup = defaultLookup;
    }

    /**
     * This class should not be instantiated.
     */
    private this() {
        // Not to be constructred.
    }
}
