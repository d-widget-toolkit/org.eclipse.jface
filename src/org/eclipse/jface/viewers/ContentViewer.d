/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
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
module org.eclipse.jface.viewers.ContentViewer;

import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ILabelProviderListener;
import org.eclipse.jface.viewers.IContentProvider;
import org.eclipse.jface.viewers.LabelProviderChangedEvent;
import org.eclipse.jface.viewers.LabelProvider;

import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.widgets.Control;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Set;

/**
 * A content viewer is a model-based adapter on a widget which accesses its
 * model by means of a content provider and a label provider.
 * <p>
 * A viewer's model consists of elements, represented by objects.
 * A viewer defines and implements generic infrastructure for handling model
 * input, updates, and selections in terms of elements.
 * Input is obtained by querying an <code>IContentProvider</code> which returns
 * elements. The elements themselves are not displayed directly.  They are
 * mapped to labels, containing text and/or an image, using the viewer's
 * <code>ILabelProvider</code>.
 * </p>
 * <p>
 * Implementing a concrete content viewer typically involves the following steps:
 * <ul>
 * <li>
 * create SWT controls for viewer (in constructor) (optional)
 * </li>
 * <li>
 * initialize SWT controls from input (inputChanged)
 * </li>
 * <li>
 * define viewer-specific update methods
 * </li>
 * <li>
 * support selections (<code>setSelection</code>, <code>getSelection</code>)
 * </ul>
 * </p>
 */
public abstract class ContentViewer : Viewer {

    /**
     * This viewer's content provider, or <code>null</code> if none.
     */
    private IContentProvider contentProvider = null;

    /**
     * This viewer's input, or <code>null</code> if none.
     * The viewer's input provides the "model" for the viewer's content.
     */
    private Object input = null;

    /**
     * This viewer's label provider. Initially <code>null</code>, but
     * lazily initialized (to a <code>SimpleLabelProvider</code>).
     */
    private IBaseLabelProvider labelProvider = null;

    /**
     * This viewer's label provider listener.
     * Note: Having a viewer register a label provider listener with
     * a label provider avoids having to define public methods
     * for internal events.
     */
    private const ILabelProviderListener labelProviderListener;

    /**
     * Creates a content viewer with no input, no content provider, and a
     * default label provider.
     */
    protected this() {
        labelProviderListener = new class ILabelProviderListener {
            public void labelProviderChanged(LabelProviderChangedEvent event) {
                this.outer.handleLabelProviderChanged(event);
            }
        };
    }

    /**
     * Returns the content provider used by this viewer,
     * or <code>null</code> if this view does not yet have a content
     * provider.
     * <p>
     * The <code>ContentViewer</code> implementation of this method returns the content
     * provider recorded is an internal state variable.
     * Overriding this method is generally not required;
     * however, if overriding in a subclass,
     * <code>super.getContentProvider</code> must be invoked.
     * </p>
     *
     * @return the content provider, or <code>null</code> if none
     */
    public IContentProvider getContentProvider() {
        return contentProvider;
    }

    /**
     * The <code>ContentViewer</code> implementation of this <code>IInputProvider</code>
     * method returns the current input of this viewer, or <code>null</code>
     * if none. The viewer's input provides the "model" for the viewer's
     * content.
     */
    public override Object getInput() {
        return input;
    }

    /**
     * Returns the label provider used by this viewer.
     * <p>
     * The <code>ContentViewer</code> implementation of this method returns the label
     * provider recorded in an internal state variable; if none has been
     * set (with <code>setLabelProvider</code>) a default label provider
     * will be created, remembered, and returned.
     * Overriding this method is generally not required;
     * however, if overriding in a subclass,
     * <code>super.getLabelProvider</code> must be invoked.
     * </p>
     *
     * @return a label provider
     */
    public IBaseLabelProvider getLabelProvider() {
        if (labelProvider is null) {
            labelProvider = new LabelProvider();
        }
        return labelProvider;
    }

    /**
     * Handles a dispose event on this viewer's control.
     * <p>
     * The <code>ContentViewer</code> implementation of this method disposes of this
     * viewer's label provider and content provider (if it has one).
     * Subclasses should override this method to perform any additional
     * cleanup of resources; however, overriding methods must invoke
     * <code>super.handleDispose</code>.
     * </p>
     *
     * @param event a dispose event
     */
    protected void handleDispose(DisposeEvent event) {
        if (contentProvider !is null) {
            contentProvider.inputChanged(this, getInput(), null);
            contentProvider.dispose();
            contentProvider = null;
        }
        if (labelProvider !is null) {
            labelProvider.removeListener(labelProviderListener);
            labelProvider.dispose();
            labelProvider = null;
        }
        input = null;
    }

