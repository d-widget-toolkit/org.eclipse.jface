/*******************************************************************************
 * Copyright (c) 2008 IBM Corporation and others.
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
module org.eclipse.jface.viewers.DecoratingStyledCellLabelProvider;

import org.eclipse.jface.viewers.DelegatingStyledCellLabelProvider;
import org.eclipse.jface.viewers.ILabelDecorator;
import org.eclipse.jface.viewers.IDecorationContext;
import org.eclipse.jface.viewers.ILabelProviderListener;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.DecorationContext;
import org.eclipse.jface.viewers.LabelProviderChangedEvent;
import org.eclipse.jface.viewers.LabelDecorator;
import org.eclipse.jface.viewers.IDelayedLabelDecorator;
import org.eclipse.jface.viewers.IColorDecorator;
import org.eclipse.jface.viewers.IFontDecorator;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.core.runtime.Assert;
import org.eclipse.jface.viewers.StyledString;

import java.lang.all;
import java.util.Set;

/**
 * A {@link DecoratingStyledCellLabelProvider} is a
 * {@link DelegatingStyledCellLabelProvider} that uses a nested
 * {@link DelegatingStyledCellLabelProvider.IStyledLabelProvider} to compute
 * styled text label and image and takes a {@link ILabelDecorator} to decorate
 * the label.
 *
 * <p>
 * Use this label provider as a replacement for the
 * {@link DecoratingLabelProvider} when decorating styled text labels.
 * </p>
 *
 * <p>
 * The {@link DecoratingStyledCellLabelProvider} will try to evaluate the text
 * decoration added by the {@link ILabelDecorator} and will apply the style
 * returned by {@link #getDecorationStyle(Object)}
 * </p>
 * <p>
 * The {@link ILabelDecorator} can optionally implement {@link IColorDecorator}
 * and {@link IFontDecorator} to provide foreground and background color and
 * font decoration.
 * </p>
 *
 * @since 3.4
 */
