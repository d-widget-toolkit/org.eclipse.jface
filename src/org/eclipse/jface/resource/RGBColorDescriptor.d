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
module org.eclipse.jface.resource.RGBColorDescriptor;

import org.eclipse.jface.resource.ColorDescriptor;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.RGB;

import java.lang.all;

/**
 * Describes a color by its RGB values.
 *
 * @since 3.1
 */
class RGBColorDescriptor : ColorDescriptor {

    private RGB color;

    /**
     * Color being copied, or null if none
     */
    private Color originalColor = null;

    /**
     * Creates a new RGBColorDescriptor given some RGB values
     *
     * @param color RGB values (not null)
     */
    public this(RGB color) {
        this.color = color;
    }

    /**
     * Creates a new RGBColorDescriptor that describes an existing color.
     *
     * @since 3.1
     *
     * @param originalColor a color to describe
     */
    public this(Color originalColor) {
        this(originalColor.getRGB());
        this.originalColor = originalColor;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#equals(java.lang.Object)
     */
    public override int opEquals(Object obj) {
        if ( auto other = cast(RGBColorDescriptor)obj ) {
            return other.color.opEquals(color) && other.originalColor is originalColor;
        }

        return false;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#hashCode()
     */
    public override hash_t toHash() {
        return color.toHash();
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resources.ColorDescriptor#createColor()
     */
    public override Color createColor(Device device) {
        // If this descriptor is wrapping an existing color, then we can return the original color
        // if this is the same device.
        if (originalColor !is null) {
            // If we're allocating on the same device as the original color, return the original.
            if (originalColor.getDevice() is device) {
                return originalColor;
            }
        }

        return new Color(device, color);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ColorDescriptor#destroyColor(org.eclipse.swt.graphics.Color)
     */
    public override void destroyColor(Color toDestroy) {
        if (toDestroy is originalColor) {
            return;
        }

        toDestroy.dispose();
    }
}