    /**
     * Handles a label provider changed event.
     * <p>
     * The <code>ContentViewer</code> implementation of this method calls <code>labelProviderChanged()</code>
     * to cause a complete refresh of the viewer.
     * Subclasses may reimplement or extend.
     * </p>
     * @param event the change event
     */
    protected void handleLabelProviderChanged(LabelProviderChangedEvent event) {
        labelProviderChanged();
    }

    /**
     * Adds event listener hooks to the given control.
     * <p>
     * All subclasses must call this method when their control is
     * first established.
     * </p>
     * <p>
     * The <code>ContentViewer</code> implementation of this method hooks
     * dispose events for the given control.
     * Subclasses may override if they need to add other control hooks;
     * however, <code>super.hookControl</code> must be invoked.
     * </p>
     *
     * @param control the control
     */
    protected void hookControl(Control control) {
        control.addDisposeListener(new class DisposeListener {
            public void widgetDisposed(DisposeEvent event) {
                handleDispose(event);
            }
        });
    }

    /**
     * Notifies that the label provider has changed.
     * <p>
     * The <code>ContentViewer</code> implementation of this method calls <code>refresh()</code>.
     * Subclasses may reimplement or extend.
     * </p>
     */
    protected void labelProviderChanged() {
        refresh();
    }

    /**
     * Sets the content provider used by this viewer.
     * <p>
     * The <code>ContentViewer</code> implementation of this method records the
     * content provider in an internal state variable.
     * Overriding this method is generally not required;
     * however, if overriding in a subclass,
     * <code>super.setContentProvider</code> must be invoked.
     * </p>
     *
     * @param contentProvider the content provider
     * @see #getContentProvider
     */
    public void setContentProvider(IContentProvider contentProvider) {
        Assert.isNotNull(cast(Object)contentProvider);
        IContentProvider oldContentProvider = this.contentProvider;
        this.contentProvider = contentProvider;
        if (oldContentProvider !is null) {
            Object currentInput = getInput();
            oldContentProvider.inputChanged(this, currentInput, null);
            oldContentProvider.dispose();
            contentProvider.inputChanged(this, null, currentInput);
            refresh();
        }
    }

    /**
     * The <code>ContentViewer</code> implementation of this <code>Viewer</code>
     * method invokes <code>inputChanged</code> on the content provider and then the
     * <code>inputChanged</code> hook method. This method fails if this viewer does
     * not have a content provider. Subclassers are advised to override
     * <code>inputChanged</code> rather than this method, but may extend this method
     * if required.
     */
    public override void setInput(Object input) {
        Assert
                .isTrue(getContentProvider() !is null,
                        "ContentViewer must have a content provider when input is set."); //$NON-NLS-1$

        Object oldInput = getInput();
        contentProvider.inputChanged(this, oldInput, input);
        this.input = input;

        // call input hook
        inputChanged(this.input, oldInput);
    }

    /**
     * Sets the label provider for this viewer.
     * <p>
     * The <code>ContentViewer</code> implementation of this method ensures that the
     * given label provider is connected to this viewer and the
     * former label provider is disconnected from this viewer.
     * Overriding this method is generally not required;
     * however, if overriding in a subclass,
     * <code>super.setLabelProvider</code> must be invoked.
     * </p>
     *
     * @param labelProvider the label provider, or <code>null</code> if none
     */
    public void setLabelProvider(IBaseLabelProvider labelProvider) {
        IBaseLabelProvider oldProvider = this.labelProvider;
        // If it hasn't changed, do nothing.
        // This also ensures that the provider is not disposed
        // if set a second time.
        if (labelProvider is oldProvider) {
            return;
        }
        if (oldProvider !is null) {
            oldProvider.removeListener(this.labelProviderListener);
        }
        this.labelProvider = labelProvider;
        if (labelProvider !is null) {
            labelProvider.addListener(this.labelProviderListener);
        }
        refresh();

        // Dispose old provider after refresh, so that items never refer to stale images.
        if (oldProvider !is null) {
            internalDisposeLabelProvider(oldProvider);
        }
    }

    /**
     * @param oldProvider
     * 
     * @since 3.4
     */
    void internalDisposeLabelProvider(IBaseLabelProvider oldProvider) {
        oldProvider.dispose();
    }
}
