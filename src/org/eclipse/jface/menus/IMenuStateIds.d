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

module org.eclipse.jface.menus.IMenuStateIds;

import org.eclipse.core.commands.INamedHandleStateIds;
// import org.eclipse.jface.commands.RadioState;
// import org.eclipse.jface.commands.ToggleState;

import java.lang.all;

/**
 * <p>
 * State identifiers that should be understood by items and renderers of items.
 * The state is associated with the command, and then interpreted by the menu
 * renderer.
 * </p>
 * <p>
 * Clients may implement or extend this class.
 * </p>
 *
 * @since 3.2
 */
public interface IMenuStateIds : INamedHandleStateIds {

    /**
     * The state id used for indicating the widget style of a command presented
     * in the menus and tool bars. This state must be an instance of
     * {@link ToggleState} or {@link RadioState}.
     */
    public static String STYLE = "STYLE"; //$NON-NLS-1$
}
