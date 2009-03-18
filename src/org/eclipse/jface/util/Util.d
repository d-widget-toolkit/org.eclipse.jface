/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
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

module org.eclipse.jface.util.Util;

import java.util.Collections;
import java.util.List;
import java.util.MissingResourceException;
import java.util.ResourceBundle;
import java.util.SortedSet;
import java.util.TreeSet;

import java.lang.all;
import java.util.Set;
private extern(C) int _d_isbaseof(ClassInfo *b, ClassInfo *c);

/**
 * <p>
 * A static class providing utility methods to all of JFace.
 * </p>
 *
 * @since 3.1
 */
public final class Util {

//     /**
//      * An unmodifiable, empty, sorted set. This value is guaranteed to never
//      * change and never be <code>null</code>.
//      */
//     public static final SortedSet EMPTY_SORTED_SET = Collections
//             .unmodifiableSortedSet(new TreeSet());

    /**
     * A common zero-length string. It avoids needing write <code>NON-NLS</code>
     * next to code fragments. It's also a bit clearer to read.
     */
    public static final String ZERO_LENGTH_STRING = ""; //$NON-NLS-1$

    /**
     * Verifies that the given object is an instance of the given class.
     *
     * @param object
     *            The object to check; may be <code>null</code>.
     * @param c
     *            The class which the object should be; must not be
     *            <code>null</code>.
     */
    public static final void assertInstance(Object object, ClassInfo c) {
        assertInstance(object, c, false);
    }

    /**
     * Verifies the given object is an instance of the given class. It is
     * possible to specify whether the object is permitted to be
     * <code>null</code>.
     *
     * @param object
     *            The object to check; may be <code>null</code>.
     * @param c
     *            The class which the object should be; must not be
     *            <code>null</code>.
     * @param allowNull
     *            Whether the object is allowed to be <code>null</code>.
     */
    private static final void assertInstance(Object object,
            ClassInfo c,  bool allowNull) {
        if (object is null && allowNull) {
            return;
        }

        if (object is null || c is null) {
            throw new NullPointerException();
        } else if (!_d_isbaseof( &object.classinfo, &c ) ) {
            throw new IllegalArgumentException(null);
        }
    }

    /**
     * Compares two bool values. <code>false</code> is considered to be
     * "less than" <code>true</code>.
     *
     * @param left
     *            The left value to compare
     * @param right
     *            The right value to compare
     * @return <code>-1</code> if the left is <code>false</code> and the
     *         right is <code>true</code>. <code>1</code> if the opposite
     *         is true. If they are equal, then it returns <code>0</code>.
     */
    public static final int compare(bool left, bool right) {
        return left is false ? (right is true ? -1 : 0) : 1;
    }

    /**
     * Compares two integer values.
     *
     * @param left
     *            The left value to compare
     * @param right
     *            The right value to compare
     * @return <code>left - right</code>
     */
    public static final int compare(int left, int right) {
        return left - right;
    }

    /**
     * Compares to comparable objects -- defending against <code>null</code>.
     *
     * @param left
     *            The left object to compare; may be <code>null</code>.
     * @param right
     *            The right object to compare; may be <code>null</code>.
     * @return The result of the comparison. <code>null</code> is considered
     *         to be the least possible value.
     */
    public static final int compare(Comparable left,
            Comparable right) {
        if (left is null && right is null) {
            return 0;
        } else if (left is null) {
            return -1;
        } else if (right is null) {
            return 1;
        } else {
            return left.compareTo(cast(Object)right);
        }
    }

