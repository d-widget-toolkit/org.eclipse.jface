/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Stefan Xenos, IBM - bug 156790: Adopt GridLayoutFactory within JFace
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.dialogs.IconAndMessageDialog;

import org.eclipse.jface.dialogs.Dialog;
import org.eclipse.jface.dialogs.IDialogConstants;

import org.eclipse.swt.SWT;
import org.eclipse.swt.accessibility.AccessibleAdapter;
import org.eclipse.swt.accessibility.AccessibleEvent;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;
import org.eclipse.jface.layout.GridDataFactory;
import org.eclipse.jface.layout.GridLayoutFactory;
import org.eclipse.jface.layout.LayoutConstants;
import org.eclipse.jface.resource.JFaceResources;

import java.lang.all;
import java.util.Set;

/**
 * The IconAndMessageDialog is the abstract superclass of dialogs that have an
 * icon and a message as the first two widgets. In this dialog the icon and
 * message are direct children of the shell in order that they can be read by
 * accessibility tools more easily.
 */
public abstract class IconAndMessageDialog : Dialog {
    /**
     * Message (a localized string).
     */
    protected String message;

    /**
     * Message label is the label the message is shown on.
     */
    protected Label messageLabel;

    /**
     * Return the label for the image.
     */
    protected Label imageLabel;

    /**
     * Constructor for IconAndMessageDialog.
     *
     * @param parentShell
     *            the parent shell, or <code>null</code> to create a top-level
     *            shell
     */
    public this(Shell parentShell) {
        super(parentShell);
    }

    /**
     * Create the area the message will be shown in.
     * <p>
     * The parent composite is assumed to use GridLayout as its layout manager,
     * since the parent is typically the composite created in
     * {@link Dialog#createDialogArea}.
     * </p>
     * 
     * @param composite
     *            The composite to parent from.
     * @return Control
     */
    protected Control createMessageArea(Composite composite) {
        // create composite
        // create image
        Image image = getImage();
        if (image !is null) {
            imageLabel = new Label(composite, SWT.NULL);
            image.setBackground(imageLabel.getBackground());
            imageLabel.setImage(image);
            addAccessibleListeners(imageLabel, image);
            GridDataFactory.fillDefaults().align_(SWT.CENTER, SWT.BEGINNING)
                    .applyTo(imageLabel);
        }
        // create message
        if (message !is null) {
            messageLabel = new Label(composite, getMessageLabelStyle());
            messageLabel.setText(message);
            GridDataFactory
                    .fillDefaults()
                    .align_(SWT.FILL, SWT.BEGINNING)
                    .grab(true, false)
                    .hint(
                            convertHorizontalDLUsToPixels(IDialogConstants.MINIMUM_MESSAGE_AREA_WIDTH),
                            SWT.DEFAULT).applyTo(messageLabel);
        }
        return composite;
    }

    private String getAccessibleMessageFor(Image image) {
        if (image.opEquals(getErrorImage())) {
            return JFaceResources.getString("error");//$NON-NLS-1$
        }

        if (image.opEquals(getWarningImage())) {
            return JFaceResources.getString("warning");//$NON-NLS-1$
        }

        if (image.opEquals(getInfoImage())) {
            return JFaceResources.getString("info");//$NON-NLS-1$
        }

        if (image.opEquals(getQuestionImage())) {
            return JFaceResources.getString("question"); //$NON-NLS-1$
        }

        return null;
    }

    /**
     * Add an accessible listener to the label if it can be inferred from the
     * image.
     *
     * @param label
     * @param image
     */
    private void addAccessibleListeners(Label label, Image image) {
        label.getAccessible().addAccessibleListener(new class(image) AccessibleAdapter {
            Image image_;
            this(Image i){
                image_ = i;
            }
            public void getName(AccessibleEvent event) {
                String accessibleMessage = getAccessibleMessageFor(image_);
                if (accessibleMessage is null) {
                    return;
                }
                event.result = accessibleMessage;
            }
        });
    }

    /**
     * Returns the style for the message label.
     *
     * @return the style for the message label
     *
     * @since 3.0
     */
    protected int getMessageLabelStyle() {
        return SWT.WRAP;
    }

    /*
     * @see Dialog.createButtonBar()
     */
    protected override Control createButtonBar(Composite parent) {
        Composite composite = new Composite(parent, SWT.NONE);
        GridLayoutFactory.fillDefaults().numColumns(0) // this is incremented
                // by createButton
                .equalWidth(true).applyTo(composite);

        GridDataFactory.fillDefaults().align_(SWT.END, SWT.CENTER).span(2, 1)
                .applyTo(composite);
        composite.setFont(parent.getFont());
        // Add the buttons to the button bar.
        createButtonsForButtonBar(composite);
        return composite;
    }

    /**
     * Returns the image to display beside the message in this dialog.
     * <p>
     * Subclasses may override.
     * </p>
     *
     * @return the image to display beside the message
     * @since 2.0
     */
    protected abstract Image getImage();

    /*
     * @see Dialog.createContents(Composite)
     */
    protected override Control createContents(Composite parent) {
        // initialize the dialog units
        initializeDialogUnits(parent);
        Point defaultSpacing = LayoutConstants.getSpacing();
        GridLayoutFactory.fillDefaults().margins(LayoutConstants.getMargins())
                .spacing(defaultSpacing.x * 2,
                defaultSpacing.y).numColumns(getColumnCount()).applyTo(parent);

        GridDataFactory.fillDefaults().grab(true, true).applyTo(parent);
        createDialogAndButtonArea(parent);
        return parent;
    }

    /**
     * Get the number of columns in the layout of the Shell of the dialog.
     *
     * @return int
     * @since 3.3
     */
    int getColumnCount() {
        return 2;
    }

    /**
     * Create the dialog area and the button bar for the receiver.
     *
     * @param parent
     */
    protected void createDialogAndButtonArea(Composite parent) {
        // create the dialog area and button bar
        dialogArea = createDialogArea(parent);
        buttonBar = createButtonBar(parent);
        // Apply to the parent so that the message gets it too.
        applyDialogFont(parent);
    }

    /**
     * Return the <code>Image</code> to be used when displaying an error.
     *
     * @return image the error image
     */
    public Image getErrorImage() {
        return getSWTImage(SWT.ICON_ERROR);
    }

    /**
     * Return the <code>Image</code> to be used when displaying a warning.
     *
     * @return image the warning image
     */
    public Image getWarningImage() {
        return getSWTImage(SWT.ICON_WARNING);
    }

    /**
     * Return the <code>Image</code> to be used when displaying information.
     *
     * @return image the information image
     */
    public Image getInfoImage() {
        return getSWTImage(SWT.ICON_INFORMATION);
    }

    /**
     * Return the <code>Image</code> to be used when displaying a question.
     *
     * @return image the question image
     */
    public Image getQuestionImage() {
        return getSWTImage(SWT.ICON_QUESTION);
    }

    /**
     * Get an <code>Image</code> from the provide SWT image constant.
     *
     * @param imageID
     *            the SWT image constant
     * @return image the image
     */
    private Image getSWTImage(int imageID) {
        Shell shell = getShell();
        Display display;
        if (shell is null) {
            shell = getParentShell();
        }
        if (shell is null) {
            display = Display.getCurrent();
        } else {
            display = shell.getDisplay();
        }

        Image[1] image;
        display.syncExec(new class(display,imageID) Runnable {
            int imageID_;
            Display display_;
            this(Display a,int b){
                display_=a;
                imageID_=b;
            }
            public void run() {
                image[0] = display_.getSystemImage(imageID_);
            }
        });

        return image[0];

    }

}
