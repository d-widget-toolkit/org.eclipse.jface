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
module org.eclipse.jface.action.SubStatusLineManager;

import org.eclipse.jface.action.SubContributionManager;
import org.eclipse.jface.action.IStatusLineManager;

import org.eclipse.swt.graphics.Image;
import org.eclipse.core.runtime.IProgressMonitor;

import java.lang.all;
import java.util.Set;

/**
 * A <code>SubStatusLineManager</code> is used to define a set of contribution
 * items within a parent manager.  Once defined, the visibility of the entire set can
 * be changed as a unit.
 */
public class SubStatusLineManager : SubContributionManager,
        IStatusLineManager {
    /**
     * Current status line message.
     */
    private String message;

    /**
     * Current status line error message.
     */
    private String errorMessage;

    /**
     * Current status line message image.
     */
    private Image messageImage;

    /**
     * Current status line error image
     */
    private Image errorImage;

    /**
     * Constructs a new manager.
     *
     * @param mgr the parent manager.  All contributions made to the
     *      <code>SubStatusLineManager</code> are forwarded and appear in the
     *      parent manager.
     */
    public this(IStatusLineManager mgr) {
        super(mgr);
    }

    /**
     * @return the parent status line manager that this sub-manager contributes
     * to
     */
    protected final IStatusLineManager getParentStatusLineManager() {
        // Cast is ok because that's the only
        // thing we accept in the construtor.
        return cast(IStatusLineManager) getParent();
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public IProgressMonitor getProgressMonitor() {
        return getParentStatusLineManager().getProgressMonitor();
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public bool isCancelEnabled() {
        return getParentStatusLineManager().isCancelEnabled();
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public void setCancelEnabled(bool enabled) {
        getParentStatusLineManager().setCancelEnabled(enabled);
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public void setErrorMessage(String message) {
        this.errorImage = null;
        this.errorMessage = message;
        if (isVisible()) {
            getParentStatusLineManager().setErrorMessage(errorMessage);
        }
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public void setErrorMessage(Image image, String message) {
        this.errorImage = image;
        this.errorMessage = message;
        if (isVisible()) {
            getParentStatusLineManager().setErrorMessage(errorImage,
                    errorMessage);
        }
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public void setMessage(String message) {
        this.messageImage = null;
        this.message = message;
        if (isVisible()) {
            getParentStatusLineManager().setMessage(message);
        }
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public void setMessage(Image image, String message) {
        this.messageImage = image;
        this.message = message;
        if (isVisible()) {
            getParentStatusLineManager().setMessage(messageImage, message);
        }
    }

    /* (non-Javadoc)
     * Method declared on SubContributionManager.
     */
    public override void setVisible(bool visible) {
        super.setVisible(visible);
        if (visible) {
            getParentStatusLineManager().setErrorMessage(errorImage,
                    errorMessage);
            getParentStatusLineManager().setMessage(messageImage, message);
        } else {
            getParentStatusLineManager().setMessage(null, null);
            getParentStatusLineManager().setErrorMessage(null, null);
        }
    }

    /* (non-Javadoc)
     * Method declared on IStatusLineManager.
     */
    public void update(bool force) {
        // This method is not governed by visibility.  The client may
        // call <code>setVisible</code> and then force an update.  At that
        // point we need to update the parent.
        getParentStatusLineManager().update(force);
    }
}
