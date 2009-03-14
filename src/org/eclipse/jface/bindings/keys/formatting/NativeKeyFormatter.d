/*******************************************************************************
 * Copyright (c) 2004, 2007 IBM Corporation and others.
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

module org.eclipse.jface.bindings.keys.formatting.NativeKeyFormatter;

import org.eclipse.jface.bindings.keys.formatting.AbstractKeyFormatter;


import org.eclipse.swt.SWT;
import org.eclipse.jface.bindings.keys.IKeyLookup;
import org.eclipse.jface.bindings.keys.KeyLookupFactory;
import org.eclipse.jface.bindings.keys.KeySequence;
import org.eclipse.jface.bindings.keys.KeyStroke;
import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.HashMap;
import java.util.ResourceBundle;

/**
 * <p>
 * Formats the key sequences and key strokes into the native human-readable
 * format. This is typically what you would see on the menus for the given
 * platform and locale.
 * </p>
 *
 * @since 3.1
 */
public final class NativeKeyFormatter : AbstractKeyFormatter {
    alias AbstractKeyFormatter.format format;

    /**
     * The key into the internationalization resource bundle for the delimiter
     * to use between keys (on the Carbon platform).
     */
    private const static String CARBON_KEY_DELIMITER_KEY = "CARBON_KEY_DELIMITER"; //$NON-NLS-1$

    /**
     * A look-up table for the string representations of various carbon keys.
     */
    private const static HashMap CARBON_KEY_LOOK_UP;

    /**
     * The resource bundle used by <code>format()</code> to translate formal
     * string representations by locale.
     */
    private const static ResourceBundle RESOURCE_BUNDLE;

    /**
     * The key into the internationalization resource bundle for the delimiter
     * to use between key strokes (on the Win32 platform).
     */
    private const static String WIN32_KEY_STROKE_DELIMITER_KEY = "WIN32_KEY_STROKE_DELIMITER"; //$NON-NLS-1$

    static this() {
        CARBON_KEY_LOOK_UP = new HashMap();
        RESOURCE_BUNDLE = ResourceBundle.getBundle(
            getImportData!("org.eclipse.jface.bindings.keys.formatting.NativeKeyFormatter.properties"));

        Object carbonBackspace = stringcast("\u232B"); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.BS_NAME), carbonBackspace);
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.BACKSPACE_NAME), carbonBackspace);
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.CR_NAME), stringcast("\u21A9")); //$NON-NLS-1$
        Object carbonDelete = stringcast("\u2326"); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.DEL_NAME), carbonDelete);
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.DELETE_NAME), carbonDelete);
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.SPACE_NAME), stringcast("\u2423")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.ALT_NAME), stringcast("\u2325")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.COMMAND_NAME), stringcast("\u2318")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.CTRL_NAME), stringcast("\u2303")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.SHIFT_NAME), stringcast("\u21E7")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.ARROW_DOWN_NAME), stringcast("\u2193")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.ARROW_LEFT_NAME), stringcast("\u2190")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.ARROW_RIGHT_NAME), stringcast("\u2192")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.ARROW_UP_NAME), stringcast("\u2191")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.END_NAME), stringcast("\u2198")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.NUMPAD_ENTER_NAME), stringcast("\u2324")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.HOME_NAME), stringcast("\u2196")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.PAGE_DOWN_NAME), stringcast("\u21DF")); //$NON-NLS-1$
        CARBON_KEY_LOOK_UP.put(stringcast(IKeyLookup.PAGE_UP_NAME), stringcast("\u21DE")); //$NON-NLS-1$
    }

    /**
     * Formats an individual key into a human readable format. This uses an
     * internationalization resource bundle to look up the key. This does the
     * platform-specific formatting for Carbon.
     *
     * @param key
     *            The key to format.
     * @return The key formatted as a string; should not be <code>null</code>.
     */
    public override final String format(int key) {
        IKeyLookup lookup = KeyLookupFactory.getDefault();
        String name = lookup.formalNameLookup(key);

        // TODO consider platform-specific resource bundles
        if ("carbon".equals(SWT.getPlatform())) { //$NON-NLS-1$
            String formattedName = stringcast( CARBON_KEY_LOOK_UP.get(name));
            if (formattedName !is null) {
                return formattedName;
            }
        }

        return super.format(key);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.AbstractKeyFormatter#getKeyDelimiter()
     */
    protected override String getKeyDelimiter() {
        // We must do the look up every time, as our locale might change.
        if ("carbon".equals(SWT.getPlatform())) { //$NON-NLS-1$
            return Util.translateString(RESOURCE_BUNDLE,
                    CARBON_KEY_DELIMITER_KEY, Util.ZERO_LENGTH_STRING);
        }

        return Util.translateString(RESOURCE_BUNDLE, KEY_DELIMITER_KEY,
                KeyStroke.KEY_DELIMITER);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.AbstractKeyFormatter#getKeyStrokeDelimiter()
     */
    protected override String getKeyStrokeDelimiter() {
        // We must do the look up every time, as our locale might change.
        if ("win32".equals(SWT.getPlatform())) { //$NON-NLS-1$
            return Util.translateString(RESOURCE_BUNDLE,
                    WIN32_KEY_STROKE_DELIMITER_KEY,
                    KeySequence.KEY_STROKE_DELIMITER);
        }

        return Util.translateString(RESOURCE_BUNDLE, KEY_STROKE_DELIMITER_KEY,
                KeySequence.KEY_STROKE_DELIMITER);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.AbstractKeyFormatter#sortModifierKeys(int)
     */
    protected override int[] sortModifierKeys(int modifierKeys) {
        IKeyLookup lookup = KeyLookupFactory.getDefault();
        String platform = SWT.getPlatform();
        int[] sortedKeys = new int[4];
        int index = 0;

        if ("win32".equals(platform) || "wpf".equals(platform)) { //$NON-NLS-1$ //$NON-NLS-2$
            if ((modifierKeys & lookup.getCtrl()) !is 0) {
                sortedKeys[index++] = lookup.getCtrl();
            }
            if ((modifierKeys & lookup.getAlt()) !is 0) {
                sortedKeys[index++] = lookup.getAlt();
            }
            if ((modifierKeys & lookup.getShift()) !is 0) {
                sortedKeys[index++] = lookup.getShift();
            }

        } else if ("gtk".equals(platform) || "motif".equals(platform)) { //$NON-NLS-1$ //$NON-NLS-2$
            if ((modifierKeys & lookup.getShift()) !is 0) {
                sortedKeys[index++] = lookup.getShift();
            }
            if ((modifierKeys & lookup.getCtrl()) !is 0) {
                sortedKeys[index++] = lookup.getCtrl();
            }
            if ((modifierKeys & lookup.getAlt()) !is 0) {
                sortedKeys[index++] = lookup.getAlt();
            }

        } else if ("carbon".equals(platform)) { //$NON-NLS-1$
            if ((modifierKeys & lookup.getShift()) !is 0) {
                sortedKeys[index++] = lookup.getShift();
            }
            if ((modifierKeys & lookup.getCtrl()) !is 0) {
                sortedKeys[index++] = lookup.getCtrl();
            }
            if ((modifierKeys & lookup.getAlt()) !is 0) {
                sortedKeys[index++] = lookup.getAlt();
            }
            if ((modifierKeys & lookup.getCommand()) !is 0) {
                sortedKeys[index++] = lookup.getCommand();
            }

        }

        return sortedKeys;
    }
}
