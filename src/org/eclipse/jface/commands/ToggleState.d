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

module org.eclipse.jface.commands.ToggleState;

import org.eclipse.jface.menus.IMenuStateIds;
import org.eclipse.jface.preference.IPreferenceStore;

import org.eclipse.jface.commands.PersistentState;

import java.lang.all;
import java.util.Set;

/**
 * <p>
 * A piece of state storing a {@link Boolean}.
 * </p>
 * <p>
 * If this state is registered using {@link IMenuStateIds#STYLE}, then it will
 * control the presentation of the command if displayed in the menus, tool bars
 * or status line.
 * </p>
 * <p>
 * Clients may instantiate this class, but must not extend.
 * </p>
 *
 * @since 3.2
 */
public class ToggleState : PersistentState {

    /**
     * Constructs a new <code>ToggleState</code>. By default, the toggle is
     * off (e.g., <code>false</code>).
     */
    public this() {
        setValue(Boolean.FALSE);
    }

    public override final void load(IPreferenceStore store,
            String preferenceKey) {
        bool currentValue = (cast(Boolean) getValue()).booleanValue();
        store.setDefault(preferenceKey, currentValue);
        if (shouldPersist() && (store.contains(preferenceKey))) {
            bool value = store.getBoolean(preferenceKey);
            setValue(value ? Boolean.TRUE : Boolean.FALSE);
        }
    }

    public override final void save(IPreferenceStore store,
            String preferenceKey) {
        if (shouldPersist()) {
            Object value = getValue();
            if ( auto v = cast(Boolean)value ) {
                store.setValue(preferenceKey, v.booleanValue());
            }
        }
    }

    public override void setValue(Object value) {
        if (!(cast(Boolean)value)) {
            throw new IllegalArgumentException(
                    "ToggleState takes a Boolean as a value"); //$NON-NLS-1$
        }

        super.setValue(value);
    }
}
