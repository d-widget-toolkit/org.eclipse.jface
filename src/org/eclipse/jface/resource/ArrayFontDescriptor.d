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
module org.eclipse.jface.resource.ArrayFontDescriptor;

import java.lang.all;

import org.eclipse.jface.resource.FontDescriptor;

import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontData;

/**
 * Describes a Font using an array of FontData
 *
 * @since 3.1
 */
final class ArrayFontDescriptor : FontDescriptor {

    private FontData[] data;
    private Font originalFont = null;

    /**
     * Creates a font descriptor for a font with the given name, height,
     * and style. These arguments are passed directly to the constructor
     * of Font.
     *
     * @param data FontData describing the font to create
     *
     * @see org.eclipse.swt.graphics.Font#Font(org.eclipse.swt.graphics.Device, org.eclipse.swt.graphics.FontData)
     * @since 3.1
     */
    public this(FontData[] data) {
        this.data = data;
    }

    /**
     * Creates a font descriptor that describes the given font.
     *
     * @param originalFont font to be described
     *
     * @see FontDescriptor#createFrom(org.eclipse.swt.graphics.Font)
     * @since 3.1
     */
    public this(Font originalFont) {
        this(originalFont.getFontData());
        this.originalFont = originalFont;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.FontDescriptor#getFontData()
     */
    public override FontData[] getFontData() {
        // Copy the original array to ensure that callers will not modify it
        return copy(data);
    }


    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.FontDescriptor#createFont(org.eclipse.swt.graphics.Device)
     */
    public override Font createFont(Device device) {

        // If this descriptor is an existing font, then we can return the original font
        // if this is the same device.
        if (originalFont !is null) {
            // If we're allocating on the same device as the original font, return the original.
            if (originalFont.getDevice() is device) {
                return originalFont;
            }
        }

        return new Font(device, data);
    }

    /* (non-Javadoc)
     * @see java.lang.Object#equals(java.lang.Object)
     */
    public override int opEquals(Object obj) {
        if ((obj.classinfo is ArrayFontDescriptor.classinfo)) {
            ArrayFontDescriptor descr = cast(ArrayFontDescriptor)obj;

            if (descr.originalFont !is originalFont) {
                return false;
            }

            if (originalFont !is null) {
                return true;
            }

            if (data.length !is descr.data.length) {
                return false;
            }

            for (int i = 0; i < data.length; i++) {
                FontData fd = data[i];
                FontData fd2 = descr.data[i];

                if (!fd.opEquals(fd2)) {
                    return false;
                }
            }

            return true;
        }

        return false;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#hashCode()
     */
    public override hash_t toHash() {
        if (originalFont !is null) {
            return originalFont.toHash();
        }

        int code = 0;

        for (int i = 0; i < data.length; i++) {
            FontData fd = data[i];
            code += fd.toHash();
        }
        return code;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.FontDescriptor#destroyFont(org.eclipse.swt.graphics.Font)
     */
    public override void destroyFont(Font previouslyCreatedFont) {
        if (previouslyCreatedFont is originalFont) {
            return;
        }
        previouslyCreatedFont.dispose();
    }

}
