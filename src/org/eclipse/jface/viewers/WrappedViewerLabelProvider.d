/*******************************************************************************
 * Copyright (c) 2006, 2007 IBM Corporation and others.
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

module org.eclipse.jface.viewers.WrappedViewerLabelProvider;

import org.eclipse.jface.viewers.ColumnLabelProvider;
import org.eclipse.jface.viewers.ILabelProvider;
import org.eclipse.jface.viewers.IColorProvider;
import org.eclipse.jface.viewers.IFontProvider;
import org.eclipse.jface.viewers.IViewerLabelProvider;
import org.eclipse.jface.viewers.ITreePathLabelProvider;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ViewerLabel;
import org.eclipse.jface.viewers.LabelProvider;
import org.eclipse.jface.viewers.TreePath;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.Set;

/**
 * The WrappedViewerLabelProvider is a label provider that allows
 * {@link ILabelProvider}, {@link IColorProvider} and {@link IFontProvider} to
 * be mapped to a ColumnLabelProvider.
 *
 * @since 3.3
 *
 */
class WrappedViewerLabelProvider : ColumnLabelProvider {

    private static ILabelProvider defaultLabelProvider;

    static this(){
        defaultLabelProvider = new LabelProvider();
    }

    private ILabelProvider labelProvider;

    private IColorProvider colorProvider;

    private IFontProvider fontProvider;

    private IViewerLabelProvider viewerLabelProvider;

    private ITreePathLabelProvider treePathLabelProvider;

    /**
     * Create a new instance of the receiver based on labelProvider.
     *
     * @param labelProvider
     */
    public this(IBaseLabelProvider labelProvider) {
        this.labelProvider = defaultLabelProvider;
        super();
        setProviders(cast(Object)labelProvider);
    }

    /**
     * Set the any providers for the receiver that can be adapted from provider.
     *
     * @param provider
     *            {@link Object}
     */
    public void setProviders(Object provider) {
        if ( auto c = cast(ITreePathLabelProvider)provider )
            treePathLabelProvider = c;

        if ( auto c = cast(IViewerLabelProvider)provider )
            viewerLabelProvider = c;

        if ( auto c = cast(ILabelProvider)provider )
            labelProvider = c;

        if ( auto c = cast(IColorProvider)provider )
            colorProvider = c;

        if ( auto c = cast(IFontProvider)provider )
            fontProvider = c;

    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.IFontProvider#getFont(java.lang.Object)
     */
    public override Font getFont(Object element) {
        if (fontProvider is null) {
            return null;
        }

        return fontProvider.getFont(element);

    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.IColorProvider#getBackground(java.lang.Object)
     */
    public override Color getBackground(Object element) {
        if (colorProvider is null) {
            return null;
        }

        return colorProvider.getBackground(element);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ILabelProvider#getText(java.lang.Object)
     */
    public override String getText(Object element) {
        return getLabelProvider().getText(element);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.ILabelProvider#getImage(java.lang.Object)
     */
    public override Image getImage(Object element) {
        return getLabelProvider().getImage(element);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.viewers.IColorProvider#getForeground(java.lang.Object)
     */
    public override Color getForeground(Object element) {
        if (colorProvider is null) {
            return null;
        }

        return colorProvider.getForeground(element);
    }

    /**
     * Get the label provider
     *
     * @return {@link ILabelProvider}
     */
    ILabelProvider getLabelProvider() {
        return labelProvider;
    }

    /**
     * Get the color provider
     *
     * @return {@link IColorProvider}
     */
    IColorProvider getColorProvider() {
        return colorProvider;
    }

    /**
     * Get the font provider
     *
     * @return {@link IFontProvider}.
     */
    IFontProvider getFontProvider() {
        return fontProvider;
    }

    public override void update(ViewerCell cell) {
        Object element = cell.getElement();
        if(viewerLabelProvider is null && treePathLabelProvider is null){
            // inlined super implementation with performance optimizations
            cell.setText(getText(element));
            Image image = getImage(element);
            cell.setImage(image);
            if (colorProvider !is null) {
                cell.setBackground(getBackground(element));
                cell.setForeground(getForeground(element));
            }
            if (fontProvider !is null) {
                cell.setFont(getFont(element));
            }
            return;
        }

        ViewerLabel label = new ViewerLabel(cell.getText(), cell.getImage());

        if (treePathLabelProvider !is null) {
            TreePath treePath = cell.getViewerRow().getTreePath();

            Assert.isNotNull(treePath);
            treePathLabelProvider.updateLabel(label, treePath);
        } else if (viewerLabelProvider !is null) {
            viewerLabelProvider.updateLabel(label, element);
        }
        if (!label.hasNewForeground() && colorProvider !is null)
            label.setForeground(getForeground(element));

        if (!label.hasNewBackground() && colorProvider !is null)
            label.setBackground(getBackground(element));

        if (!label.hasNewFont() && fontProvider !is null)
            label.setFont(getFont(element));

        applyViewerLabel(cell, label);
    }

    private void applyViewerLabel(ViewerCell cell, ViewerLabel label) {
        if (label.hasNewText()) {
            cell.setText(label.getText());
        }
        if (label.hasNewImage()) {
            cell.setImage(label.getImage());
        }
        if (colorProvider !is null || label.hasNewBackground()) {
            cell.setBackground(label.getBackground());
        }
        if (colorProvider !is null || label.hasNewForeground()) {
            cell.setForeground(label.getForeground());
        }
        if (fontProvider !is null || label.hasNewFont()) {
            cell.setFont(label.getFont());
        }
    }
}
