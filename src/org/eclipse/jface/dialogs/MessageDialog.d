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
module org.eclipse.jface.dialogs.MessageDialog;

import org.eclipse.jface.dialogs.IconAndMessageDialog;
import org.eclipse.jface.dialogs.IDialogConstants;

import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.CLabel;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Shell;

import java.lang.all;
import java.util.Set;

/**
 * A dialog for showing messages to the user.
 * <p>
 * This concrete dialog class can be instantiated as is, or further subclassed
 * as required.
 * </p>
 */
public class MessageDialog : IconAndMessageDialog {
    /**
     * Constant for a dialog with no image (value 0).
     */
    public const static int NONE = 0;

    /**
     * Constant for a dialog with an error image (value 1).
     */
    public const static int ERROR = 1;

    /**
     * Constant for a dialog with an info image (value 2).
     */
    public const static int INFORMATION = 2;

    /**
     * Constant for a dialog with a question image (value 3).
     */
    public const static int QUESTION = 3;

    /**
     * Constant for a dialog with a warning image (value 4).
     */
    public const static int WARNING = 4;

    /**
     * Labels for buttons in the button bar (localized strings).
     */
    private String[] buttonLabels;

    /**
     * The buttons. Parallels <code>buttonLabels</code>.
     */
    private Button[] buttons;

    /**
     * Index into <code>buttonLabels</code> of the default button.
     */
    private int defaultButtonIndex;

    /**
     * Dialog title (a localized string).
     */
    private String title;

    /**
     * Dialog title image.
     */
    private Image titleImage;

    /**
     * Image, or <code>null</code> if none.
     */
    private Image image = null;

    /**
     * The custom dialog area.
     */
    private Control customArea;

    /**
     * Create a message dialog. Note that the dialog will have no visual
     * representation (no widgets) until it is told to open.
     * <p>
     * The labels of the buttons to appear in the button bar are supplied in
     * this constructor as an array. The <code>open</code> method will return
     * the index of the label in this array corresponding to the button that was
     * pressed to close the dialog. If the dialog was dismissed without pressing
     * a button (ESC, etc.) then -1 is returned. Note that the <code>open</code>
     * method blocks.
     * </p>
     *
     * @param parentShell
     *            the parent shell
     * @param dialogTitle
     *            the dialog title, or <code>null</code> if none
     * @param dialogTitleImage
     *            the dialog title image, or <code>null</code> if none
     * @param dialogMessage
     *            the dialog message
     * @param dialogImageType
     *            one of the following values:
     *            <ul>
     *            <li><code>MessageDialog.NONE</code> for a dialog with no
     *            image</li>
     *            <li><code>MessageDialog.ERROR</code> for a dialog with an
     *            error image</li>
     *            <li><code>MessageDialog.INFORMATION</code> for a dialog
     *            with an information image</li>
     *            <li><code>MessageDialog.QUESTION </code> for a dialog with a
     *            question image</li>
     *            <li><code>MessageDialog.WARNING</code> for a dialog with a
     *            warning image</li>
     *            </ul>
     * @param dialogButtonLabels
     *            an array of labels for the buttons in the button bar
     * @param defaultIndex
     *            the index in the button label array of the default button
     */
    public this(Shell parentShell, String dialogTitle,
            Image dialogTitleImage, String dialogMessage, int dialogImageType,
            String[] dialogButtonLabels, int defaultIndex) {
        super(parentShell);
        this.title = dialogTitle;
        this.titleImage = dialogTitleImage;
        this.message = dialogMessage;

        switch (dialogImageType) {
        case ERROR: {
            this.image = getErrorImage();
            break;
        }
        case INFORMATION: {
            this.image = getInfoImage();
            break;
        }
        case QUESTION: {
            this.image = getQuestionImage();
            break;
        }
        case WARNING: {
            this.image = getWarningImage();
            break;
        }
        default:
        }
        this.buttonLabels = dialogButtonLabels;
        this.defaultButtonIndex = defaultIndex;
    }

    /*
     *  (non-Javadoc)
     * @see org.eclipse.jface.dialogs.Dialog#buttonPressed(int)
     */
    protected override void buttonPressed(int buttonId) {
        setReturnCode(buttonId);
        close();
    }

