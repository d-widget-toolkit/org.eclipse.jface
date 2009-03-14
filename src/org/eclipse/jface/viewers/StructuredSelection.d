/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
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
module org.eclipse.jface.viewers.StructuredSelection;

import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.IElementComparer;


import org.eclipse.core.runtime.Assert;
import org.eclipse.jface.resource.JFaceResources;

import java.lang.all;
import java.util.Arrays;
import java.util.List;
import java.util.Iterator;

/**
 * A concrete implementation of the <code>IStructuredSelection</code> interface,
 * suitable for instantiating.
 * <p>
 * This class is not intended to be subclassed.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class StructuredSelection : IStructuredSelection {

    /**
     * The element that make up this structured selection.
     */
    private Object[] elements;

    /**
     * The element comparer, or <code>null</code>
     */
    private IElementComparer comparer;

    /**
     * The canonical empty selection. This selection should be used instead of
     * <code>null</code>.
     */
    public static const StructuredSelection EMPTY;
    static this(){
        EMPTY = new StructuredSelection();
    }
    /**
     * Creates a new empty selection.
     * See also the static field <code>EMPTY</code> which contains an empty selection singleton.
     *
     * @see #EMPTY
     */
    public this() {
    }

    /**
     * Creates a structured selection from the given elements.
     *
     * @param elements an array of elements
     */
    public this(Object[] elements) {
        this.elements = new Object[elements.length];
        System.arraycopy(elements, 0, this.elements, 0, elements.length);
    }

    /**
     * Creates a structured selection containing a single object.
     * The object must not be <code>null</code>.
     *
     * @param element the element
     */
    public this(Object element) {
        Assert.isNotNull(element);
        elements = [ element ];
    }

    /**
     * Creates a structured selection from the given <code>List</code>.
     * @param elements list of selected elements
     */
    public this(List elements) {
        this(elements, null);
    }

    /**
     * Creates a structured selection from the given <code>List</code> and
     * element comparer. If an element comparer is provided, it will be used to
     * determine equality between structured selection objects provided that
     * they both are based on the same (identical) comparer. See bug
     *
     * @param elements
     *            list of selected elements
     * @param comparer
     *            the comparer, or null
     * @since 3.4
     */
    public this(List elements, IElementComparer comparer) {
        Assert.isNotNull(cast(Object)elements);
        this.elements = elements.toArray();
        this.comparer = comparer;
    }

    /**
     * Returns whether this structured selection is equal to the given object.
     * Two structured selections are equal if they contain the same elements
     * in the same order.
     *
     * @param o the other object
     * @return <code>true</code> if they are equal, and <code>false</code> otherwise
     */
    public override int opEquals(Object o) {
        if (this is o) {
            return true;
        }
        //null and other classes
        if (!(cast(StructuredSelection)o )) {
            return false;
        }
        StructuredSelection s2 = cast(StructuredSelection) o;

        // either or both empty?
        if (isEmpty()) {
            return s2.isEmpty();
        }
        if (s2.isEmpty()) {
            return false;
        }

        bool useComparer = comparer !is null && comparer is s2.comparer;

        //size
        int myLen = elements.length;
        if (myLen !is s2.elements.length) {
            return false;
        }
        //element comparison
        for (int i = 0; i < myLen; i++) {
            if (useComparer) {
                if (!comparer.opEquals(elements[i], s2.elements[i])) {
                    return false;
                }
            } else {
                if (!elements[i].opEquals(s2.elements[i])) {
                    return false;
                }
            }
        }
        return true;
    }

    /* (non-Javadoc)
     * Method declared in IStructuredSelection.
     */
    public Object getFirstElement() {
        return isEmpty() ? null : elements[0];
    }

    /* (non-Javadoc)
     * Method declared in ISelection.
     */
    public bool isEmpty() {
        return elements is null || elements.length is 0;
    }

    /* (non-Javadoc)
     * Method declared in IStructuredSelection.
     */
    public Iterator iterator() {
        return Arrays.asList(elements is null ? null : elements)
                .iterator();
    }

    /* (non-Javadoc)
     * Method declared in IStructuredSelection.
     */
    public int size() {
        return elements is null ? 0 : elements.length;
    }

    /* (non-Javadoc)
     * Method declared in IStructuredSelection.
     */
    public Object[] toArray() {
        return elements is null ? new Object[0] : elements.dup;
    }

    /* (non-Javadoc)
     * Method declared in IStructuredSelection.
     */
    public List toList() {
        return Arrays.asList(elements is null ? null : elements);
    }

    /**
     * Internal method which returns a string representation of this
     * selection suitable for debug purposes only.
     *
     * @return debug string
     */
    public override String toString() {
        return isEmpty() ? JFaceResources.getString("<empty_selection>") : (cast(Object)toList()).toString(); //$NON-NLS-1$
    }
}
