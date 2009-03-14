/*******************************************************************************
 * Copyright (c) 2006, 2008 IBM Corporation and others.
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
module org.eclipse.jface.viewers.DecorationContext;

import org.eclipse.jface.viewers.IDecorationContext;


import java.lang.all;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;

/**
 * A concrete implementation of the {@link IDecorationContext} interface,
 * suitable for instantiating.
 * <p>
 * This class is not intended to be subclassed.
 * </p>
 * @since 3.2
 */
public class DecorationContext : IDecorationContext {

    /**
     * Constant that defines a default decoration context that has
     * no context ids associated with it.
     */
    public static const IDecorationContext DEFAULT_CONTEXT;
    static this(){
        DEFAULT_CONTEXT = new DecorationContext();
    }

    private Map properties;

    /**
     * Create a decoration context.
     */
    public this() {
        properties = new HashMap();
    }


    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.IDecorationContext#getProperty(java.lang.String)
     */
    public Object getProperty(String property) {
        return properties.get(stringcast(property));
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.IDecorationContext#getProperties()
     */
    public String[] getProperties() {
        return stringcast( properties.keySet().toArray() );
    }

    /**
     * Set the given property to the given value. Setting the value of
     * a property to <code>null</code> removes the property from
     * the context.
     * @param property the property
     * @param value the value of the property or <code>null</code>
     * if the property is to be removed.
     */
    public void putProperty(String property, Object value) {
        if (value is null) {
            properties.remove(stringcast(property));
        } else {
            properties.put(stringcast(property), value);
        }
    }
}
