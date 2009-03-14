/*******************************************************************************
 * Copyright (c) 2005, 2008 IBM Corporation and others.
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
module org.eclipse.jface.fieldassist.TextContentAdapter;

import org.eclipse.jface.fieldassist.IControlContentAdapter;
import org.eclipse.jface.fieldassist.IControlContentAdapter2;

import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.graphics.Rectangle;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Text;

import java.lang.all;
import java.util.Set;

/**
 * An {@link IControlContentAdapter} for SWT Text controls. This is a
 * convenience class for easily creating a {@link ContentProposalAdapter} for
 * text fields.
 *
 * @since 3.2
 */
public class TextContentAdapter : IControlContentAdapter,
        IControlContentAdapter2 {

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.dialogs.taskassistance.IControlContentAdapter#getControlContents(org.eclipse.swt.widgets.Control)
     */
    public String getControlContents(Control control) {
        return (cast(Text) control).getText();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter#setControlContents(org.eclipse.swt.widgets.Control,
     *      java.lang.String, int)
     */
    public void setControlContents(Control control, String text,
            int cursorPosition) {
        (cast(Text) control).setText(text);
        (cast(Text) control).setSelection(cursorPosition, cursorPosition);
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter#insertControlContents(org.eclipse.swt.widgets.Control,
     *      java.lang.String, int)
     */
    public void insertControlContents(Control control, String text,
            int cursorPosition) {
        Point selection = (cast(Text) control).getSelection();
        (cast(Text) control).insert(text);
        // Insert will leave the cursor at the end of the inserted text. If this
        // is not what we wanted, reset the selection.
        if (cursorPosition < text.length) {
            (cast(Text) control).setSelection(selection.x + cursorPosition,
                    selection.x + cursorPosition);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter#getCursorPosition(org.eclipse.swt.widgets.Control)
     */
    public int getCursorPosition(Control control) {
        return (cast(Text) control).getCaretPosition();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter#getInsertionBounds(org.eclipse.swt.widgets.Control)
     */
    public Rectangle getInsertionBounds(Control control) {
        Text text = cast(Text) control;
        Point caretOrigin = text.getCaretLocation();
        // We fudge the y pixels due to problems with getCaretLocation
        // See https://bugs.eclipse.org/bugs/show_bug.cgi?id=52520
        return new Rectangle(caretOrigin.x + text.getClientArea().x,
                caretOrigin.y + text.getClientArea().y + 3, 1, text.getLineHeight());
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter#setCursorPosition(org.eclipse.swt.widgets.Control,
     *      int)
     */
    public void setCursorPosition(Control control, int position) {
        (cast(Text) control).setSelection(new Point(position, position));
    }

    /**
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter2#getSelection(org.eclipse.swt.widgets.Control)
     *
     * @since 3.4
     */
    public Point getSelection(Control control) {
        return (cast(Text) control).getSelection();
    }

    /**
     * @see org.eclipse.jface.fieldassist.IControlContentAdapter2#setSelection(org.eclipse.swt.widgets.Control,
     *      org.eclipse.swt.graphics.Point)
     *
     * @since 3.4
     */
    public void setSelection(Control control, Point range) {
        (cast(Text) control).setSelection(range);
    }
}
