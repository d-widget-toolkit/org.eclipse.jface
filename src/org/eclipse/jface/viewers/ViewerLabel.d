/*******************************************************************************
 * Copyright (c) 2004, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.shindl@bestsolution.at> - tooltip support
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.viewers.ViewerLabel;

import org.eclipse.swt.graphics.Color;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;

import java.lang.all;
import java.util.Set;

/**
 * The ViewerLabel is the class that is passed to a viewer to handle updates of
 * labels. It keeps track of both original and updates text.
 *
 * @see IViewerLabelProvider
 * @since 3.0
 */
public class ViewerLabel {

    // New values for the receiver. Null if nothing has been set.
    private String newText = null;

    private Image newImage = null;

    private bool imageUpdated = false;

    private bool textUpdated = false;

    private Color background = null;

    private Color foreground = null;

    private Font font = null;

    // The initial values for the receiver.
    private String startText;

    private Image startImage;

    private bool hasPendingDecorations_;

    private String tooltipText;

    private Color tooltipForegroundColor;

    private Color tooltipBackgroundColor;

    private Point tooltipShift;

    /**
     * Create a new instance of the receiver with the supplied initial text and
     * image.
     *
     * @param initialText
     * @param initialImage
     */
    public this(String initialText, Image initialImage) {
        startText = initialText;
        startImage = initialImage;
    }

    /**
     * Get the image for the receiver. If the new image has been set return it,
     * otherwise return the starting image.
     *
     * @return Returns the image.
     */
    public final Image getImage() {
        if (imageUpdated) {
            return newImage;
        }
        return startImage;
    }

    /**
     * Set the image for the receiver.
     *
     * @param image
     *            The image to set.
     */
    public final void setImage(Image image) {
        imageUpdated = true;
        newImage = image;
    }

    /**
     * Get the text for the receiver. If the new text has been set return it,
     * otherwise return the starting text.
     *
     * @return String or <code>null</code> if there was no initial text and
     *         nothing was updated.
     */
    public final String getText() {
        if (textUpdated) {
            return newText;
        }
        return startText;
    }

    /**
     * Set the text for the receiver.
     *
     * @param text
     *            String The label to set. This value should not be
     *            <code>null</code>.
     * @see #hasNewText()
     */
    public final void setText(String text) {
        newText = text;
        textUpdated = true;
    }

    /**
     * Return whether or not the image has been set.
     *
     * @return bool. <code>true</code> if the image has been set to
     *         something new.
     *
     * @since 3.1
     */
    public bool hasNewImage() {

        // If we started with null any change is an update
        if (startImage is null) {
            return newImage !is null;
        }

        if (imageUpdated) {
            return !(startImage.opEquals(newImage));
        }
        return false;
    }

    /**
     * Return whether or not the text has been set.
     *
     * @return bool. <code>true</code> if the text has been set to
     *         something new.
     */
    public bool hasNewText() {

        // If we started with null any change is an update
        if (startText is null) {
            return newText !is null;
        }

        if (textUpdated) {
            return !(startText.equals(newText));
        }

        return false;
    }

    /**
     * Return whether or not the background color has been set.
     *
     * @return bool. <code>true</code> if the value has been set.
     */
    public bool hasNewBackground() {
        return background !is null;
    }

    /**
     * Return whether or not the foreground color has been set.
     *
     * @return bool. <code>true</code> if the value has been set.
     *
     * @since 3.1
     */
    public bool hasNewForeground() {
        return foreground !is null;
    }

    /**
     * Return whether or not the font has been set.
     *
     * @return bool. <code>true</code> if the value has been set.
     *
     * @since 3.1
     */
    public bool hasNewFont() {
        return font !is null;
    }

    /**
     * Get the background Color.
     *
     * @return Color or <code>null</code> if no new value was set.
     *
     * @since 3.1
     */
    public Color getBackground() {
        return background;
    }

    /**
     * Set the background Color.
     *
     * @param background
     *            Color. This value should not be <code>null</code>.
     *
     * @since 3.1
     */
    public void setBackground(Color background) {
        this.background = background;
    }

    /**
     * Get the font.
     *
     * @return Font or <code>null</code> if no new value was set.
     *
     * @since 3.1
     */
    public Font getFont() {
        return font;
    }