    /**
     * Compares two arrays of comparable objects -- accounting for
     * <code>null</code>.
     *
     * @param left
     *            The left array to be compared; may be <code>null</code>.
     * @param right
     *            The right array to be compared; may be <code>null</code>.
     * @return The result of the comparison. <code>null</code> is considered
     *         to be the least possible value. A shorter array is considered
     *         less than a longer array.
     */
    public static final int compare(Comparable[] left,
            Comparable[] right) {
        if (left is null && right is null) {
            return 0;
        } else if (left is null) {
            return -1;
        } else if (right is null) {
            return 1;
        } else {
            int l = left.length;
            int r = right.length;

            if (l !is r) {
                return l - r;
            }

            for (int i = 0; i < l; i++) {
                int compareTo = compare(left[i], right[i]);

                if (compareTo !is 0) {
                    return compareTo;
                }
            }

            return 0;
        }
    }
    public static final int compare(String left, String right) {
        return left < right;
    }

//     /**
//      * Compares two lists -- account for <code>null</code>. The lists must
//      * contain comparable objects.
//      *
//      * @param left
//      *            The left list to compare; may be <code>null</code>. This
//      *            list must only contain instances of <code>Comparable</code>.
//      * @param right
//      *            The right list to compare; may be <code>null</code>. This
//      *            list must only contain instances of <code>Comparable</code>.
//      * @return The result of the comparison. <code>null</code> is considered
//      *         to be the least possible value. A shorter list is considered less
//      *         than a longer list.
//      */
//     public static final int compare(SeqView!(Object) left, SeqView!(Object) right) {
//         if (left is null && right is null) {
//             return 0;
//         } else if (left is null) {
//             return -1;
//         } else if (right is null) {
//             return 1;
//         } else {
//             int l = left.size();
//             int r = right.size();
//
//             if (l !is r) {
//                 return l - r;
//             }
//
//             for (int i = 0; i < l; i++) {
//                 int compareTo = compare((Comparable) left.get(i),
//                         (Comparable) right.get(i));
//
//                 if (compareTo !is 0) {
//                     return compareTo;
//                 }
//             }
//
//             return 0;
//         }
//     }