    /*
     *  (non-Javadoc)
     * @see org.eclipse.jface.window.Window#configureShell(org.eclipse.swt.widgets.Shell)
     */
    protected override void configureShell(Shell shell) {
        super.configureShell(shell);
        if (title !is null) {
            shell.setText(title);
        }
        if (titleImage !is null) {
            shell.setImage(titleImage);
        }
    }

    /*
     * (non-Javadoc) Method declared on Dialog.
     */
    protected override void createButtonsForButtonBar(Composite parent) {
        buttons = new Button[buttonLabels.length];
        for (int i = 0; i < buttonLabels.length; i++) {
            String label = buttonLabels[i];
            Button button = createButton(parent, i, label,
                    defaultButtonIndex is i);
            buttons[i] = button;
        }
    }

    /**
     * Creates and returns the contents of an area of the dialog which appears
     * below the message and above the button bar.
     * <p>
     * The default implementation of this framework method returns
     * <code>null</code>. Subclasses may override.
     * </p>
     *
     * @param parent
     *            parent composite to contain the custom area
     * @return the custom area control, or <code>null</code>
     */
    protected Control createCustomArea(Composite parent) {
        return null;
    }

    /**
     * This implementation of the <code>Dialog</code> framework method creates
     * and lays out a composite and calls <code>createMessageArea</code> and
     * <code>createCustomArea</code> to populate it. Subclasses should
     * override <code>createCustomArea</code> to add contents below the
     * message.
     */
    protected override Control createDialogArea(Composite parent) {
        // create message area
        createMessageArea(parent);
        // create the top level composite for the dialog area
        Composite composite = new Composite(parent, SWT.NONE);
        GridLayout layout = new GridLayout();
        layout.marginHeight = 0;
        layout.marginWidth = 0;
        composite.setLayout(layout);
        GridData data = new GridData(GridData.FILL_BOTH);
        data.horizontalSpan = 2;
        composite.setLayoutData(data);
        // allow subclasses to add custom controls
        customArea = createCustomArea(composite);
        //If it is null create a dummy label for spacing purposes
        if (customArea is null) {
            customArea = new Label(composite, SWT.NULL);
        }
        return composite;
    }

    /**
     * Gets a button in this dialog's button bar.
     *
     * @param index
     *            the index of the button in the dialog's button bar
     * @return a button in the dialog's button bar
     */
    protected override Button getButton(int index) {
        return buttons[index];
    }

    /**
     * Returns the minimum message area width in pixels This determines the
     * minimum width of the dialog.
     * <p>
     * Subclasses may override.
     * </p>
     *
     * @return the minimum message area width (in pixels)
     */
    protected int getMinimumMessageWidth() {
        return convertHorizontalDLUsToPixels(IDialogConstants.MINIMUM_MESSAGE_AREA_WIDTH);
    }

    /**
     * Handle the shell close. Set the return code to <code>SWT.DEFAULT</code>
     * as there has been no explicit close by the user.
     *
     * @see org.eclipse.jface.window.Window#handleShellCloseEvent()
     */
    protected override void handleShellCloseEvent() {
        //Sets a return code of SWT.DEFAULT since none of the dialog buttons
        // were pressed to close the dialog.
        super.handleShellCloseEvent();
        setReturnCode(SWT.DEFAULT);
    }

    /**
     * Convenience method to open a simple confirm (OK/Cancel) dialog.
     *
     * @param parent
     *            the parent shell of the dialog, or <code>null</code> if none
     * @param title
     *            the dialog's title, or <code>null</code> if none
     * @param message
     *            the message
     * @return <code>true</code> if the user presses the OK button,
     *         <code>false</code> otherwise
     */
    public static bool openConfirm(Shell parent, String title, String message) {
        MessageDialog dialog = new MessageDialog(parent, title, null, // accept
                // the
                // default
                // window
                // icon
                message, QUESTION, [ IDialogConstants.OK_LABEL,
                        IDialogConstants.CANCEL_LABEL ], 0); // OK is the
        // default
        return dialog.open() is 0;
    }

    /**
     * Convenience method to open a standard error dialog.
     *
     * @param parent
     *            the parent shell of the dialog, or <code>null</code> if none
     * @param title
     *            the dialog's title, or <code>null</code> if none
     * @param message
     *            the message
     */
    public static void openError(Shell parent, String title, String message) {
        MessageDialog dialog = new MessageDialog(parent, title, null, // accept
                // the
                // default
                // window
                // icon
                message, ERROR, [ IDialogConstants.OK_LABEL ], 0); // ok
        // is
        // the
        // default
        dialog.open();
        return;
    }

