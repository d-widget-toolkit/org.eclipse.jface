/*******************************************************************************
 * Copyright (c) 2000, 2005 IBM Corporation and others.
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
module org.eclipse.jface.window.SameShellProvider;

import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Shell;

import org.eclipse.jface.window.IShellProvider;

import java.lang.all;

/**
 * Standard shell provider that always returns the shell containing the given
 * control. This will always return the correct shell for the control, even if
 * the control is reparented.
 *
 * @since 3.1
 */
public class SameShellProvider : IShellProvider {

    private Control targetControl;

    /**
     * Returns a shell provider that always returns the current
     * shell for the given control.
     *
     * @param targetControl control whose shell will be tracked, or null if getShell() should always
     * return null
     */
    public this(Control targetControl) {
        this.targetControl = targetControl;
    }

    /* (non-javadoc)
     * @see IShellProvider#getShell()
     */
    public Shell getShell() {
        if ( auto res = cast(Shell)targetControl ) {
            return res;
        }

        return targetControl is null? null :targetControl.getShell();
    }

}
