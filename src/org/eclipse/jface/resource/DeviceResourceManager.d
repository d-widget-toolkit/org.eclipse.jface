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
module org.eclipse.jface.resource.DeviceResourceManager;

import org.eclipse.jface.resource.AbstractResourceManager;
import org.eclipse.jface.resource.DeviceResourceDescriptor;
import org.eclipse.jface.resource.ImageDescriptor;

import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.Image;

import java.lang.all;

/**
 * Manages SWT resources for a particular device.
 *
 * <p>
 * IMPORTANT: in most cases clients should use a <code>LocalResourceManager</code> instead of a
 * <code>DeviceResourceManager</code>. To create a resource manager on a particular display,
 * use <code>new LocalResourceManager(JFaceResources.getResources(myDisplay))</code>.
 * <code>DeviceResourceManager</code> should only be used directly when managing
 * resources for a device other than a Display (such as a printer).
 * </p>
 *
 * @see LocalResourceManager
 *
 * @since 3.1
 */
public final class DeviceResourceManager : AbstractResourceManager {

    private Device device;
    private Image missingImage;

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ResourceManager#getDevice()
     */
    public override Device getDevice() {
        return device;
    }

    /**
     * Creates a new registry for the given device.
     *
     * @param device device to manage
     */
    public this(Device device) {
        this.device = device;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.AbstractResourceManager#allocate(org.eclipse.jface.resource.DeviceResourceDescriptor)
     */
    protected override Object allocate(DeviceResourceDescriptor descriptor){
        return descriptor.createResource(device);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.AbstractResourceManager#deallocate(java.lang.Object, org.eclipse.jface.resource.DeviceResourceDescriptor)
     */
    protected override void deallocate(Object resource, DeviceResourceDescriptor descriptor) {
        descriptor.destroyResource(resource);
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ResourceManager#getDefaultImage()
     */
    protected override Image getDefaultImage() {
        if (missingImage is null) {
            missingImage = ImageDescriptor.getMissingImageDescriptor().createImage();
        }
        return missingImage;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.AbstractResourceManager#dispose()
     */
    public override void dispose() {
        super.dispose();
        if (missingImage !is null) {
            missingImage.dispose();
            missingImage = null;
        }
    }
}
