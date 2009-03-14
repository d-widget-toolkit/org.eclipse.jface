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
module org.eclipse.jface.resource.AbstractResourceManager;

import org.eclipse.jface.resource.ResourceManager;
import org.eclipse.jface.resource.DeviceResourceDescriptor;


import java.lang.all;
import java.util.Collection;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;

/**
 * Abstract implementation of ResourceManager. Maintains reference counts for all previously
 * allocated SWT resources. Delegates to the abstract method allocate(...) the first time a resource
 * is referenced and delegates to the abstract method deallocate(...) the last time a reference is
 * removed.
 *
 * @since 3.1
 */
abstract class AbstractResourceManager : ResourceManager {

    /**
     * Map of ResourceDescriptor onto RefCount. (null when empty)
     */
    private HashMap map = null;

    /**
     * Holds a reference count for a previously-allocated resource
     */
    private static class RefCount {
        Object resource;
        int count = 1;

        this(Object resource) {
            this.resource = resource;
        }
    }

    /**
     * Called the first time a resource is requested. Should allocate and return a resource
     * of the correct type.
     *
     * @since 3.1
     *
     * @param descriptor identifier for the resource to allocate
     * @return the newly allocated resource
     * @throws DeviceResourceException Thrown when allocation of an SWT device resource fails
     */
    protected abstract Object allocate(DeviceResourceDescriptor descriptor);

    /**
     * Called the last time a resource is dereferenced. Should release any resources reserved by
     * allocate(...).
     *
     * @since 3.1
     *
     * @param resource resource being deallocated
     * @param descriptor identifier for the resource
     */
    protected abstract void deallocate(Object resource, DeviceResourceDescriptor descriptor);

    /* (non-Javadoc)
     * @see ResourceManager#create(DeviceResourceDescriptor)
     */
    public override final Object create(DeviceResourceDescriptor descriptor){

        // Lazily allocate the map
        if (map is null) {
            map = new HashMap();
        }

        // Get the current reference count
        RefCount count = cast(RefCount)map.get(descriptor);
        if (count !is null) {
            // If this resource already exists, increment the reference count and return
            // the existing resource.
            count.count++;
            return count.resource;
        }

        // Allocate and return a new resource (with ref count = 1)
        Object resource = allocate(descriptor);

        count = new RefCount(resource);
        map.put(descriptor, count);

        return resource;
    }

    /* (non-Javadoc)
     * @see ResourceManager#destroy(DeviceResourceDescriptor)
     */
    public override final void destroy(DeviceResourceDescriptor descriptor) {
        // If the map is empty (null) then there are no resources to dispose
        if (map is null) {
            return;
        }

        // Find the existing resource
        RefCount count = cast(RefCount)map.get(descriptor);
        if (count !is null) {
            // If the resource exists, decrement the reference count.
            count.count--;
            if (count.count is 0) {
                // If this was the last reference, deallocate it.
                deallocate(count.resource, descriptor);
                map.remove(descriptor);
            }
        }

        // Null out the map when empty to save a small amount of memory
        if (map.isEmpty()) {
            map = null;
        }
    }

    /**
     * Deallocates any resources allocated by this registry that have not yet been
     * deallocated.
     *
     * @since 3.1
     */
    public override void dispose() {
        super.dispose();

        if (map is null) {
            return;
        }

        Collection entries = map.entrySet();

        for (Iterator iter = entries.iterator(); iter.hasNext();) {
            Map.Entry next = cast(Map.Entry) iter.next();

            Object key = next.getKey();
            RefCount val = cast(RefCount)next.getValue();

            deallocate(val.resource, cast(DeviceResourceDescriptor)key);
        }

        map = null;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.resource.ResourceManager#find(org.eclipse.jface.resource.DeviceResourceDescriptor)
     */
    public override Object find(DeviceResourceDescriptor descriptor) {
        if (map is null) {
            return null;
        }
        RefCount refCount = cast(RefCount)map.get(descriptor);
        if (refCount is null)
            return null;
        return refCount.resource;
    }
}