    /**
     * Set the font.
     *
     * @param font
     *            Font This value should not be <code>null</code>.
     *
     * @since 3.1
     */
    public void setFont(Font font) {
        this.font = font;
    }

    /**
     * Get the foreground Color.
     *
     * @return Color or <code>null</code> if no new value was set.
     *
     * @since 3.1
     */
    public Color getForeground() {
        return foreground;
    }

    /**
     * Set the foreground Color.
     *
     * @param foreground
     *            Color This value should not be <code>null</code>.
     *
     * @since 3.1
     */
    public void setForeground(Color foreground) {
        this.foreground = foreground;
    }

    /**
     * Set whether or not there are any decorations pending.
     *
     * @param hasPendingDecorations
     */
    void setHasPendingDecorations(bool hasPendingDecorations_) {
        this.hasPendingDecorations_ = hasPendingDecorations_;
    }

    /**
     * @return <code>bool</code>. <code>true</code> if there are any
     *         decorations pending.
     */
    bool hasPendingDecorations() {
        return hasPendingDecorations_;
    }

    /**
     * Returns the tooltipText.
     *
     * @return {@link String} or <code>null</code> if the tool tip text was
     *         never set.
     *
     * @since 3.3
     */
    public String getTooltipText() {
        return tooltipText;
    }

    /**
     * Set the tool tip text.
     *
     * @param tooltipText
     *            The tooltipText {@link String} to set. This value should not
     *            be <code>null</code>.
     *
     * @since 3.3
     */
    public void setTooltipText(String tooltipText) {
        this.tooltipText = tooltipText;
    }

    /**
     * Return whether or not the tool tip text has been set.
     *
     * @return <code>bool</code>. <code>true</code> if the tool tip text
     *         has been set.
     *
     * @since 3.3
     */
    public bool hasNewTooltipText() {
        return this.tooltipText !is null;
    }

    /**
     * Return the tool tip background color.
     *
     * @return {@link Color} or <code>null</code> if the tool tip background
     *         color has not been set.
     *
     * @since 3.3
     */
    public Color getTooltipBackgroundColor() {
        return tooltipBackgroundColor;
    }

    /**
     * Set the background {@link Color} for tool tip.
     *
     * @param tooltipBackgroundColor
     *            The {@link Color} to set. This value should not be
     *            <code>null</code>.
     *
     * @since 3.3
     */
    public void setTooltipBackgroundColor(Color tooltipBackgroundColor) {
        this.tooltipBackgroundColor = tooltipBackgroundColor;
    }

    /**
     * Return whether or not the tool tip background color has been set.
     *
     * @return <code>bool</code>. <code>true</code> if the tool tip text
     *         has been set.
     *
     * @since 3.3
     */
    public bool hasNewTooltipBackgroundColor() {
        return tooltipBackgroundColor !is null;
    }

    /**
     * Return the foreground {@link Color}.
     *
     * @return Returns {@link Color} or <code>null</code> if the tool tip
     *         foreground color has not been set.
     *
     * @since 3.3
     */
    public Color getTooltipForegroundColor() {
        return tooltipForegroundColor;
    }

    /**
     * Set the foreground {@link Color} for tool tip.
     *
     * @param tooltipForegroundColor
     *            The tooltipForegroundColor to set.
     *
     * @since 3.3
     */
    public void setTooltipForegroundColor(Color tooltipForegroundColor) {
        this.tooltipForegroundColor = tooltipForegroundColor;
    }

    /**
     *
     * Return whether or not the tool tip foreground color has been set.
     *
     * @return <code>bool</code>. <code>true</code> if the tool tip foreground
     *         has been set.
     *
     * @since 3.3
     */
    public bool hasNewTooltipForegroundColor() {
        return tooltipForegroundColor !is null;
    }

    /**
     * @return Returns the tooltipShift.
     * @since 3.3
     */
    public Point getTooltipShift() {
        return tooltipShift;
    }

    /**
     * @param tooltipShift
     *            The tooltipShift to set.
     * @since 3.3
     */
    public void setTooltipShift(Point tooltipShift) {
        this.tooltipShift = tooltipShift;
    }

    /**
     * @return Return whether or not the tool tip shift has been set.
     * @since 3.3
     */
    public bool hasTooltipShift() {
        return this.tooltipShift !is null;
    }
}
