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
module org.eclipse.jface.preference.IPreferencePage;

import java.lang.all;

import org.eclipse.jface.preference.IPreferencePageContainer;

import org.eclipse.swt.graphics.Point;
import org.eclipse.jface.dialogs.IDialogPage;

/**
 * An interface for a preference page. This interface
 * is used primarily by the page's container
 */
public interface IPreferencePage : IDialogPage {

    /**
     * Computes a size for this page's UI component.
     *
     * @return the size of the preference page encoded as
     *   <code>new Point(width,height)</code>, or
     *   <code>(0,0)</code> if the page doesn't currently have any UI component
     */
    public Point computeSize();

    /**
     * Returns whether this dialog page is in a valid state.
     *
     * @return <code>true</code> if the page is in a valid state,
     *   and <code>false</code> if invalid
     */
    public bool isValid();

    /**
     * Checks whether it is alright to leave this page.
     *
     * @return <code>false</code> to abort page flipping and the
     *  have the current page remain visible, and <code>true</code>
     *  to allow the page flip
     */
    public bool okToLeave();

    /**
     * Notifies that the container of this preference page has been canceled.
     *
     * @return <code>false</code> to abort the container's cancel
     *  procedure and <code>true</code> to allow the cancel to happen
     */
    public bool performCancel();

    /**
     * Notifies that the OK button of this page's container has been pressed.
     *
     * @return <code>false</code> to abort the container's OK
     *  processing and <code>true</code> to allow the OK to happen
     */
    public bool performOk();

    /**
     * Sets or clears the container of this page.
     *
     * @param preferencePageContainer the preference page container, or <code>null</code>
     */
    public void setContainer(IPreferencePageContainer preferencePageContainer);

    /**
     * Sets the size of this page's UI component.
     *
     * @param size the size of the preference page encoded as
     *   <code>new Point(width,height)</code>
     */
    public void setSize(Point size);
}
