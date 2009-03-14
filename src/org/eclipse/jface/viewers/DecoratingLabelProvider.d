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
module org.eclipse.jface.viewers.DecoratingLabelProvider;

import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.ILabelProvider;
import org.eclipse.jface.viewers.IViewerLabelProvider;
import org.eclipse.jface.viewers.IColorProvider;
import org.eclipse.jface.viewers.IFontProvider;
import org.eclipse.jface.viewers.ITreePathLabelProvider;
import org.eclipse.jface.viewers.ILabelDecorator;
import org.eclipse.jface.viewers.IDecorationContext;
import org.eclipse.jface.viewers.ILabelProviderListener;
import org.eclipse.jface.viewers.ViewerLabel;
import org.eclipse.jface.viewers.TreePath;
import org.eclipse.jface.viewers.DecorationContext;
import org.eclipse.jface.viewers.LabelDecorator;
import org.eclipse.jface.viewers.LabelProviderChangedEvent;
import org.eclipse.jface.viewers.IDelayedLabelDecorator;
import org.eclipse.jface.viewers.IColorDecorator;
import org.eclipse.jface.viewers.IFontDecorator;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.ListenerList;

import java.lang.all;
import java.util.Set;

/**
 * A decorating label provider is a label provider which combines
 * a nested label provider and an optional decorator.
 * The decorator decorates the label text, image, font and colors provided by
 * the nested label provider.
 */