    /**
     * Tests whether the first array ends with the second array.
     *
     * @param left
     *            The array to check (larger); may be <code>null</code>.
     * @param right
     *            The array that should be a subsequence (smaller); may be
     *            <code>null</code>.
     * @param equals
     *            Whether the two array are allowed to be equal.
     * @return <code>true</code> if the second array is a subsequence of the
     *         array list, and they share end elements.
     */
    public static final bool endsWith(Object[] left,
            Object[] right, bool equals) {
        if (left is null || right is null) {
            return false;
        }

        int l = left.length;
        int r = right.length;

        if (r > l || !equals && r is l) {
            return false;
        }

        for (int i = 0; i < r; i++) {
            if (!Util.opEquals(left[l - i - 1], right[r - i - 1])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Checks whether the two objects are <code>null</code> -- allowing for
     * <code>null</code>.
     *
     * @param left
     *            The left object to compare; may be <code>null</code>.
     * @param right
     *            The right object to compare; may be <code>null</code>.
     * @return <code>true</code> if the two objects are equivalent;
     *         <code>false</code> otherwise.
     */
    public static final bool opEquals(Object left, Object right) {
        return left is null ? right is null : ((right !is null) && left
                .opEquals(right));
    }
    public static final bool opEquals(String left, String right) {
        return left == right;
    }

    /**
     * Tests whether two arrays of objects are equal to each other. The arrays
     * must not be <code>null</code>, but their elements may be
     * <code>null</code>.
     *
     * @param leftArray
     *            The left array to compare; may be <code>null</code>, and
     *            may be empty and may contain <code>null</code> elements.
     * @param rightArray
     *            The right array to compare; may be <code>null</code>, and
     *            may be empty and may contain <code>null</code> elements.
     * @return <code>true</code> if the arrays are equal length and the
     *         elements at the same position are equal; <code>false</code>
     *         otherwise.
     */
    public static final bool opEquals(Object[] leftArray,
            Object[] rightArray) {
        if (leftArray is rightArray) {
            return true;
        }

        if (leftArray is null) {
            return (rightArray is null);
        } else if (rightArray is null) {
            return false;
        }

        if (leftArray.length !is rightArray.length) {
            return false;
        }

        for (int i = 0; i < leftArray.length; i++) {
            Object left = leftArray[i];
            Object right = rightArray[i];
            bool equal = ((left is null) ? (right is null) : (left.opEquals(right))) !is 0;
            if (!equal) {
                return false;
            }
        }

        return true;
    }

    public static final bool opEquals(String[] leftArray, String[] rightArray) {
        if (leftArray.length !is rightArray.length) {
            return false;
        }

        for (int i = 0; i < leftArray.length; i++) {
            String left = leftArray[i];
            String right = rightArray[i];
            if (left != right) {
                return false;
            }
        }

        return true;
    }

    /**
     * Provides a hash code based on the given integer value.
     *
     * @param i
     *            The integer value
     * @return <code>i</code>
     */
    public static final hash_t toHash(int i) {
        return i;
    }

    /**
     * Provides a hash code for the object -- defending against
     * <code>null</code>.
     *
     * @param object
     *            The object for which a hash code is required.
     * @return <code>object.hashCode</code> or <code>0</code> if
     *         <code>object</code> if <code>null</code>.
     */
    public static final hash_t toHash( Object object) {
        return object !is null ? object.toHash() : 0;
    }

    /**
     * Computes the hash code for an array of objects, but with defense against
     * <code>null</code>.
     *
     * @param objects
     *            The array of objects for which a hash code is needed; may be
     *            <code>null</code>.
     * @return The hash code for <code>objects</code>; or <code>0</code> if
     *         <code>objects</code> is <code>null</code>.
     */
    public static final hash_t toHash(Object[] objects) {
        if (objects is null) {
            return 0;
        }

        int hashCode = 89;
        for (int i = 0; i < objects.length; i++) {
            final Object object = objects[i];
            if (object !is null) {
                hashCode = hashCode * 31 + object.toHash();
            }
        }

        return hashCode;
    }
    public static final hash_t toHash(String str) {
        return java.lang.all.toHash(str);
    }
    public static final hash_t toHash(String[] objects) {
        int hashCode = 89;
        for (int i = 0; i < objects.length; i++) {
            auto object = objects[i];
            hashCode = hashCode * 31 + toHash(object);
        }

        return hashCode;
    }

    /**
     * Checks whether the second array is a subsequence of the first array, and
     * that they share common starting elements.
     *
     * @param left
     *            The first array to compare (large); may be <code>null</code>.
     * @param right
     *            The second array to compare (small); may be <code>null</code>.
     * @param equals
     *            Whether it is allowed for the two arrays to be equivalent.
     * @return <code>true</code> if the first arrays starts with the second
     *         list; <code>false</code> otherwise.
     */
    public static final bool startsWith(Object[] left,
            Object[] right, bool equals) {
        if (left is null || right is null) {
            return false;
        }

        int l = left.length;
        int r = right.length;

        if (r > l || !equals && r is l) {
            return false;
        }

        for (int i = 0; i < r; i++) {
            if (!opEquals(left[i], right[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Converts an array into a string representation that is suitable for
     * debugging.
     *
     * @param array
     *            The array to convert; may be <code>null</code>.
     * @return The string representation of the array; never <code>null</code>.
     */
    public static final String toString(Object[] array) {
        if (array is null) {
            return "null"; //$NON-NLS-1$
        }

        final StringBuffer buffer = new StringBuffer();
        buffer.append('[');

        final int length = array.length;
        for (int i = 0; i < length; i++) {
            if (i !is 0) {
                buffer.append(',');
            }
            Object object = array[i];
            String element = (object is null ) ? "null" : object.toString;
            buffer.append(element);
        }
        buffer.append(']');

        return buffer.toString();
    }

    /**
     * Provides a translation of a particular key from the resource bundle.
     *
     * @param resourceBundle
     *            The key to look up in the resource bundle; should not be
     *            <code>null</code>.
     * @param key
     *            The key to look up in the resource bundle; should not be
     *            <code>null</code>.
     * @param defaultString
     *            The value to return if the resource cannot be found; may be
     *            <code>null</code>.
     * @return The value of the translated resource at <code>key</code>. If
     *         the key cannot be found, then it is simply the
     *         <code>defaultString</code>.
     */
    public static final String translateString(
            ResourceBundle resourceBundle, String key,
            String defaultString) {
        if (resourceBundle !is null && key !is null) {
            try {
                String translatedString = resourceBundle.getString(key);

                if (translatedString !is null) {
                    return translatedString;
                }
            } catch (MissingResourceException eMissingResource) {
                // Such is life. We'll return the key
            }
        }

        return defaultString;
    }

    /**
     * Foundation replacement for String.replaceAll(*).
     *
     * @param src the starting string.
     * @param find the string to find.
     * @param replacement the string to replace.
     * @return The new string.
     * @since 3.4
     */
    public static final String replaceAll(String src, String find, String replacement) {
        final int len = src.length;
        final int findLen = find.length;

        int idx = src.indexOf(find);
        if (idx < 0) {
            return src;
        }

        StringBuffer buf = new StringBuffer();
        int beginIndex = 0;
        while (idx !is -1 && idx < len) {
            buf.append(src.substring(beginIndex, idx));
            buf.append(replacement);

            beginIndex = idx + findLen;
            if (beginIndex < len) {
                idx = src.indexOf(find, beginIndex);
            } else {
                idx = -1;
            }
        }
        if (beginIndex<len) {
            buf.append(src.substring(beginIndex, (idx is -1 ? len : idx)));
        }
        return buf.toString();
    }

    /**
     * This class should never be constructed.
     */
    private this() {
        // Not allowed.
    }
}