public class DecoratingStyledCellLabelProvider :
        DelegatingStyledCellLabelProvider {

    private ILabelDecorator decorator;
    private IDecorationContext decorationContext;
    private ILabelProviderListener labelProviderListener;

    /**
     * Creates a {@link DecoratingStyledCellLabelProvider} that delegates the
     * requests for styled labels and for images to a
     * {@link DelegatingStyledCellLabelProvider.IStyledLabelProvider}.
     *
     * @param labelProvider
     *            the styled label provider
     * @param decorator
     *            a label decorator or <code>null</code> to not decorate the
     *            label
     * @param decorationContext
     *            a decoration context or <code>null</code> if the no
     *            decorator is configured or the default decorator should be
     *            used
     */
    public this(
            IStyledLabelProvider labelProvider, ILabelDecorator decorator,
            IDecorationContext decorationContext) {
        decorationContext= DecorationContext.DEFAULT_CONTEXT;
        super(labelProvider);

        this.decorator = decorator;
        this.decorationContext = decorationContext !is null ? decorationContext
                : DecorationContext.DEFAULT_CONTEXT;

        this.labelProviderListener = new class ILabelProviderListener {
            public void labelProviderChanged(LabelProviderChangedEvent event) {
                fireLabelProviderChanged(event);
            }
        };
        labelProvider.addListener(this.labelProviderListener);
        if (decorator !is null)
            decorator.addListener(this.labelProviderListener);
    }

    /**
     * Returns the decoration context associated with this label provider. It
     * will be passed to the decorator if the decorator is an instance of
     * {@link LabelDecorator}.
     *
     * @return the decoration context associated with this label provider
     */
    public IDecorationContext getDecorationContext() {
        return this.decorationContext;
    }

    /**
     * Set the decoration context that will be based to the decorator for this
     * label provider if that decorator implements {@link LabelDecorator}.
     *
     * @param decorationContext
     *            the decoration context.
     */
    public void setDecorationContext(IDecorationContext decorationContext) {
        Assert.isNotNull(cast(Object)decorationContext);
        this.decorationContext = decorationContext;
    }

    private bool waitForPendingDecoration(ViewerCell cell) {
        if (this.decorator is null)
            return false;

        Object element = cell.getElement();
        String oldText = cell.getText();

        bool isDecorationPending = false;
        if (null !is cast(LabelDecorator)this.decorator ) {
            isDecorationPending = !(cast(LabelDecorator) this.decorator)
                    .prepareDecoration(element, oldText, getDecorationContext());
        } else if (null !is cast(IDelayedLabelDecorator)this.decorator ) {
            isDecorationPending = !(cast(IDelayedLabelDecorator) this.decorator)
                    .prepareDecoration(element, oldText);
        }
        if (isDecorationPending && oldText.length is 0) {
            // item is empty: is shown for the first time: don't wait
            return false;
        }
        return isDecorationPending;
    }

    public void update(ViewerCell cell) {
        if (waitForPendingDecoration(cell)) {
            return; // wait until the decoration is ready
        }
        super.update(cell);
    }

    public Color getForeground(Object element) {
        if (null !is cast(IColorDecorator)this.decorator ) {
            Color foreground = (cast(IColorDecorator) this.decorator)
                    .decorateForeground(element);
            if (foreground !is null)
                return foreground;
        }
        return super.getForeground(element);
    }

    public Color getBackground(Object element) {
        if (null !is cast(IColorDecorator)this.decorator ) {
            Color color = (cast(IColorDecorator) this.decorator)
                    .decorateBackground(element);
            if (color !is null)
                return color;
        }
        return super.getBackground(element);
    }

    public Font getFont(Object element) {
        if (null !is cast(IFontDecorator)this.decorator ) {
            Font font = (cast(IFontDecorator) this.decorator).decorateFont(element);
            if (font !is null)
                return font;
        }
        return super.getFont(element);
    }

    public Image getImage(Object element) {
        Image image = super.getImage(element);
        if (this.decorator is null) {
            return image;
        }
        Image decorated = null;
        if (null !is cast(LabelDecorator)this.decorator ) {
            decorated = (cast(LabelDecorator) this.decorator).decorateImage(image,
                    element, getDecorationContext());
        } else {
            decorated = this.decorator.decorateImage(image, element);
        }
        if (decorated !is null)
            return decorated;

        return image;
    }

    /**
     * Returns the styled text for the label of the given element.
     *
     * @param element
     *            the element for which to provide the styled label text
     * @return the styled text string used to label the element
     */
    protected StyledString getStyledText(Object element) {
        StyledString styledString = super.getStyledText(element);
        if (this.decorator is null) {
            return styledString;
        }

        String label = styledString.getString();
        String decorated;
        if (null !is cast(LabelDecorator)this.decorator ) {
            decorated = (cast(LabelDecorator) this.decorator).decorateText(label,
                    element, getDecorationContext());
        } else {
            decorated = this.decorator.decorateText(label, element);
        }
        if (decorated is null)
            return styledString;

        int originalStart = decorated.indexOf(label);
        if (originalStart is -1) {
            return new StyledString(decorated); // the decorator did
                                                        // something wild
        }

        if (decorated.length is label.length)
            return styledString;

        auto style = getDecorationStyle(element);
        if (originalStart > 0) {
            StyledString newString = new StyledString(decorated
                    .substring(0, originalStart), style);
            newString.append(styledString);
            styledString = newString;
        }
        if (decorated.length > originalStart + label.length) { // decorator
                                                                    // appended
                                                                    // something
            return styledString.append(decorated.substring(originalStart
                    + label.length), style);
        }
        return styledString;
    }

    /**
     * Sets the {@link StyledString.Styler} to be used for string
     * decorations. By default the
     * {@link StyledString#DECORATIONS_STYLER decoration style}. Clients
     * can override.
     *
     * Note that it is the client's responsibility to react on color changes of
     * the decoration color by refreshing the view
     *
     * @param element
     *            the element that has been decorated
     *
     * @return return the decoration style
     */
    protected StyledString.Styler getDecorationStyle(Object element) {
        return StyledString.DECORATIONS_STYLER;
    }

    /**
     * Returns the decorator or <code>null</code> if no decorator is installed
     *
     * @return the decorator or <code>null</code> if no decorator is installed
     */
    public ILabelDecorator getLabelDecorator() {
        return this.decorator;
    }

    /**
     * Sets the label decorator. Removes all known listeners from the old
     * decorator, and adds all known listeners to the new decorator. The old
     * decorator is not disposed. Fires a label provider changed event
     * indicating that all labels should be updated. Has no effect if the given
     * decorator is identical to the current one.
     *
     * @param newDecorator
     *            the label decorator, or <code>null</code> if no decorations
     *            are to be applied
     */
    public void setLabelDecorator(ILabelDecorator newDecorator) {
        ILabelDecorator oldDecorator = this.decorator;
        if (oldDecorator !is newDecorator) {
            if (oldDecorator !is null)
                oldDecorator.removeListener(this.labelProviderListener);
            this.decorator = newDecorator;
            if (newDecorator !is null) {
                newDecorator.addListener(this.labelProviderListener);
            }
        }
        fireLabelProviderChanged(new LabelProviderChangedEvent(this));
    }

    public void addListener(ILabelProviderListener listener) {
        super.addListener(listener);
        if (this.decorator !is null) {
            this.decorator.addListener(this.labelProviderListener);
        }
    }

    public void removeListener(ILabelProviderListener listener) {
        super.removeListener(listener);
        if (this.decorator !is null) {
            this.decorator.removeListener(this.labelProviderListener);
        }
    }

    public bool isLabelProperty(Object element, String property) {
        if (super.isLabelProperty(element, property)) {
            return true;
        }
        return this.decorator !is null
                && this.decorator.isLabelProperty(element, property);
    }

    public void dispose() {
        super.dispose();
        if (this.decorator !is null) {
            this.decorator.removeListener(this.labelProviderListener);
            this.decorator.dispose();
            this.decorator = null;
        }
    }

}
