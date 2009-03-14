/*******************************************************************************
 * Copyright (c) 2006, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - initial API and implementation
 *                                               - fix for bug 187817
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.ColumnViewerEditorActivationStrategy;

import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ColumnViewer;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationEvent;
import org.eclipse.jface.viewers.IStructuredSelection;

import org.eclipse.swt.events.KeyEvent;
import org.eclipse.swt.events.KeyListener;
import org.eclipse.swt.events.MouseEvent;

import java.lang.all;
import java.util.Set;

/**
 * This class is responsible to determine if a cell selection event is triggers
 * an editor activation. Implementors can extend and overwrite to implement
 * custom editing behavior
 *
 * @since 3.3
 */
public class ColumnViewerEditorActivationStrategy {
    private ColumnViewer viewer;

    private KeyListener keyboardActivationListener;

    /**
     * @param viewer
     *            the viewer the editor support is attached to
     */
    public this(ColumnViewer viewer) {
        this.viewer = viewer;
    }

    /**
     * @param event
     *            the event triggering the action
     * @return <code>true</code> if this event should open the editor
     */
    protected bool isEditorActivationEvent(
            ColumnViewerEditorActivationEvent event) {
        bool singleSelect = (cast(IStructuredSelection)viewer.getSelection()).size() is 1;
        bool isLeftMouseSelect = event.eventType is ColumnViewerEditorActivationEvent.MOUSE_CLICK_SELECTION && (cast(MouseEvent)event.sourceEvent).button is 1;

        return singleSelect && (isLeftMouseSelect
                || event.eventType is ColumnViewerEditorActivationEvent.PROGRAMMATIC
                || event.eventType is ColumnViewerEditorActivationEvent.TRAVERSAL);
    }
    package bool isEditorActivationEvent_package(ColumnViewerEditorActivationEvent event){
        return isEditorActivationEvent(event);
    }

    /**
     * @return the cell holding the current focus
     */
    private ViewerCell getFocusCell() {
        return viewer.getColumnViewerEditor().getFocusCell();
    }

    /**
     * @return the viewer
     */
    public ColumnViewer getViewer() {
        return viewer;
    }

    /**
     * Enable activation of cell editors by keyboard
     *
     * @param enable
     *            <code>true</code> to enable
     */
    public void setEnableEditorActivationWithKeyboard(bool enable) {
        if (enable) {
            if (keyboardActivationListener is null) {
                keyboardActivationListener = new class KeyListener {

                    public void keyPressed(KeyEvent e) {
                        ViewerCell cell = getFocusCell();

                        if (cell !is null) {
                            viewer
                                    .triggerEditorActivationEvent_package(new ColumnViewerEditorActivationEvent(
                                            cell, e));
                        }
                    }

                    public void keyReleased(KeyEvent e) {

                    }

                };
                viewer.getControl().addKeyListener(keyboardActivationListener);
            }
        } else {
            if (keyboardActivationListener !is null) {
                viewer.getControl().removeKeyListener(
                        keyboardActivationListener);
                keyboardActivationListener = null;
            }
        }
    }

}
