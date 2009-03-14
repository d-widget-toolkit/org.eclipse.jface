/*******************************************************************************
 * Copyright (c) 2006 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 ******************************************************************************/

module org.eclipse.jface.internal.provisional.action.CoolBarManager2;

import org.eclipse.jface.action.IContributionItem;
import org.eclipse.jface.internal.provisional.action.ICoolBarManager2;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.CoolBar;
import org.eclipse.jface.action.CoolBarManager;

import java.lang.all;
import java.util.Set;

/**
 * Extends <code>CoolBarManager</code> to implement <code>ICoolBarManager2</code>
 *
 * <p>
 * <strong>EXPERIMENTAL</strong>. This class or interface has been added as
 * part of a work in progress. There is a guarantee neither that this API will
 * work nor that it will remain the same. Please do not use this API without
 * consulting with the Platform/UI team.
 * </p>
 *
 * @since 3.2
*/
public class CoolBarManager2 : CoolBarManager, ICoolBarManager2 {

    // delegate to super
    public override void refresh(){
        super.refresh();
    }
    public override void dispose(){
        super.dispose();
    }
    public override void setItems(IContributionItem[] newItems){
        super.setItems(newItems);
    }
    public override void resetItemOrder(){
        super.resetItemOrder();
    }

    /**
     * Creates a new cool bar manager with the default style. Equivalent to
     * <code>CoolBarManager(SWT.NONE)</code>.
     */
    public this() {
        super();
    }

    /**
     * Creates a cool bar manager for an existing cool bar control. This
     * manager becomes responsible for the control, and will dispose of it when
     * the manager is disposed.
     *
     * @param coolBar
     *            the cool bar control
     */
    public this(CoolBar coolBar) {
        super(coolBar);
    }

    /**
     * Creates a cool bar manager with the given SWT style. Calling <code>createControl</code>
     * will create the cool bar control.
     *
     * @param style
     *            the cool bar item style; see
     *            {@link org.eclipse.swt.widgets.CoolBar CoolBar}for for valid
     *            style bits
     */
    public this(int style) {
       super(style);
    }

    /**
     * Creates and returns this manager's cool bar control. Does not create a
     * new control if one already exists.
     *
     * @param parent
     *            the parent control
     * @return the cool bar control
     * @since 3.2
     */
    public Control createControl2(Composite parent) {
        return createControl(parent);
    }

    /**
     * Returns the control for this manager.
     *
     * @return the control, or <code>null</code> if none
     * @since 3.2
     */
    public Control getControl2() {
        return getControl();
    }

}
