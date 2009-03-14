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
module org.eclipse.jface.resource.DerivedImageDescriptor;

import org.eclipse.jface.resource.ImageDescriptor;
import org.eclipse.jface.resource.DeviceResourceException;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.swt.widgets.Display;

import java.lang.all;

/**
 * An image descriptor which creates images based on another ImageDescriptor, but with
 * additional SWT flags. Note that this is only intended for compatibility.
 *
 * @since 3.1
 */
final class DerivedImageDescriptor : ImageDescriptor {
    alias ImageDescriptor.createImage createImage;

    private ImageDescriptor original;
    private int flags;

    /**
     * Create a new image descriptor
     * @param original the original one
     * @param swtFlags flags to be used when image is created {@link Image#Image(Device, Image, int)}
     * @see SWT#IMAGE_COPY
     * @see SWT#IMAGE_DISABLE
     * @see SWT#IMAGE_GRAY
     */
    public this(ImageDescriptor original, int swtFlags) {
        this.original = original;
        flags = swtFlags;
    }

    public override Object createResource(Device device) {
        try {
            return internalCreateImage(device);
        } catch (SWTException e) {
            throw new DeviceResourceException(this, e);
        }
    }

    public override Image createImage(Device device) {
        return internalCreateImage(device);
    }

    public override hash_t toHash() {
        return original.toHash() + flags;
    }

    public override int opEquals(Object arg0) {
        if ( auto desc = cast(DerivedImageDescriptor)arg0 ) {
            return desc.original is original && flags is desc.flags;
        }

        return false;
    }

    /**
     * Creates a new Image on the given device. Note that we defined a new
     * method rather than overloading createImage since this needs to be
     * called by getImageData(), and we want to be absolutely certain not
     * to cause infinite recursion if the base class gets refactored.
     *
     * @param device device to create the image on
     * @return a newly allocated Image. Must be disposed by calling image.dispose().
     */
    private final Image internalCreateImage(Device device) {
        Image originalImage = original.createImage(device);
        Image result = new Image(device, originalImage, flags);
        original.destroyResource(originalImage);
        return result;
    }

    public override ImageData getImageData() {
        Image image = internalCreateImage(Display.getCurrent());
        ImageData result = image.getImageData();
        image.dispose();
        return result;
    }

}
