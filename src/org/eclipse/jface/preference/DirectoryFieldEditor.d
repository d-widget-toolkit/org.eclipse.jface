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
module org.eclipse.jface.preference.DirectoryFieldEditor;

import org.eclipse.jface.preference.StringButtonFieldEditor;
// import java.io.File;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.DirectoryDialog;
import org.eclipse.jface.resource.JFaceResources;

import java.lang.all;
import java.util.Set;
import tango.io.FilePath;
static import tango.io.Path;
import tango.io.FileSystem;

/**
 * A field editor for a directory path type preference. A standard directory
 * dialog appears when the user presses the change button.
 */
public class DirectoryFieldEditor : StringButtonFieldEditor {
    /**
     * Creates a new directory field editor
     */
    protected this() {
    }

    /**
     * Creates a directory field editor.
     *
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param parent the parent of the field editor's control
     */
    public this(String name, String labelText, Composite parent) {
        init(name, labelText);
        setErrorMessage(JFaceResources
                .getString("DirectoryFieldEditor.errorMessage"));//$NON-NLS-1$
        setChangeButtonText(JFaceResources.getString("openBrowse"));//$NON-NLS-1$
        setValidateStrategy(VALIDATE_ON_FOCUS_LOST);
        createControl(parent);
    }

    /* (non-Javadoc)
     * Method declared on StringButtonFieldEditor.
     * Opens the directory chooser dialog and returns the selected directory.
     */
    protected override String changePressed() {
        auto f = new FilePath(tango.io.Path.standard(getTextControl().getText()));
        if (!f.exists()) {
            f = cast(FilePath)null;
        }
        auto d = getDirectory(f);
        if (d is null) {
            return null;
        }

        return FileSystem.toAbsolute( d ).native.toString;
    }

    /* (non-Javadoc)
     * Method declared on StringFieldEditor.
     * Checks whether the text input field contains a valid directory.
     */
    protected override bool doCheckState() {
        String fileName = getTextControl().getText();
        fileName = fileName.trim();
        if (fileName.length is 0 && isEmptyStringAllowed()) {
            return true;
        }
        auto file = new FilePath(tango.io.Path.standard(fileName));
        return file.exists() && file.isFolder();
    }

    /**
     * Helper that opens the directory chooser dialog.
     * @param startingDirectory The directory the dialog will open in.
     * @return File File or <code>null</code>.
     *
     */
    private FilePath getDirectory(FilePath startingDirectory) {

        DirectoryDialog fileDialog = new DirectoryDialog(getShell(), SWT.OPEN);
        if (startingDirectory !is null) {
            fileDialog.setFilterPath(startingDirectory.path);
        }
        String dir = fileDialog.open();
        if (dir !is null) {
            dir = dir.trim();
            if (dir.length > 0) {
                return new FilePath(tango.io.Path.standard(dir));
            }
        }

        return null;
    }
}
