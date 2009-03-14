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
module org.eclipse.jface.preference.FileFieldEditor;

import org.eclipse.jface.preference.StringButtonFieldEditor;
// import java.io.File;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.FileDialog;
import org.eclipse.jface.resource.JFaceResources;

import java.lang.all;
import java.util.List;
import java.util.Set;
import tango.io.FilePath;
static import tango.io.Path;
import tango.io.FileSystem;

/**
 * A field editor for a file path type preference. A standard file
 * dialog appears when the user presses the change button.
 */
public class FileFieldEditor : StringButtonFieldEditor {

    /**
     * List of legal file extension suffixes, or <code>null</code>
     * for system defaults.
     */
    private String[] extensions = null;

    /**
     * Indicates whether the path must be absolute;
     * <code>false</code> by default.
     */
    private bool enforceAbsolute = false;

    /**
     * Creates a new file field editor
     */
    protected this() {
    }

    /**
     * Creates a file field editor.
     *
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param parent the parent of the field editor's control
     */
    public this(String name, String labelText, Composite parent) {
        this(name, labelText, false, parent);
    }
    
    /**
     * Creates a file field editor.
     *
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param enforceAbsolute <code>true</code> if the file path
     *  must be absolute, and <code>false</code> otherwise
     * @param parent the parent of the field editor's control
     */
    public this(String name, String labelText, bool enforceAbsolute, Composite parent) {
        this(name, labelText, enforceAbsolute, VALIDATE_ON_FOCUS_LOST, parent);
    }
    /**
     * Creates a file field editor.
     * 
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param enforceAbsolute <code>true</code> if the file path
     *  must be absolute, and <code>false</code> otherwise
     * @param validationStrategy either {@link StringButtonFieldEditor#VALIDATE_ON_KEY_STROKE}
     *  to perform on the fly checking, or {@link StringButtonFieldEditor#VALIDATE_ON_FOCUS_LOST}
     *  (the default) to perform validation only after the text has been typed in
     * @param parent the parent of the field editor's control.
     * @since 3.4
     * @see StringButtonFieldEditor#VALIDATE_ON_KEY_STROKE
     * @see StringButtonFieldEditor#VALIDATE_ON_FOCUS_LOST
     */
    public this(String name, String labelText,
            bool enforceAbsolute, int validationStrategy, Composite parent) {
        init(name, labelText);
        this.enforceAbsolute = enforceAbsolute;
        setErrorMessage(JFaceResources
                .getString("FileFieldEditor.errorMessage"));//$NON-NLS-1$
        setChangeButtonText(JFaceResources.getString("openBrowse"));//$NON-NLS-1$
        setValidateStrategy(validationStrategy);
        createControl(parent);
    }

    /* (non-Javadoc)
     * Method declared on StringButtonFieldEditor.
     * Opens the file chooser dialog and returns the selected file.
     */
    protected override String changePressed() {
        auto f = new FilePath(tango.io.Path.standard(getTextControl().getText()));
        if (!f.exists()) {
            f = cast(FilePath)null;
        }
        auto d = getFile(f);
        if (d is null) {
            return null;
        }

        return FileSystem.toAbsolute( d ).native.toString();
    }

    /* (non-Javadoc)
     * Method declared on StringFieldEditor.
     * Checks whether the text input field specifies an existing file.
     */
    protected override bool checkState() {

        String msg = null;

        String path = getTextControl().getText();
        if (path !is null) {
            path = path.trim();
        } else {
            path = "";//$NON-NLS-1$
        }
        if (path.length is 0) {
            if (!isEmptyStringAllowed()) {
                msg = getErrorMessage();
            }
        } else {
            auto file = new FilePath(tango.io.Path.standard(path));
            if (/+file.isFile()+/ file.exists && !file.isFolder ) {
                if (enforceAbsolute && !file.isAbsolute()) {
                    msg = JFaceResources
                            .getString("FileFieldEditor.errorMessage2");//$NON-NLS-1$
                }
            } else {
                msg = getErrorMessage();
            }
        }

        if (msg !is null) { // error
            showErrorMessage(msg);
            return false;
        }

        // OK!
        clearErrorMessage();
        return true;
    }

    /**
     * Helper to open the file chooser dialog.
     * @param startingDirectory the directory to open the dialog on.
     * @return File The File the user selected or <code>null</code> if they
     * do not.
     */
    private FilePath getFile(FilePath startingDirectory) {

        FileDialog dialog = new FileDialog(getShell(), SWT.OPEN);
        if (startingDirectory !is null) {
            dialog.setFileName(startingDirectory.path());
        }
        if (extensions !is null) {
            dialog.setFilterExtensions(extensions);
        }
        String file = dialog.open();
        if (file !is null) {
            file = file.trim();
            if (file.length > 0) {
                return new FilePath(tango.io.Path.standard(file));
            }
        }

        return null;
    }

    /**
     * Sets this file field editor's file extension filter.
     *
     * @param extensions a list of file extension, or <code>null</code>
     * to set the filter to the system's default value
     */
    public void setFileExtensions(String[] extensions) {
        this.extensions = extensions;
    }
}
