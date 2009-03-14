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
module org.eclipse.jface.resource.ImageDataImageDescriptor;

import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;

import org.eclipse.jface.resource.ImageDescriptor;

import java.lang.all;

/**
 * @since 3.1
 */
class ImageDataImageDescriptor : ImageDescriptor {

    private ImageData data;

    /**
     * Original image being described, or null if this image is described
     * completely using its ImageData
     */
    private Image originalImage = null;

    /**
     * Creates an image descriptor, given an image and the device it was created on.
     *
     * @param originalImage
     */
    this(Image originalImage) {
        this(originalImage.getImageData());
        this.originalImage = originalImage;
    }

    /**
     * Creates an image descriptor, given some image data.
     *
     * @param data describing the image
     */

    this(ImageData data) {
        this.data = data;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.DeviceResourceDescriptor#create(org.eclipse.swt.graphics.Device)
     */
    public override Object createResource(Device device) {

        // If this descriptor is an existing font, then we can return the original font
        // if this is the same device.
        if (originalImage !is null) {
            // If we're allocating on the same device as the original font, return the original.
            if (originalImage.getDevice() is device) {
                return originalImage;
            }
        }

        return super.createResource(device);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.DeviceResourceDescriptor#destroy(java.lang.Object)
     */
    public override void destroyResource(Object previouslyCreatedObject) {
        if (previouslyCreatedObject is originalImage) {
            return;
        }

        super.destroyResource(previouslyCreatedObject);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ImageDescriptor#getImageData()
     */
    public override ImageData getImageData() {
        return data;
    }

    /* (non-Javadoc)
     * @see Object#hashCode
     */
    public override hash_t toHash() {
         if (originalImage !is null) {
             return System.identityHashCode(originalImage);
         }
         return data.toHash();
    }

    /* (non-Javadoc)
     * @see Object#equals
     */
    public override int opEquals(Object obj) {
        if (!(cast(ImageDataImageDescriptor)obj )) {
            return false;
        }

        ImageDataImageDescriptor imgWrap = cast(ImageDataImageDescriptor) obj;

        //Intentionally using is instead of equals() as Image.hashCode() changes
        //when the image is disposed and so leaks may occur with equals()

        if (originalImage !is null) {
            return imgWrap.originalImage is originalImage;
        }

        return (imgWrap.originalImage is null && data.opEquals(imgWrap.data));
    }

}
