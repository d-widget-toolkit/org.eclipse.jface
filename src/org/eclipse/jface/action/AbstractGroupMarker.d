/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
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
module org.eclipse.jface.action.AbstractGroupMarker;

import org.eclipse.jface.action.ContributionItem;

import org.eclipse.core.runtime.Assert;

import java.lang.all;

/**
 * Abstract superclass for group marker classes.
 * <p>
 * This class is not intended to be subclassed outside the framework.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public abstract class AbstractGroupMarker : ContributionItem {
    /**
     * Constructor for use by subclasses.
     */
    protected this() {
    }

    /**
     * Create a new group marker with the given name.
     * The group name must not be <code>null</code> or the empty string.
     * The group name is also used as the item id.
     *
     * @param groupName the name of the group
     */
    protected this(String groupName) {
        super(groupName);
        Assert.isTrue(groupName !is null && groupName.length > 0);
    }

    /**
     * Returns the group name.
     *
     * @return the group name
     */
    public String getGroupName() {
        return getId();
    }

    /**
     * The <code>AbstractGroupMarker</code> implementation of this <code>IContributionItem</code>
     * method returns <code>true</code> iff the id is not <code>null</code>. Subclasses may override.
     */
    public override bool isGroupMarker() {
        return getId() !is null;
    }
}
