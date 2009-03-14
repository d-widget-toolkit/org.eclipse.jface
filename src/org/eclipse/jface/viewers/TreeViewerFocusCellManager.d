/*******************************************************************************
 * Copyright (c) 2007, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl<tom.schindl@bestsolution.at> - initial API and implementation
 *                                              - fix in bug: 195908, 210752
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TreeViewerFocusCellManager;

import org.eclipse.jface.viewers.SWTFocusCellManager;
import org.eclipse.jface.viewers.CellNavigationStrategy;
import org.eclipse.jface.viewers.TreeViewer;
import org.eclipse.jface.viewers.FocusCellHighlighter;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ColumnViewer;

import org.eclipse.swt.SWT;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Tree;
import org.eclipse.swt.widgets.TreeItem;

import java.lang.all;
import java.util.Set;

/**
 * This class is responsible to provide the concept of cells for {@link Tree}.
 * This concept is needed to provide features like editor activation with the
 * keyboard
 *
 * @since 3.3
 *
 */
public class TreeViewerFocusCellManager : SWTFocusCellManager {
    private static /+final+/ CellNavigationStrategy TREE_NAVIGATE;
    static this(){
        TREE_NAVIGATE = new class CellNavigationStrategy {
            public void collapse(ColumnViewer viewer, ViewerCell cellToCollapse,
                    Event event) {
                if (cellToCollapse !is null) {
                    (cast(TreeItem) cellToCollapse.getItem()).setExpanded(false);
                }
            }

            public void expand(ColumnViewer viewer, ViewerCell cellToExpand,
                    Event event) {
                if (cellToExpand !is null) {
                    TreeViewer v = cast(TreeViewer) viewer;
                    v.setExpandedState(v.getTreePathFromItem_package(cast(Item)cellToExpand
                            .getItem()), true);
                }
            }

            public bool isCollapseEvent(ColumnViewer viewer,
                    ViewerCell cellToCollapse, Event event) {

            if (cellToCollapse is null) {
                return false;
            }

                return cellToCollapse !is null
                    && (cast(TreeItem) cellToCollapse.getItem()).getExpanded()
                    && event.keyCode is SWT.ARROW_LEFT
                    && isFirstColumnCell(cellToCollapse);
            }

            public bool isExpandEvent(ColumnViewer viewer,
                    ViewerCell cellToExpand, Event event) {

            if (cellToExpand is null) {
                return false;
            }

                return cellToExpand !is null
                    && (cast(TreeItem) cellToExpand.getItem()).getItemCount() > 0
                    && !(cast(TreeItem) cellToExpand.getItem()).getExpanded()
                    && event.keyCode is SWT.ARROW_RIGHT
                    && isFirstColumnCell(cellToExpand);
        }

        private bool isFirstColumnCell(ViewerCell cell) {
            return cell.getViewerRow().getVisualIndex_package(cell.getColumnIndex()) is 0;
        }
        };
    }

    /**
     * Create a new manager using a default navigation strategy:
     * <ul>
     * <li><code>SWT.ARROW_UP</code>: navigate to cell above</li>
     * <li><code>SWT.ARROW_DOWN</code>: navigate to cell below</li>
     * <li><code>SWT.ARROW_RIGHT</code>: on first column (collapses if item
     * is expanded) else navigate to next visible cell on the right</li>
     * <li><code>SWT.ARROW_LEFT</code>: on first column (expands if item is
     * collapsed) else navigate to next visible cell on the left</li>
     * </ul>
     *
     * @param viewer
     *            the viewer the manager is bound to
     * @param focusDrawingDelegate
     *            the delegate responsible to highlight selected cell
     */
    public this(TreeViewer viewer,
            FocusCellHighlighter focusDrawingDelegate) {
        this(viewer, focusDrawingDelegate, TREE_NAVIGATE);
    }

    /**
     * Create a new manager with a custom navigation strategy
     *
     * @param viewer
     *            the viewer the manager is bound to
     * @param focusDrawingDelegate
     *            the delegate responsible to highlight selected cell
     * @param navigationStrategy
     *            the strategy used to navigate the cells
     * @since 3.4
     */
    public this(TreeViewer viewer,
            FocusCellHighlighter focusDrawingDelegate,
            CellNavigationStrategy navigationStrategy) {
        super(viewer, focusDrawingDelegate, navigationStrategy);
    }

    override ViewerCell getInitialFocusCell() {
        Tree tree = cast(Tree) getViewer().getControl();

        if (! tree.isDisposed() && tree.getItemCount() > 0 && ! tree.getItem(0).isDisposed()) {
            return getViewer().getViewerRowFromItem_package(tree.getItem(0)).getCell(0);
        }

        return null;
    }

    public ViewerCell getFocusCell() {
        ViewerCell cell = super.getFocusCell();
        Tree t = cast(Tree) getViewer().getControl();

        // It is possible that the selection has changed under the hood
        if (cell !is null) {
            if (t.getSelection().length is 1
                    && t.getSelection()[0] !is cell.getItem()) {
                setFocusCell(getViewer().getViewerRowFromItem_package(
                        t.getSelection()[0]).getCell(cell.getColumnIndex()));
            }
        }

        return super.getFocusCell();
    }
}
