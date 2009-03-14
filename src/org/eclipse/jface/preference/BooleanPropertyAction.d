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

module org.eclipse.jface.preference.BooleanPropertyAction;

import org.eclipse.jface.preference.IPreferenceStore;

import org.eclipse.jface.action.Action;
import org.eclipse.jface.util.IPropertyChangeListener;
import org.eclipse.jface.util.PropertyChangeEvent;

import java.lang.all;
import java.util.Set;

/**
 * The BooleanPropertyAction is an action that set the values of a
 * bool property in the preference store.
 */

public class BooleanPropertyAction : Action {

    private IPreferenceStore preferenceStore;

    private String property;

    /**
     * Create a new instance of the receiver.
     * @param title The displayable name of the action.
     * @param preferenceStore The preference store to propogate changes to
     * @param property The property that is being updated
     * @throws IllegalArgumentException Thrown if preferenceStore or
     * property are <code>null</code>.
     */
    public this(String title,
            IPreferenceStore preferenceStore, String property) {
        super(title, AS_CHECK_BOX);

        if (preferenceStore is null || property is null) {
            throw new IllegalArgumentException(null);
        }

        this.preferenceStore = preferenceStore;
        this.property = property;
        final String finalProprety = property;

        preferenceStore
                .addPropertyChangeListener(new class IPropertyChangeListener {
                    public void propertyChange(PropertyChangeEvent event) {
                        if (finalProprety.equals(event.getProperty())) {
                            setChecked(cast(bool)(Boolean.TRUE == event.getNewValue() ));
                        }
                    }
                });

        setChecked(preferenceStore.getBoolean(property));
    }

    /*
     *  (non-Javadoc)
     * @see org.eclipse.jface.action.IAction#run()
     */
    public override void run() {
        preferenceStore.setValue(property, isChecked());
    }
}