public class DecoratingLabelProvider : LabelProvider,
        ILabelProvider, IViewerLabelProvider, IColorProvider, IFontProvider, ITreePathLabelProvider {

    private ILabelProvider provider;

    private ILabelDecorator decorator;

    // Need to keep our own list of listeners
    private ListenerList listeners;

    private IDecorationContext decorationContext;

    /**
     * Creates a decorating label provider which uses the given label decorator
     * to decorate labels provided by the given label provider.
     *
     * @param provider the nested label provider
     * @param decorator the label decorator, or <code>null</code> if no decorator is to be used initially
     */
    public this(ILabelProvider provider,
            ILabelDecorator decorator) {
        decorationContext = DecorationContext.DEFAULT_CONTEXT;
        listeners = new ListenerList();
        Assert.isNotNull(cast(Object)provider);
        this.provider = provider;
        this.decorator = decorator;
    }

    /**
     * The <code>DecoratingLabelProvider</code> implementation of this <code>IBaseLabelProvider</code> method
     * adds the listener to both the nested label provider and the label decorator.
     *
     * @param listener a label provider listener
     */
    public override void addListener(ILabelProviderListener listener) {
        super.addListener(listener);
        provider.addListener(listener);
        if (decorator !is null) {
            decorator.addListener(listener);
        }
        listeners.add(cast(Object)listener);
    }

    /**
     * The <code>DecoratingLabelProvider</code> implementation of this <code>IBaseLabelProvider</code> method
     * disposes both the nested label provider and the label decorator.
     */
    public override void dispose() {
        provider.dispose();
        if (decorator !is null) {
            decorator.dispose();
        }
    }

    /**
     * The <code>DecoratingLabelProvider</code> implementation of this
     * <code>ILabelProvider</code> method returns the image provided
     * by the nested label provider's <code>getImage</code> method,
     * decorated with the decoration provided by the label decorator's
     * <code>decorateImage</code> method.
     */
    public override Image getImage(Object element) {
        Image image = provider.getImage(element);
        if (decorator !is null) {
            if ( auto ld2 = cast(LabelDecorator)decorator ) {
                Image decorated = ld2.decorateImage(image, element, getDecorationContext());
                if (decorated !is null) {
                    return decorated;
                }
            } else {
                Image decorated = decorator.decorateImage(image, element);
                if (decorated !is null) {
                    return decorated;
                }
            }
        }
        return image;
    }

    /**
     * Returns the label decorator, or <code>null</code> if none has been set.
     *
     * @return the label decorator, or <code>null</code> if none has been set.
     */
    public ILabelDecorator getLabelDecorator() {
        return decorator;
    }

    /**
     * Returns the nested label provider.
     *
     * @return the nested label provider
     */
    public ILabelProvider getLabelProvider() {
        return provider;
    }

    /**
     * The <code>DecoratingLabelProvider</code> implementation of this
     * <code>ILabelProvider</code> method returns the text label provided
     * by the nested label provider's <code>getText</code> method,
     * decorated with the decoration provided by the label decorator's
     * <code>decorateText</code> method.
     */
    public override String getText(Object element) {
        String text = provider.getText(element);
        if (decorator !is null) {
            if ( auto ld2 = cast(LabelDecorator)decorator ) {
                String decorated = ld2.decorateText(text, element, getDecorationContext());
                if (decorated !is null) {
                    return decorated;
                }
            } else {
                String decorated = decorator.decorateText(text, element);
                if (decorated !is null) {
                    return decorated;
                }
            }
        }
        return text;
    }

    /**
     * The <code>DecoratingLabelProvider</code> implementation of this
     * <code>IBaseLabelProvider</code> method returns <code>true</code> if the corresponding method
     * on the nested label provider returns <code>true</code> or if the corresponding method on the
     * decorator returns <code>true</code>.
     */
    public override bool isLabelProperty(Object element, String property) {
        if (provider.isLabelProperty(element, property)) {
            return true;
        }
        if (decorator !is null && decorator.isLabelProperty(element, property)) {
            return true;
        }
        return false;
    }

    /**
     * The <code>DecoratingLabelProvider</code> implementation of this <code>IBaseLabelProvider</code> method
     * removes the listener from both the nested label provider and the label decorator.
     *
     * @param listener a label provider listener
     */
    public override void removeListener(ILabelProviderListener listener) {
        super.removeListener(listener);
        provider.removeListener(listener);
        if (decorator !is null) {
            decorator.removeListener(listener);
        }
        listeners.remove(cast(Object)listener);
    }

    /**
     * Sets the label decorator.
     * Removes all known listeners from the old decorator, and adds all known listeners to the new decorator.
     * The old decorator is not disposed.
     * Fires a label provider changed event indicating that all labels should be updated.
     * Has no effect if the given decorator is identical to the current one.
     *
     * @param decorator the label decorator, or <code>null</code> if no decorations are to be applied
     */
    public void setLabelDecorator(ILabelDecorator decorator) {
        ILabelDecorator oldDecorator = this.decorator;
        if (oldDecorator !is decorator) {
            Object[] listenerList = this.listeners.getListeners();
            if (oldDecorator !is null) {
                for (int i = 0; i < listenerList.length; ++i) {
                    oldDecorator
                            .removeListener(cast(ILabelProviderListener) listenerList[i]);
                }
            }
            this.decorator = decorator;
            if (decorator !is null) {
                for (int i = 0; i < listenerList.length; ++i) {
                    decorator
                            .addListener(cast(ILabelProviderListener) listenerList[i]);
                }
            }
            fireLabelProviderChanged(new LabelProviderChangedEvent(this));
        }
    }


    /*
     *  (non-Javadoc)
     * @see org.eclipse.jface.viewers.IViewerLabelProvider#updateLabel(org.eclipse.jface.viewers.ViewerLabel, java.lang.Object)
     */
    public void updateLabel(ViewerLabel settings, Object element) {

        ILabelDecorator currentDecorator = getLabelDecorator();
        String oldText = settings.getText();
        bool decorationReady = true;
        if ( auto delayedDecorator = cast(IDelayedLabelDecorator)currentDecorator ) {
            if (!delayedDecorator.prepareDecoration(element, oldText)) {
                // The decoration is not ready but has been queued for processing
                decorationReady = false;
            }
        }
        // update icon and label

        if (decorationReady || oldText is null
                || settings.getText().length is 0) {
            settings.setText(getText(element));
        }

        Image oldImage = settings.getImage();
        if (decorationReady || oldImage is null) {
            settings.setImage(getImage(element));
        }

        if(decorationReady) {
            updateForDecorationReady(settings,element);
        }

    }

    /**
     * Decoration is ready. Update anything else for the settings.
     * @param settings The object collecting the settings.
     * @param element The Object being decorated.
     * @since 3.1
     */
    protected void updateForDecorationReady(ViewerLabel settings, Object element) {

        if( auto colorDecorator = cast(IColorDecorator) decorator ){
            settings.setBackground(colorDecorator.decorateBackground(element));
            settings.setForeground(colorDecorator.decorateForeground(element));
        }

        if( auto d = cast(IFontDecorator) decorator ) {
            settings.setFont(d.decorateFont(element));
        }

    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.IColorProvider#getBackground(java.lang.Object)
     */
    public Color getBackground(Object element) {
        if( auto p = cast(IColorProvider) provider ) {
            return p.getBackground(element);
        }
        return null;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.IFontProvider#getFont(java.lang.Object)
     */
    public Font getFont(Object element) {
        if(auto p = cast(IFontProvider)provider ) {
            return p.getFont(element);
        }
        return null;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.IColorProvider#getForeground(java.lang.Object)
     */
    public Color getForeground(Object element) {
        if(auto p = cast(IColorProvider)provider ) {
            return p.getForeground(element);
        }
        return null;
    }

    /**
     * Return the decoration context associated with this label provider.
     * It will be passed to the decorator if the decorator is an
     * instance of {@link LabelDecorator}.
     * @return the decoration context associated with this label provider
     *
     * @since 3.2
     */
    public IDecorationContext getDecorationContext() {
        return decorationContext;
    }

    /**
     * Set the decoration context that will be based to the decorator
     * for this label provider if that decorator implements {@link LabelDecorator}.
     * @param decorationContext the decoration context.
     *
     * @since 3.2
     */
    public void setDecorationContext(IDecorationContext decorationContext) {
        Assert.isNotNull(cast(Object)decorationContext);
        this.decorationContext = decorationContext;
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.ITreePathLabelProvider#updateLabel(org.eclipse.jface.viewers.ViewerLabel, org.eclipse.jface.viewers.TreePath)
     */
    public void updateLabel(ViewerLabel settings, TreePath elementPath) {
        ILabelDecorator currentDecorator = getLabelDecorator();
        String oldText = settings.getText();
        Object element = elementPath.getLastSegment();
        bool decorationReady = true;
        if ( auto labelDecorator = cast(LabelDecorator) currentDecorator ) {
           if (!labelDecorator.prepareDecoration(element, oldText, getDecorationContext())) {
                // The decoration is not ready but has been queued for processing
                decorationReady = false;
            }
        } else if ( auto delayedDecorator = cast(IDelayedLabelDecorator) currentDecorator ) {
            if (!delayedDecorator.prepareDecoration(element, oldText)) {
                // The decoration is not ready but has been queued for processing
                decorationReady = false;
            }
        }
        settings.setHasPendingDecorations(!decorationReady);
        // update icon and label

        if ( auto pprov = cast(ITreePathLabelProvider) provider ) {
            if (decorationReady || oldText is null
                    || settings.getText().length is 0) {
                pprov.updateLabel(settings, elementPath);
                decorateSettings(settings, elementPath);
            }
        } else {
            if (decorationReady || oldText is null
                    || settings.getText().length is 0) {
                settings.setText(getText(element));
            }

            Image oldImage = settings.getImage();
            if (decorationReady || oldImage is null) {
                settings.setImage(getImage(element));
            }

            if(decorationReady) {
                updateForDecorationReady(settings,element);
            }
        }

    }

    /**
     * Decorate the settings
     * @param settings the settings obtained from the label provider
     * @param elementPath the element path being decorated
     */
    private void decorateSettings(ViewerLabel settings, TreePath elementPath) {
        Object element = elementPath.getLastSegment();
        if (decorator !is null) {
            if ( auto labelDecorator = cast(LabelDecorator) decorator ) {
                String text = labelDecorator.decorateText(settings.getText(), element, getDecorationContext());
                if (text !is null && text.length > 0)
                    settings.setText(text);
                Image image = labelDecorator.decorateImage(settings.getImage(), element, getDecorationContext());
                if (image !is null)
                    settings.setImage(image);

            } else {
                String text = decorator.decorateText(settings.getText(), element);
                if (text !is null && text.length > 0)
                    settings.setText(text);
                Image image = decorator.decorateImage(settings.getImage(), element);
                if (image !is null)
                    settings.setImage(image);
            }
            if( auto colorDecorator = cast(IColorDecorator) decorator ){
                Color background = colorDecorator.decorateBackground(element);
                if (background !is null)
                    settings.setBackground(background);
                Color foreground = colorDecorator.decorateForeground(element);
                if (foreground !is null)
                    settings.setForeground(foreground);
            }

            if( auto fd = cast(IFontDecorator) decorator ) {
                Font font = fd.decorateFont(element);
                if (font !is null)
                    settings.setFont(font);
            }
        }
    }
}
