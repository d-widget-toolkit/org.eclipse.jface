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

module org.eclipse.jface.internal.provisional.action.ToolBarContributionItem2;

import org.eclipse.jface.internal.provisional.action.IToolBarContributionItem;
import org.eclipse.jface.action.IToolBarManager;
import org.eclipse.jface.action.IContributionManager;

import org.eclipse.jface.action.IToolBarManager;
import org.eclipse.jface.action.ToolBarContributionItem;

import java.lang.all;
import java.util.Set;

/**
 * Extends <code>ToolBarContributionItem</code> to implement <code>IToolBarContributionItem</code>.
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
public class ToolBarContributionItem2 : ToolBarContributionItem,
        IToolBarContributionItem {

    // delegate to super
    public override int getCurrentHeight(){
        return super.getCurrentHeight();
    }
    public override int getCurrentWidth(){
        return super.getCurrentWidth();
    }
    public override int getMinimumItemsToShow(){
        return super.getMinimumItemsToShow();
    }
    public override bool getUseChevron(){
        return super.getUseChevron();
    }
    public override void setCurrentHeight(int currentHeight){
        super.setCurrentHeight(currentHeight);
    }
    public override void setCurrentWidth(int currentWidth){
        super.setCurrentWidth(currentWidth);
    }
    public override void setMinimumItemsToShow(int minimumItemsToShow){
        super.setMinimumItemsToShow(minimumItemsToShow);
    }
    public override void setUseChevron(bool value){
        super.setUseChevron(value);
    }
    public override IToolBarManager getToolBarManager(){
        return super.getToolBarManager();
    }
    public override IContributionManager getParent(){
        return super.getParent();
    }


    /**
     *
     */
    public this() {
        super();
    }

    /**
     * @param toolBarManager
     */
    public this(IToolBarManager toolBarManager) {
        super(toolBarManager);
    }

    /**
     * @param toolBarManager
     * @param id
     */
    public this(IToolBarManager toolBarManager, String id) {
        super(toolBarManager, id);
    }

}
