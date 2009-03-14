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
module org.eclipse.jface.preference.PathEditor;

import org.eclipse.jface.preference.ListEditor;

import tango.io.FilePath;
static import tango.io.Path;
import tango.io.model.IFile;

// import java.util.ArrayList;
// import java.util.StringTokenizer;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.DirectoryDialog;

import java.lang.all;
import java.util.ArrayList;
import java.util.Set;
import tango.text.Util;

/**
 * A field editor to edit directory paths.
 */
public class PathEditor : ListEditor {

    /**
     * The last path, or <code>null</code> if none.
     */
    private String lastPath;

    /**
     * The special label text for directory chooser,
     * or <code>null</code> if none.
     */
    private String dirChooserLabelText;

    /**
     * Creates a new path field editor
     */
    protected this() {
    }

    /**
     * Creates a path field editor.
     *
     * @param name the name of the preference this field editor works on
     * @param labelText the label text of the field editor
     * @param dirChooserLabelText the label text displayed for the directory chooser
     * @param parent the parent of the field editor's control
     */
    public this(String name, String labelText,
            String dirChooserLabelText, Composite parent) {
        init(name, labelText);
        this.dirChooserLabelText = dirChooserLabelText;
        createControl(parent);
    }

    /* (non-Javadoc)
     * Method declared on ListEditor.
     * Creates a single string from the given array by separating each
     * string with the appropriate OS-specific path separator.
     */
    protected override String createList(String[] items) {
        StringBuffer path = new StringBuffer("");//$NON-NLS-1$

        for (int i = 0; i < items.length; i++) {
            path.append(items[i]);
            path.append(FileConst.SystemPathString);
        }
        return path.toString();
    }

    /* (non-Javadoc)
     * Method declared on ListEditor.
     * Creates a new path element by means of a directory dialog.
     */
    protected override String getNewInputObject() {

        DirectoryDialog dialog = new DirectoryDialog(getShell());
        if (dirChooserLabelText !is null) {
            dialog.setMessage(dirChooserLabelText);
        }
        if (lastPath !is null) {
            if ((new FilePath(tango.io.Path.standard(lastPath))).exists()) {
                dialog.setFilterPath(lastPath);
            }
        }
        String dir = dialog.open();
        if (dir !is null) {
            dir = java.lang.all.trim(dir);
            if (dir.length is 0) {
                return null;
            }
            lastPath = dir;
        }
        return dir;
    }

    /* (non-Javadoc)
     * Method declared on ListEditor.
     */
    protected override String[] parseString(String stringList) {
        return tango.text.Util.delimit(stringList.dup, FileConst.SystemPathString
                ~ "\n\r");//$NON-NLS-1$
    }
}
