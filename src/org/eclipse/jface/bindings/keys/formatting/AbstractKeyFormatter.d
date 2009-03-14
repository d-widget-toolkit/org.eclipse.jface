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

module org.eclipse.jface.bindings.keys.formatting.AbstractKeyFormatter;

import org.eclipse.jface.bindings.keys.formatting.IKeyFormatter;


import org.eclipse.jface.bindings.keys.IKeyLookup;
import org.eclipse.jface.bindings.keys.KeyLookupFactory;
import org.eclipse.jface.bindings.keys.KeySequence;
import org.eclipse.jface.bindings.keys.KeyStroke;
import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.Set;
import java.util.HashSet;
import java.util.ResourceBundle;

/**
 * <p>
 * An abstract implementation of a key formatter that provides a lot of common
 * key formatting functionality. It is recommended that implementations of
 * <code>IKeyFormatter</code> subclass from here, rather than implementing
 * <code>IKeyFormatter</code> directly.
 * </p>
 *
 * @since 3.1
 */
public abstract class AbstractKeyFormatter : IKeyFormatter {

    /**
     * The key for the delimiter between keys. This is used in the
     * internationalization bundles.
     */
    protected static const String KEY_DELIMITER_KEY = "KEY_DELIMITER"; //$NON-NLS-1$

    /**
     * The key for the delimiter between key strokes. This is used in the
     * internationalization bundles.
     */
    protected static const String KEY_STROKE_DELIMITER_KEY = "KEY_STROKE_DELIMITER"; //$NON-NLS-1$

    /**
     * An empty integer array that can be used in
     * <code>sortModifierKeys(int)</code>.
     */
    protected static const int[] NO_MODIFIER_KEYS = null;

    /**
     * The bundle in which to look up the internationalized text for all of the
     * individual keys in the system. This is the platform-agnostic version of
     * the internationalized strings. Some platforms (namely Carbon) provide
     * special Unicode characters and glyphs for some keys.
     */
    private static const ResourceBundle RESOURCE_BUNDLE;

    /**
     * The keys in the resource bundle. This is used to avoid missing resource
     * exceptions when they aren't necessary.
     */
    private static const Set resourceBundleKeys;

    static this() {
        RESOURCE_BUNDLE = ResourceBundle.getBundle(
            getImportData!("org.eclipse.jface.bindings.keys.formatting.AbstractKeyFormatter.properties"));
        resourceBundleKeys = new HashSet();
        foreach( element; RESOURCE_BUNDLE.getKeys()){
            resourceBundleKeys.add(stringcast(element));
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keysKeyFormatter#format(org.eclipse.jface.bindings.keys.KeySequence)
     */
    public String format(int key) {
        IKeyLookup lookup = KeyLookupFactory.getDefault();
        String name = lookup.formalNameLookup(key);

        if (resourceBundleKeys.contains(name)) {
            return Util.translateString(RESOURCE_BUNDLE, name, name);
        }

        return name;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.KeyFormatter#format(org.eclipse.jface.bindings.keys.KeySequence)
     */
    public String format(KeySequence keySequence) {
        StringBuffer stringBuffer = new StringBuffer();

        KeyStroke[] keyStrokes = keySequence.getKeyStrokes();
        int keyStrokesLength = keyStrokes.length;
        for (int i = 0; i < keyStrokesLength; i++) {
            stringBuffer.append(format(keyStrokes[i]));

            if (i + 1 < keyStrokesLength) {
                stringBuffer.append(getKeyStrokeDelimiter());
            }
        }

        return stringBuffer.toString();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.bindings.keys.KeyFormatter#formatKeyStroke(org.eclipse.jface.bindings.keys.KeyStroke)
     */
    public String format(KeyStroke keyStroke) {
        String keyDelimiter = getKeyDelimiter();

        // Format the modifier keys, in sorted order.
        int modifierKeys = keyStroke.getModifierKeys();
        int[] sortedModifierKeys = sortModifierKeys(modifierKeys);
        StringBuffer stringBuffer = new StringBuffer();
        if (sortedModifierKeys !is null) {
            for (int i = 0; i < sortedModifierKeys.length; i++) {
                int modifierKey = sortedModifierKeys[i];
                if (modifierKey !is KeyStroke.NO_KEY) {
                    stringBuffer.append(format(modifierKey));
                    stringBuffer.append(keyDelimiter);
                }
            }
        }

        // Format the natural key, if any.
        int naturalKey = keyStroke.getNaturalKey();
        if (naturalKey !is 0) {
            stringBuffer.append(format(naturalKey));
        }

        return stringBuffer.toString();

    }

    /**
     * An accessor for the delimiter you wish to use between keys. This is used
     * by the default format implementations to determine the key delimiter.
     *
     * @return The delimiter to use between keys; should not be
     *         <code>null</code>.
     */
    protected abstract String getKeyDelimiter();

    /**
     * An accessor for the delimiter you wish to use between key strokes. This
     * used by the default format implementations to determine the key stroke
     * delimiter.
     *
     * @return The delimiter to use between key strokes; should not be
     *         <code>null</code>.
     */
    protected abstract String getKeyStrokeDelimiter();

    /**
     * Separates the modifier keys from each other, and then places them in an
     * array in some sorted order. The sort order is dependent on the type of
     * formatter.
     *
     * @param modifierKeys
     *            The modifier keys from the key stroke.
     * @return An array of modifier key values -- separated and sorted in some
     *         order. Any values in this array that are
     *         <code>KeyStroke.NO_KEY</code> should be ignored.
     */
    protected abstract int[] sortModifierKeys(int modifierKeys);
}
