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

module org.eclipse.jface.bindings.keys.formatting.EmacsKeyFormatter;

import org.eclipse.jface.bindings.keys.formatting.AbstractKeyFormatter;

import org.eclipse.jface.bindings.keys.IKeyLookup;
import org.eclipse.jface.bindings.keys.KeyLookupFactory;
import org.eclipse.jface.bindings.keys.KeySequence;
import org.eclipse.jface.bindings.keys.KeyStroke;
import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.ResourceBundle;

/**
 * <p>
 * A key formatter providing the Emacs-style accelerators using single letters
 * to represent the modifier keys.
 * </p>
 *
 * @since 3.1
 */
public final class EmacsKeyFormatter : AbstractKeyFormatter {
    alias AbstractKeyFormatter.format format;

    /**
     * The resource bundle used by <code>format()</code> to translate formal
     * string representations by locale.
     */
    private const static ResourceBundle RESOURCE_BUNDLE;

    static this(){
        RESOURCE_BUNDLE = ResourceBundle.getBundle(
            getImportData!("org.eclipse.jface.bindings.keys.formatting.EmacsKeyFormatter.properties"));
    }
    /**
     * Formats an individual key into a human readable format. This converts the
     * key into a format similar to Xemacs.
     *
     * @param key
     *            The key to format; must not be <code>null</code>.
     * @return The key formatted as a string; should not be <code>null</code>.
     */
    public override String format(int key) {
        IKeyLookup lookup = KeyLookupFactory.getDefault();
        if (lookup.isModifierKey(key)) {
            String formattedName = Util.translateString(RESOURCE_BUNDLE, lookup
                    .formalNameLookup(key), null);
            if (formattedName !is null) {
                return formattedName;
            }
        }

        return super.format(key).toLowerCase();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.AbstractKeyFormatter#getKeyDelimiter()
     */
    protected override String getKeyDelimiter() {
        return Util.translateString(RESOURCE_BUNDLE, KEY_DELIMITER_KEY,
                KeyStroke.KEY_DELIMITER);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.AbstractKeyFormatter#getKeyStrokeDelimiter()
     */
    protected override String getKeyStrokeDelimiter() {
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
        int[] sortedKeys = new int[4];
        int index = 0;

        if ((modifierKeys & lookup.getAlt()) !is 0) {
            sortedKeys[index++] = lookup.getAlt();
        }
        if ((modifierKeys & lookup.getCommand()) !is 0) {
            sortedKeys[index++] = lookup.getCommand();
        }
        if ((modifierKeys & lookup.getCtrl()) !is 0) {
            sortedKeys[index++] = lookup.getCtrl();
        }
        if ((modifierKeys & lookup.getShift()) !is 0) {
            sortedKeys[index++] = lookup.getShift();
        }

        return sortedKeys;
    }
}
