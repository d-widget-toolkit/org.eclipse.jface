/*******************************************************************************
 * Copyright (c) 2003, 2008 IBM Corporation and others.
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
module org.eclipse.jface.resource.ColorRegistry;

import org.eclipse.jface.resource.ColorDescriptor;
import org.eclipse.jface.resource.ResourceRegistry;
import org.eclipse.jface.resource.RGBColorDescriptor;


import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.RGB;
import org.eclipse.swt.widgets.Display;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Collections;
import java.util.Collection;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;

/**
 * A color registry maintains a mapping between symbolic color names and SWT
 * <code>Color</code>s.
 * <p>
 * A color registry owns all of the <code>Color</code> objects registered with
 * it, and automatically disposes of them when the SWT Display that creates the
 * <code>Color</code>s is disposed. Because of this, clients do not need to
 * (indeed, must not attempt to) dispose of <code>Color</code> objects
 * themselves.
 * </p>
 * <p>
 * Methods are provided for registering listeners that will be kept
 * apprised of changes to list of registed colors.
 * </p>
 * <p>
 * Clients may instantiate this class (it was not designed to be subclassed).
 * </p>
 *
 * @since 3.0
 * @noextend This class is not intended to be subclassed by clients.
 */
public class ColorRegistry : ResourceRegistry {

    /**
     * Default color value.  This is cyan (very unappetizing).
     * @since 3.4
     */
    private static ColorDescriptor DEFAULT_COLOR;
    private static void init_DEFAULT_COLOR () {
        if( DEFAULT_COLOR is null ){
            synchronized( ColorRegistry.classinfo ){
                if( DEFAULT_COLOR is null ){
                    DEFAULT_COLOR = new RGBColorDescriptor(new RGB(0, 255, 255));
                }
            }
        }
    }

    /**
     * This registries <code>Display</code>. All colors will be allocated using
     * it.
     */
    protected Display display;

    /**
     * Collection of <code>Color</code> that are now stale to be disposed when
     * it is safe to do so (i.e. on shutdown).
     */
    private List staleColors;

    /**
     * Table of known colors, keyed by symbolic color name (key type: <code>String</code>,
     * value type: <code>org.eclipse.swt.graphics.Color</code>.
     */
    private Map stringToColor;

    /**
     * Table of known color data, keyed by symbolic color name (key type:
     * <code>String</code>, value type: <code>org.eclipse.swt.graphics.RGB</code>).
     */
    private Map stringToRGB;

    /**
     * Runnable that cleans up the manager on disposal of the display.
     */
    protected Runnable displayRunnable;
    private void init_displayRunnable(){
        displayRunnable = new class Runnable {
            public void run() {
                clearCaches();
            }
        };
    }

    private final bool cleanOnDisplayDisposal;

    /**
     * Create a new instance of the receiver that is hooked to the current
     * display.
     *
     * @see org.eclipse.swt.widgets.Display#getCurrent()
     */
    public this() {
        this(Display.getCurrent(), true);
    }

    /**
     * Create a new instance of the receiver.
     *
     * @param display the <code>Display</code> to hook into.
     */
    public this(Display display) {
        this (display, true);
    }

    /**
     * Create a new instance of the receiver.
     *
     * @param display the <code>Display</code> to hook into
     * @param cleanOnDisplayDisposal
     *            whether all fonts allocated by this <code>ColorRegistry</code>
     *            should be disposed when the display is disposed
     * @since 3.1
     */
    public this(Display display, bool cleanOnDisplayDisposal) {
        init_DEFAULT_COLOR();
        staleColors = new ArrayList();
        stringToColor = new HashMap();
        stringToRGB = new HashMap();
        init_displayRunnable();
        Assert.isNotNull(display);
        this.display = display;
        this.cleanOnDisplayDisposal = cleanOnDisplayDisposal;
        if (cleanOnDisplayDisposal) {
            hookDisplayDispose();
        }
    }

    /**
     * Create a new <code>Color</code> on the receivers <code>Display</code>.
     *
     * @param rgb the <code>RGB</code> data for the color.
     * @return the new <code>Color</code> object.
     *
     * @since 3.1
     */
    private Color createColor(RGB rgb) {
        if (this.display is null) {
            Display display = Display.getCurrent();
            if (display is null) {
                throw new IllegalStateException();
            }
            this.display = display;
            if (cleanOnDisplayDisposal) {
                hookDisplayDispose();
            }
        }
        return new Color(display, rgb);
    }

    /**
     * Dispose of all of the <code>Color</code>s in this iterator.
     *
     * @param iterator over <code>Collection</code> of <code>Color</code>
     */
    private void disposeColors(Iterator iterator) {
        while (iterator.hasNext()) {
            Object next = iterator.next();
            (cast(Color) next).dispose();
        }
    }

