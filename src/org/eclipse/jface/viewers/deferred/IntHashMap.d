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
module org.eclipse.jface.viewers.deferred.IntHashMap;

import java.lang.all;
import java.util.HashMap;


/**
 * Represents a map of objects onto ints. This is intended for future optimization:
 * using int primitives would allow for an implementation that doesn't require
 * additional object allocations for Integers. However, the current implementation
 * simply delegates to the Java HashMap class.
 *
 * @since 3.1
 */
/* package */ class IntHashMap {
    private int[Object] map;

    /**
     * @param size
     * @param loadFactor
     */
    public this(int size, float loadFactor) {
//         map = new HashMap(size,loadFactor);
    }

    /**
     *
     */
    public this() {
//         map = new HashMap();
    }

    /**
     * @param key
     */
    public void remove(Object key) {
        map.remove(key);
    }

    /**
     * @param key
     * @param value
     */
    public void put(Object key, int value) {
        map[key] = value;
    }

    /**
     * @param key
     * @return the int value at the given key
     */
    public int get(Object key) {
        return get(key, 0);
    }

    /**
     * @param key
     * @param defaultValue
     * @return the int value at the given key, or the default value if this map does not contain the given key
     */
    public int get(Object key, int defaultValue) {
        if( auto res = key in map ){
            return *res;
        }
        return defaultValue;
    }

    /**
     * @param key
     * @return <code>true</code> if this map contains the given key, <code>false</code> otherwise
     */
    public bool containsKey(Object key) {
        if( auto res = key in map ){
            return true;
        }
        return false;
    }

    /**
     * @return the number of key/value pairs
     */
    public int size() {
        return map.length;
    }
}
