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
module org.eclipse.jface.viewers.ILabelDecorator;

import org.eclipse.jface.viewers.IBaseLabelProvider;

import org.eclipse.swt.graphics.Image;

import java.lang.all;

/**
 * A label decorator decorates the label text and image for some element.
 * The original label text and image are obtained by some other means,
 * for example by a label provider.
 *
 * @see ILabelProvider
 */
public interface ILabelDecorator : IBaseLabelProvider {
    /**
     * Returns an image that is based on the given image,
     * but decorated with additional information relating to the state
     * of the provided element.
     *
     * Text and image decoration updates can occur as a result of other updates
     * within the workbench including deferred decoration by background processes.
     * Clients should handle labelProviderChangedEvents for the given element to get
     * the complete decoration.
     * @see LabelProviderChangedEvent
     * @see IBaseLabelProvider#addListener
     *
     * @param image the input image to decorate, or <code>null</code> if the element has no image
     * @param element the element whose image is being decorated
     * @return the decorated image, or <code>null</code> if no decoration is to be applied
     *
     * @see org.eclipse.jface.resource.CompositeImageDescriptor
     */
    public Image decorateImage(Image image, Object element);

    /**
     * Returns a text label that is based on the given text label,
     * but decorated with additional information relating to the state
     * of the provided element.
     *
     * Text and image decoration updates can occur as a result of other updates
     * within the workbench including deferred decoration by background processes.
     * Clients should handle labelProviderChangedEvents for the given element to get
     * the complete decoration.
     * @see LabelProviderChangedEvent
     * @see IBaseLabelProvider#addListener
     *
     * @param text the input text label to decorate
     * @param element the element whose image is being decorated
     * @return the decorated text label, or <code>null</code> if no decoration is to be applied
     */
    public String decorateText(String text, Object element);
}