    /**
     * Returns the <code>color</code> associated with the given symbolic color
     * name, or <code>null</code> if no such definition exists.
     *
     * @param symbolicName symbolic color name
     * @return the <code>Color</code> or <code>null</code>
     */
    public Color get(String symbolicName) {

        Assert.isNotNull(symbolicName);
        Object result = stringToColor.get(stringcast(symbolicName));
        if (result !is null) {
            return cast(Color) result;
        }

        Color color = null;

        result = stringToRGB.get(stringcast(symbolicName));
        if (result is null) {
            return null;
        }

        color = createColor( cast(RGB) result);

        stringToColor.put(stringcast(symbolicName), color);

        return color;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ResourceRegistry#getKeySet()
     */
    public override Set getKeySet() {
        return Collections.unmodifiableSet(stringToRGB.keySet());
    }

    /**
     * Returns the color data associated with the given symbolic color name.
     *
     * @param symbolicName symbolic color name.
     * @return the <code>RGB</code> data, or <code>null</code> if the symbolic name
     * is not valid.
     */
    public RGB getRGB(String symbolicName) {
        Assert.isNotNull(symbolicName);
        return cast(RGB) stringToRGB.get(symbolicName);
    }

    /**
     * Returns the color descriptor associated with the given symbolic color
     * name. As of 3.4 if this color is not defined then an unspecified color
     * is returned. Users that wish to ensure a reasonable default value should
     * use {@link #getColorDescriptor(String, ColorDescriptor)} instead.
     *
     * @since 3.1
     *
     * @param symbolicName
     * @return the color descriptor associated with the given symbolic color
     *         name or an unspecified sentinel.
     */
    public ColorDescriptor getColorDescriptor(String symbolicName) {
        return getColorDescriptor(symbolicName, DEFAULT_COLOR);
    }

    /**
     * Returns the color descriptor associated with the given symbolic color
     * name. If this name does not exist within the registry the supplied
     * default value will be used.
     *
     * @param symbolicName
     * @param defaultValue
     * @return the color descriptor associated with the given symbolic color
     *         name or the default
     * @since 3.4
     */
    public ColorDescriptor getColorDescriptor(String symbolicName,
            ColorDescriptor defaultValue) {
        RGB rgb = getRGB(symbolicName);
        if (rgb is null)
            return defaultValue;
        return ColorDescriptor.createFrom(rgb);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.resource.ResourceRegistry#clearCaches()
     */
    protected override void clearCaches() {
        disposeColors(stringToColor.values().iterator());
        disposeColors(staleColors.iterator());
        stringToColor.clear();
        staleColors.clear();
        display = null;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ResourceRegistry#hasValueFor(java.lang.String)
     */
    public override bool hasValueFor(String colorKey) {
        return stringToRGB.containsKey(colorKey);
    }

    /**
     * Hook a dispose listener on the SWT display.
     */
    private void hookDisplayDispose() {
        display.disposeExec(displayRunnable);
    }

    /**
     * Adds (or replaces) a color to this color registry under the given
     * symbolic name.
     * <p>
     * A property change event is reported whenever the mapping from a symbolic
     * name to a color changes. The source of the event is this registry; the
     * property name is the symbolic color name.
     * </p>
     *
     * @param symbolicName the symbolic color name
     * @param colorData an <code>RGB</code> object
     */
    public void put(String symbolicName, RGB colorData) {
        put(symbolicName, colorData, true);
    }

    /**
     * Adds (or replaces) a color to this color registry under the given
     * symbolic name.
     * <p>
     * A property change event is reported whenever the mapping from a symbolic
     * name to a color changes. The source of the event is this registry; the
     * property name is the symbolic color name.
     * </p>
     *
     * @param symbolicName the symbolic color name
     * @param colorData an <code>RGB</code> object
     * @param update - fire a color mapping changed if true. False if this
     *            method is called from the get method as no setting has
     *            changed.
     */
    private void put(String symbolicName, RGB colorData, bool update) {

        Assert.isNotNull(symbolicName);
        Assert.isNotNull(colorData);

        RGB existing = cast(RGB)stringToRGB.get(symbolicName);
        if (colorData.opEquals(existing)) {
            return;
        }

        Color oldColor = cast(Color) stringToColor.remove(symbolicName);
        stringToRGB.put(stringcast(symbolicName), colorData);
        if (update) {
            fireMappingChanged(symbolicName, existing, colorData);
        }

        if (oldColor !is null) {
            staleColors.add(oldColor);
        }
    }
}
