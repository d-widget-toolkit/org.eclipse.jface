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
module org.eclipse.jface.dialogs.ControlEnableState;


import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;

import java.lang.all;
import java.util.List;
import java.util.ArrayList;
import java.util.Set;

/**
 * Helper class to save the enable/disable state of a control including all its
 * descendent controls.
 */
public class ControlEnableState {
    /**
     * List of exception controls (element type: <code>Control</code>);
     * <code>null</code> if none.
     */
    private List exceptions = null;

    /**
     * List of saved states (element type: <code>ItemState</code>).
     */
    private List states;

    /**
     * Internal class for recording the enable/disable state of a single
     * control.
     */
    private class ItemState {
        /** the control */
        protected Control item;

        /** the state */
        protected bool state;

        /**
         * Create a new instance of the receiver.
         *
         * @param item
         * @param state
         */
        public this(Control item, bool state) {
            this.item = item;
            this.state = state;
        }

        /**
         * Restore the enabled state to the original value.
         *
         */
        public void restore() {
            if (item is null || item.isDisposed()) {
                return;
            }
            item.setEnabled(state);
        }
    }

    /**
     * Creates a new object and saves in it the current enable/disable state of
     * the given control and its descendents; the controls that are saved are
     * also disabled.
     *
     * @param w
     *            the control
     */
    protected this(Control w) {
        this(w, null);
    }

    /**
     * Creates a new object and saves in it the current enable/disable state of
     * the given control and its descendents except for the given list of
     * exception cases; the controls that are saved are also disabled.
     *
     * @param w
     *            the control
     * @param exceptions
     *            the list of controls to not disable (element type:
     *            <code>Control</code>), or <code>null</code> if none
     */
    protected this(Control w, List exceptions) {
//         super();
        states = new ArrayList();
        this.exceptions = exceptions;
        readStateForAndDisable(w);
    }

    /**
     * Saves the current enable/disable state of the given control and its
     * descendents in the returned object; the controls are all disabled.
     *
     * @param w
     *            the control
     * @return an object capturing the enable/disable state
     */
    public static ControlEnableState disable(Control w) {
        return new ControlEnableState(w);
    }

    /**
     * Saves the current enable/disable state of the given control and its
     * descendents in the returned object except for the given list of exception
     * cases; the controls that are saved are also disabled.
     *
     * @param w
     *            the control
     * @param exceptions
     *            the list of controls to not disable (element type:
     *            <code>Control</code>)
     * @return an object capturing the enable/disable state
     */
    public static ControlEnableState disable(Control w, List exceptions) {
        return new ControlEnableState(w, exceptions);
    }

    /**
     * Recursively reads the enable/disable state for the given window and
     * disables all controls.
     * @param control Control
     */
    private void readStateForAndDisable(Control control) {
        if ((exceptions !is null && exceptions.contains(control))) {
            return;
        }
        if (auto c = cast(Composite)control ) {
            Control[] children = c.getChildren();
            for (int i = 0; i < children.length; i++) {
                readStateForAndDisable(children[i]);
            }
        }
        // XXX: Workaround for 1G2Q8SS: ITPUI:Linux - Combo box is not enabled
        // in "File->New->Solution"
        states.add(new ItemState(control, control.getEnabled()));
        control.setEnabled(false);
    }

    /**
     * Restores the window enable state saved in this object.
     */
    public void restore() {
        int size = states.size();
        for (int i = 0; i < size; i++) {
            (cast(ItemState) states.get(i)).restore();
        }
    }
}
