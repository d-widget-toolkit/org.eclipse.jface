/*******************************************************************************
 * Copyright (c) 2005, 2007 IBM Corporation and others.
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

module org.eclipse.jface.viewers.NamedHandleObjectLabelProvider;

import org.eclipse.jface.viewers.DialogCellEditor;
import org.eclipse.jface.viewers.LabelProvider;


import org.eclipse.core.commands.common.NamedHandleObject;
import org.eclipse.core.commands.common.NotDefinedException;

import java.lang.all;

/**
 * A label provider for instances of <code>NamedHandlerObject</code>, which
 * exposes the name as the label.
 *
 * @since 3.2
 */
public final class NamedHandleObjectLabelProvider : LabelProvider {
    
    /**
     * The text of the element is simply the name of the element if its a
     * defined instance of <code>NamedHandleObject</code>. Otherwise, this
     * method just returns <code>null</code>.
     * 
     * @param element
     *            The element for which the text should be retrieved; may be
     *            <code>null</code>.
     * @return the name of the handle object; <code>null</code> if there is no
     *         name or if the element is not a named handle object.
     */
    public override final String getText(Object element) {
        if ( cast(NamedHandleObject)element ) {
            try {
                return (cast(NamedHandleObject) element).getName();
            } catch (NotDefinedException e) {
                return null;
            }
        }

        return null;
    }
}

