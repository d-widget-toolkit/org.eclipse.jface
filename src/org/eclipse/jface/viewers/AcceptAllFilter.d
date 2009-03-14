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
module org.eclipse.jface.viewers.AcceptAllFilter;

import org.eclipse.jface.viewers.IFilter;

import java.lang.all;


/**
 * Filter that accepts everything. Available as a singleton since having
 * more than one instance would be wasteful.
 *
 * @since 3.1
 */
public final class AcceptAllFilter : IFilter {

    /**
     * Returns the singleton instance of AcceptAllFilter
     *
     * @return the singleton instance of AcceptAllFilter
     */
    public static IFilter getInstance() {
        if( singleton is null ){
            synchronized{
                if( singleton is null ){
                    singleton = new AcceptAllFilter();
                }
            }
        }
        return singleton;
    }

    /**
     * The singleton instance
     */
    private static IFilter singleton = null;

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.deferred.IFilter#select(java.lang.Object)
     */
    public bool select(Object toTest) {
        return true;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#equals(java.lang.Object)
     */
    public override int opEquals(Object other) {
        return other is this || null !is cast(AcceptAllFilter)other ;
    }

}
