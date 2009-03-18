/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Peter Shipton - original hashtable implementation
 *     Nick Edgar - added element comparer support
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.CustomHashtable;

import org.eclipse.jface.viewers.IElementComparer;
// import java.util.Enumeration;
// import java.util.NoSuchElementException;

import java.lang.all;
import java.util.Enumeration;

/**
 * CustomHashtable associates keys with values. Keys and values cannot be null.
 * The size of the Hashtable is the number of key/value pairs it contains.
 * The capacity is the number of key/value pairs the Hashtable can hold.
 * The load factor is a float value which determines how full the Hashtable
 * gets before expanding the capacity. If the load factor of the Hashtable
 * is exceeded, the capacity is doubled.
 * <p>
 * CustomHashtable allows a custom comparator and hash code provider.
 */
/* package */final class CustomHashtable {
    alias Object.toHash toHash;

    /**
     * HashMapEntry is an internal class which is used to hold the entries of a Hashtable.
     */
    private static class HashMapEntry {
        Object key, value;

        HashMapEntry next;

        this(Object theKey, Object theValue) {
            key = theKey;
            value = theValue;
        }
    }

    private static final class EmptyEnumerator : Enumeration {
        public bool hasMoreElements() {
            return false;
        }

        public Object nextElement() {
            throw new NoSuchElementException(null);
        }
    }

    private class HashEnumerator : Enumeration {
        bool key;

        int start;

        HashMapEntry entry;

        this(bool isKey) {
            key = isKey;
            start = firstSlot;
        }

        public bool hasMoreElements() {
            if (entry !is null) {
                return true;
            }
            while (start <= lastSlot) {
                if (elementData[start++] !is null) {
                    entry = elementData[start - 1];
                    return true;
                }
            }
            return false;
        }

        public Object nextElement() {
            if (hasMoreElements()) {
                Object result = key ? entry.key : entry.value;
                entry = entry.next;
                return result;
            } else {
                throw new NoSuchElementException(null);
            }
        }
    }

    /+transient+/ int elementCount;

    /+transient+/ HashMapEntry[] elementData;

    private float loadFactor;

    private int threshold;

    /+transient+/ int firstSlot = 0;

    /+transient+/ int lastSlot = -1;

    /+transient+/ private IElementComparer comparer;

    private static const EmptyEnumerator emptyEnumerator;
    static this(){
        emptyEnumerator = new EmptyEnumerator();
    }

    /**
     * The default capacity used when not specified in the constructor.
     */
    public static const int DEFAULT_CAPACITY = 13;

    /**
     * Constructs a new Hashtable using the default capacity
     * and load factor.
     */
    public this() {
        this(13);
    }

    /**
     * Constructs a new Hashtable using the specified capacity
     * and the default load factor.
     *
     * @param capacity the initial capacity
     */
    public this(int capacity) {
        this(capacity, null);
    }

    /**
     * Constructs a new hash table with the default capacity and the given
     * element comparer.
     *
     * @param comparer the element comparer to use to compare keys and obtain
     *   hash codes for keys, or <code>null</code>  to use the normal
     *   <code>equals</code> and <code>hashCode</code> methods
     */
    public this(IElementComparer comparer) {
        this(DEFAULT_CAPACITY, comparer);
    }

    /**
     * Constructs a new hash table with the given capacity and the given
     * element comparer.
     *
     * @param capacity the maximum number of elements that can be added without
     *   rehashing
     * @param comparer the element comparer to use to compare keys and obtain
     *   hash codes for keys, or <code>null</code>  to use the normal
     *   <code>equals</code> and <code>hashCode</code> methods
     */
    public this(int capacity, IElementComparer comparer) {
        if (capacity >= 0) {
            elementCount = 0;
            elementData = new HashMapEntry[capacity is 0 ? 1 : capacity];
            firstSlot = elementData.length;
            loadFactor = 0.75f;
            computeMaxSize();
        } else {
            throw new IllegalArgumentException(null);
        }
        this.comparer = comparer;
    }

    /**
     * Constructs a new hash table with enough capacity to hold all keys in the
     * given hash table, then adds all key/value pairs in the given hash table
     * to the new one, using the given element comparer.
     * @param table the original hash table to copy from
     *
     * @param comparer the element comparer to use to compare keys and obtain
     *   hash codes for keys, or <code>null</code>  to use the normal
     *   <code>equals</code> and <code>hashCode</code> methods
     */
    public this(CustomHashtable table, IElementComparer comparer) {
        this(table.size() * 2, comparer);
        for (int i = table.elementData.length; --i >= 0;) {
            HashMapEntry entry = table.elementData[i];
            while (entry !is null) {
                put(entry.key, entry.value);
                entry = entry.next;
            }
        }
    }

    /**
     * Returns the element comparer used  to compare keys and to obtain
     * hash codes for keys, or <code>null</code> if no comparer has been
     * provided.
     *
     * @return the element comparer or <code>null</code>
     *
     * @since 3.2
     */
    public IElementComparer getComparer() {
        return comparer;
    }

    private void computeMaxSize() {
        threshold = cast(int) (elementData.length * loadFactor);
    }

    /**
     * Answers if this Hashtable contains the specified object as a key
     * of one of the key/value pairs.
     *
     * @param       key the object to look for as a key in this Hashtable
     * @return      true if object is a key in this Hashtable, false otherwise
     */
    public bool containsKey(Object key) {
        return getEntry(key) !is null;
    }

    /**
     * Answers an Enumeration on the values of this Hashtable. The
     * results of the Enumeration may be affected if the contents
     * of this Hashtable are modified.
     *
     * @return      an Enumeration of the values of this Hashtable
     */
    public Enumeration elements() {
        if (elementCount is 0) {
            return emptyEnumerator;
        }
        return new HashEnumerator(false);
    }

    /**
     * Answers the value associated with the specified key in
     * this Hashtable.
     *
     * @param       key the key of the value returned
     * @return      the value associated with the specified key, null if the specified key
     *              does not exist
     */
    public Object get(Object key) {
        int index = (toHash(key) & 0x7FFFFFFF) % elementData.length;
        HashMapEntry entry = elementData[index];
        while (entry !is null) {
            if (keyEquals(key, entry.key)) {
                return entry.value;
            }
            entry = entry.next;
        }
        return null;
    }

    private HashMapEntry getEntry(Object key) {
        int index = (toHash(key) & 0x7FFFFFFF) % elementData.length;
        HashMapEntry entry = elementData[index];
        while (entry !is null) {
            if (keyEquals(key, entry.key)) {
                return entry;
            }
            entry = entry.next;
        }
        return null;
    }

    /**
     * Answers the hash code for the given key.
     */
    private hash_t toHash(Object key) {
        if (comparer is null) {
            return key.toHash();
        } else {
            return comparer.toHash(key);
        }
    }

    /**
     * Compares two keys for equality.
     */
    private bool keyEquals(Object a, Object b) {
        if (comparer is null) {
            return a.opEquals(b) !is 0;
        } else {
            return comparer.opEquals(a, b) !is 0;
        }
    }

    /**
     * Answers an Enumeration on the keys of this Hashtable. The
     * results of the Enumeration may be affected if the contents
     * of this Hashtable are modified.
     *
     * @return      an Enumeration of the keys of this Hashtable
     */
    public Enumeration keys() {
        if (elementCount is 0) {
            return emptyEnumerator;
        }
        return new HashEnumerator(true);
    }

    /**
     * Associate the specified value with the specified key in this Hashtable.
     * If the key already exists, the old value is replaced. The key and value
     * cannot be null.
     *
     * @param       key the key to add
     * @param       value   the value to add
     * @return      the old value associated with the specified key, null if the key did
     *              not exist
     */
    public Object put(Object key, Object value) {
        if (key !is null && value !is null) {
            int index = (toHash(key) & 0x7FFFFFFF) % elementData.length;
            HashMapEntry entry = elementData[index];
            while (entry !is null && !keyEquals(key, entry.key)) {
                entry = entry.next;
            }
            if (entry is null) {
                if (++elementCount > threshold) {
                    rehash();
                    index = (toHash(key) & 0x7FFFFFFF) % elementData.length;
                }
                if (index < firstSlot) {
                    firstSlot = index;
                }
                if (index > lastSlot) {
                    lastSlot = index;
                }
                entry = new HashMapEntry(key, value);
                entry.next = elementData[index];
                elementData[index] = entry;
                return null;
            }
            Object result = entry.value;
            entry.key = key; // important to avoid hanging onto keys that are equal but "old" -- see bug 30607
            entry.value = value;
            return result;
        } else {
            throw new NullPointerException();
        }
    }

    /**
     * Increases the capacity of this Hashtable. This method is sent when
     * the size of this Hashtable exceeds the load factor.
     */
    private void rehash() {
        int length = elementData.length << 1;
        if (length is 0) {
            length = 1;
        }
        firstSlot = length;
        lastSlot = -1;
        HashMapEntry[] newData = new HashMapEntry[length];
        for (int i = elementData.length; --i >= 0;) {
            HashMapEntry entry = elementData[i];
            while (entry !is null) {
                int index = (toHash(entry.key) & 0x7FFFFFFF) % length;
                if (index < firstSlot) {
                    firstSlot = index;
                }
                if (index > lastSlot) {
                    lastSlot = index;
                }
                HashMapEntry next = entry.next;
                entry.next = newData[index];
                newData[index] = entry;
                entry = next;
            }
        }
        elementData = newData;
        computeMaxSize();
    }

    /**
     * Remove the key/value pair with the specified key from this Hashtable.
     *
     * @param       key the key to remove
     * @return      the value associated with the specified key, null if the specified key
     *              did not exist
     */
    public Object remove(Object key) {
        HashMapEntry last = null;
        int index = (toHash(key) & 0x7FFFFFFF) % elementData.length;
        HashMapEntry entry = elementData[index];
        while (entry !is null && !keyEquals(key, entry.key)) {
            last = entry;
            entry = entry.next;
        }
        if (entry !is null) {
            if (last is null) {
                elementData[index] = entry.next;
            } else {
                last.next = entry.next;
            }
            elementCount--;
            return entry.value;
        }
        return null;
    }

    /**
     * Answers the number of key/value pairs in this Hashtable.
     *
     * @return      the number of key/value pairs in this Hashtable
     */
    public int size() {
        return elementCount;
    }

    /**
     * Answers the string representation of this Hashtable.
     *
     * @return      the string representation of this Hashtable
     */
    public override String toString() {
        if (size() is 0) {
            return "{}"; //$NON-NLS-1$
        }

        StringBuffer buffer = new StringBuffer();
        buffer.append('{');
        for (int i = elementData.length; --i >= 0;) {
            HashMapEntry entry = elementData[i];
            while (entry !is null) {
                if( buffer.length > 1 ){
                    buffer.append(", "); //$NON-NLS-1$
                }
                buffer.append(entry.key.toString);
                buffer.append('=');
                buffer.append(entry.value.toString);
                entry = entry.next;
            }
        }
        buffer.append('}');
        return buffer.toString();
    }
}
