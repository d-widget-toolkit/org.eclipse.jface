/*******************************************************************************
 * Copyright (c) 2005, 2006 IBM Corporation and others.
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

module org.eclipse.jface.menus.TextState;

import org.eclipse.core.commands.INamedHandleStateIds;
import org.eclipse.jface.commands.PersistentState;
import org.eclipse.jface.preference.IPreferenceStore;

import java.lang.all;
import java.util.Set;

/**
 * <p>
 * A piece of state carrying a single {@link String}.
 * </p>
 * <p>
 * If this state is registered using {@link INamedHandleStateIds#NAME} or
 * {@link INamedHandleStateIds#DESCRIPTION}, then this allows the handler to
 * communicate a textual change for a given command. This is typically used by
 * graphical applications to allow more specific text to be displayed in the
 * menus. For example, "Undo" might become "Undo Typing" through the use of a
 * {@link TextState}.
 * </p>
 * <p>
 * Clients may instantiate this class, but must not extend.
 * </p>
 *
 * @since 3.2
 * @see INamedHandleStateIds
 */
public class TextState : PersistentState {

    public override final void load(IPreferenceStore store,
            String preferenceKey) {
        String value = store.getString(preferenceKey);
        setValue(stringcast(value));
    }

    public override final void save(IPreferenceStore store,
            String preferenceKey) {
        Object value = getValue();
        if ( cast(ArrayWrapperString)value ) {
            store.setValue(preferenceKey, stringcast(value));
        }
    }

    public override void setValue(Object value) {
        if (!( cast(ArrayWrapperString)value )) {
            throw new IllegalArgumentException(
                    "TextState takes a String as a value"); //$NON-NLS-1$
        }

        super.setValue(value);
    }

}
