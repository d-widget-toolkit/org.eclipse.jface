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
module org.eclipse.jface.viewers.SelectionChangedEvent;

import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.ISelectionProvider;
// import java.util.EventObject;

import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.EventObject;

/**
 * Event object describing a selection change. The source of these
 * events is a selection provider.
 *
 * @see ISelection
 * @see ISelectionProvider
 * @see ISelectionChangedListener
 */
public class SelectionChangedEvent : EventObject {

    /**
     * Generated serial version UID for this class.
     * @since 3.1
     */
    private static const long serialVersionUID = 3835149545519723574L;

    /**
     * The selection.
     */
    protected ISelection selection;
    package ISelection getSelection_package(){
        return selection;
    }
    /**
     * Creates a new event for the given source and selection.
     *
     * @param source the selection provider
     * @param selection the selection
     */
    public this(ISelectionProvider source, ISelection selection) {
        super(cast(Object)source);
        Assert.isNotNull(cast(Object)selection);
        this.selection = selection;
    }

    /**
     * Returns the selection.
     *
     * @return the selection
     */
    public ISelection getSelection() {
        return selection;
    }

    /**
     * Returns the selection provider that is the source of this event.
     *
     * @return the originating selection provider
     */
    public ISelectionProvider getSelectionProvider() {
        return cast(ISelectionProvider) getSource();
    }
}
