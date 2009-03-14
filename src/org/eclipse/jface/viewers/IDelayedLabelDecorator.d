/*******************************************************************************
 * Copyright (c) 2004, 2007 IBM Corporation and others.
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
module org.eclipse.jface.viewers.IDelayedLabelDecorator;

import org.eclipse.jface.viewers.ILabelDecorator;

import java.lang.all;

/**
 * A delayed label decorator is a label decorator that may not have a
 * decoration available immediately. This interface defines the methods for
 * requesting the preparation of a decorator for an object and for querying
 * if the decorator is ready. Interested parties should register an
 * ILabelProviderListener with a delayed label decorator in order to be informed
 * when the decoration is ready.
 * @since 3.0
 */
public interface IDelayedLabelDecorator : ILabelDecorator {

    /**
     * Prepare the element for decoration. If it is already decorated and ready for update
     * return true. If decoration is pending return false.
     * @param element The element to be decorated
     * @param originalText The starting text.
     * @return bool <code>true</code> if the decoration is ready for this element
     */

    public bool prepareDecoration(Object element, String originalText);

}
