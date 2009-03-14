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
module org.eclipse.jface.preference.IPersistentPreferenceStore;

import java.lang.all;

import org.eclipse.jface.preference.IPreferenceStore;

/**
 * IPersistentPreferenceStore is a preference store that can
 * be saved.
 */
public interface IPersistentPreferenceStore : IPreferenceStore {

    /**
     * Saves the non-default-valued preferences known to this preference
     * store to the file from which they were originally loaded.
     *
     * @exception java.io.IOException if there is a problem saving this store
     */
    public void save();

}
