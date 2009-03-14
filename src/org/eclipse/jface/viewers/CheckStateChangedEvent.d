/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
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
module org.eclipse.jface.viewers.CheckStateChangedEvent;

import org.eclipse.jface.viewers.ICheckStateListener;
import org.eclipse.jface.viewers.ICheckable;

import java.lang.all;
import java.util.EventObject;

/**
 * Event object describing a change to the checked state
 * of a viewer element.
 *
 * @see ICheckStateListener
 */
public class CheckStateChangedEvent : EventObject {

    /**
     * Generated serial version UID for this class.
     * @since 3.1
     */
    private static const long serialVersionUID = 3256443603340244789L;

    /**
     * The viewer element.
     */
    private Object element;

    /**
     * The checked state.
     */
    private bool state;

    /**
     * Creates a new event for the given source, element, and checked state.
     *
     * @param source the source
     * @param element the element
     * @param state the checked state
     */
    public this(ICheckable source, Object element,
            bool state) {
        super(cast(Object)source);
        this.element = element;
        this.state = state;
    }

    /**
     * Returns the checkable that is the source of this event.
     *
     * @return the originating checkable
     */
    public ICheckable getCheckable() {
        return cast(ICheckable) source;
    }

    /**
     * Returns the checked state of the element.
     *
     * @return the checked state
     */
    public bool getChecked() {
        return state;
    }

    /**
     * Returns the element whose check state changed.
     *
     * @return the element
     */
    public Object getElement() {
        return element;
    }
}
