/*******************************************************************************
 * Copyright (c) 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 ******************************************************************************/
module org.eclipse.jface.internal.InternalPolicy;

import java.lang.all;
import java.util.Map;


/**
 * Internal class used for non-API debug flags.
 *
 * @since 3.3
 */
public class InternalPolicy {

    /**
     * (NON-API) A flag to indicate whether reentrant viewer calls should always be
     * logged. If false, only the first reentrant call will cause a log entry.
     *
     * @since 3.3
     */
    public static bool DEBUG_LOG_REENTRANT_VIEWER_CALLS = false;

    /**
     * (NON-API) Instead of logging current conflicts they can be
     * held here.  If there is a problem, they can be reported then.
     */
    public static Map currentConflicts = null;
}