    /**
     * Convenience method to open a standard information dialog.
     *
     * @param parent
     *            the parent shell of the dialog, or <code>null</code> if none
     * @param title
     *            the dialog's title, or <code>null</code> if none
     * @param message
     *            the message
     */
    public static void openInformation(Shell parent, String title,
            String message) {
        MessageDialog dialog = new MessageDialog(parent, title, null, // accept
                // the
                // default
                // window
                // icon
                message, INFORMATION,
                [ IDialogConstants.OK_LABEL ], 0);
        // ok is the default
        dialog.open();
        return;
    }

    /**
     * Convenience method to open a simple Yes/No question dialog.
     *
     * @param parent
     *            the parent shell of the dialog, or <code>null</code> if none
     * @param title
     *            the dialog's title, or <code>null</code> if none
     * @param message
     *            the message
     * @return <code>true</code> if the user presses the OK button,
     *         <code>false</code> otherwise
     */
    public static bool openQuestion(Shell parent, String title,
            String message) {
        MessageDialog dialog = new MessageDialog(parent, title, null, // accept
                // the
                // default
                // window
                // icon
                message, QUESTION, [ IDialogConstants.YES_LABEL,
                        IDialogConstants.NO_LABEL ], 0); // yes is the default
        return dialog.open() is 0;
    }

    /**
     * Convenience method to open a standard warning dialog.
     *
     * @param parent
     *            the parent shell of the dialog, or <code>null</code> if none
     * @param title
     *            the dialog's title, or <code>null</code> if none
     * @param message
     *            the message
     */
    public static void openWarning(Shell parent, String title, String message) {
        MessageDialog dialog = new MessageDialog(parent, title, null, // accept
                // the
                // default
                // window
                // icon
                message, WARNING, [ IDialogConstants.OK_LABEL ], 0); // ok
        // is
        // the
        // default
        dialog.open();
        return;
    }

    /*
     * @see org.eclipse.jface.dialogs.Dialog#createButton(org.eclipse.swt.widgets.Composite,
     *      int, java.lang.String, bool)
     */
    protected override Button createButton(Composite parent, int id, String label,
            bool defaultButton) {
        Button button = super.createButton(parent, id, label, defaultButton);
        //Be sure to set the focus if the custom area cannot so as not
        //to lose the defaultButton.
        if (defaultButton && !customShouldTakeFocus()) {
            button.setFocus();
        }
        return button;
    }

    /**
     * Return whether or not we should apply the workaround where we take focus
     * for the default button or if that should be determined by the dialog. By
     * default only return true if the custom area is a label or CLabel that
     * cannot take focus.
     *
     * @return bool
     */
    protected bool customShouldTakeFocus() {
        if (cast(Label) customArea ) {
            return false;
        }
        if (cast(CLabel) customArea ) {
            return (customArea.getStyle() & SWT.NO_FOCUS) > 0;
        }
        return true;
    }

    /*
     *  (non-Javadoc)
     * @see org.eclipse.jface.dialogs.IconAndMessageDialog#getImage()
     */
    public override Image getImage() {
        return image;
    }

    /**
     * An accessor for the labels to use on the buttons.
     *
     * @return The button labels to used; never <code>null</code>.
     */
    protected String[] getButtonLabels() {
        return buttonLabels;
    }

    /**
     * An accessor for the index of the default button in the button array.
     *
     * @return The default button index.
     */
    protected int getDefaultButtonIndex() {
        return defaultButtonIndex;
    }

    /**
     * A mutator for the array of buttons in the button bar.
     *
     * @param buttons
     *            The buttons in the button bar; must not be <code>null</code>.
     */
    protected void setButtons(Button[] buttons) {
        if (buttons is null) {
            throw new NullPointerException(
                    "The array of buttons cannot be null.");} //$NON-NLS-1$
        this.buttons = buttons;
    }

    /**
     * A mutator for the button labels.
     *
     * @param buttonLabels
     *            The button labels to use; must not be <code>null</code>.
     */
    protected void setButtonLabels(String[] buttonLabels) {
        if (buttonLabels is null) {
            throw new NullPointerException(
                    "The array of button labels cannot be null.");} //$NON-NLS-1$
        this.buttonLabels = buttonLabels;
    }
}
