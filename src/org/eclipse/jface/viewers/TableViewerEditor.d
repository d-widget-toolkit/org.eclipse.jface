/*******************************************************************************
 * Copyright (c) 2007, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Schindl <tom.schindl@bestsolution.at> - initial API and implementation
 *                                                 fixes in bug 198665, 200731
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TableViewerEditor;

import org.eclipse.jface.viewers.ColumnViewerEditor;
import org.eclipse.jface.viewers.SWTFocusCellManager;
import org.eclipse.jface.viewers.CellEditor;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationStrategy;
import org.eclipse.jface.viewers.ColumnViewerEditorActivationEvent;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.StructuredSelection;


import org.eclipse.swt.SWT;
import org.eclipse.swt.custom.TableEditor;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableItem;

import java.lang.all;
import java.util.Set;

/**
 * This is an editor-implementation for {@link Table}
 *
 * @since 3.3
 *
 */
public final class TableViewerEditor : ColumnViewerEditor {
    /**
     * This viewer's table editor.
     */
    private TableEditor tableEditor;

    private SWTFocusCellManager focusCellManager;

    /**
     * @param viewer
     *            the viewer the editor is attached to
     * @param focusCellManager
     *            the cell focus manager if one used or <code>null</code>
     * @param editorActivationStrategy
     *            the strategy used to decide about the editor activation
     * @param feature
     *            the feature mask
     */
    this(TableViewer viewer, SWTFocusCellManager focusCellManager,
            ColumnViewerEditorActivationStrategy editorActivationStrategy,
            int feature) {
        super(viewer, editorActivationStrategy, feature);
        tableEditor = new TableEditor(viewer.getTable());
        this.focusCellManager = focusCellManager;
    }

    /**
     * Create a customized editor with focusable cells
     *
     * @param viewer
     *            the viewer the editor is created for
     * @param focusCellManager
     *            the cell focus manager if one needed else <code>null</code>
     * @param editorActivationStrategy
     *            activation strategy to control if an editor activated
     * @param feature
     *            bit mask controlling the editor
     *            <ul>
     *            <li>{@link ColumnViewerEditor#DEFAULT}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_CYCLE_IN_ROW}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_HORIZONTAL}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_MOVE_TO_ROW_NEIGHBOR}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_VERTICAL}</li>
     *            </ul>
     * @see #create(TableViewer, ColumnViewerEditorActivationStrategy, int)
     */
    public static void create(TableViewer viewer,
            SWTFocusCellManager focusCellManager,
            ColumnViewerEditorActivationStrategy editorActivationStrategy,
            int feature) {
        TableViewerEditor editor = new TableViewerEditor(viewer,
                focusCellManager, editorActivationStrategy, feature);
        viewer.setColumnViewerEditor(editor);
        if (focusCellManager !is null) {
            focusCellManager.init();
        }
    }

    /**
     * Create a customized editor whose activation process is customized
     *
     * @param viewer
     *            the viewer the editor is created for
     * @param editorActivationStrategy
     *            activation strategy to control if an editor activated
     * @param feature
     *            bit mask controlling the editor
     *            <ul>
     *            <li>{@link ColumnViewerEditor#DEFAULT}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_CYCLE_IN_ROW}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_HORIZONTAL}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_MOVE_TO_ROW_NEIGHBOR}</li>
     *            <li>{@link ColumnViewerEditor#TABBING_VERTICAL}</li>
     *            </ul>
     */
    public static void create(TableViewer viewer,
            ColumnViewerEditorActivationStrategy editorActivationStrategy,
            int feature) {
        create(viewer, null, editorActivationStrategy, feature);
    }

    protected override void setEditor(Control w, Item item, int columnNumber) {
        tableEditor.setEditor(w, cast(TableItem) item, columnNumber);
    }

    protected override void setLayoutData(LayoutData layoutData) {
        tableEditor.grabHorizontal = layoutData.grabHorizontal;
        tableEditor.horizontalAlignment = layoutData.horizontalAlignment;
        tableEditor.minimumWidth = layoutData.minimumWidth;
        tableEditor.verticalAlignment = layoutData.verticalAlignment;

        if( layoutData.minimumHeight !is SWT.DEFAULT ) {
            tableEditor.minimumHeight = layoutData.minimumHeight;
        }
    }

    public override ViewerCell getFocusCell() {
        if (focusCellManager !is null) {
            return focusCellManager.getFocusCell();
        }

        return super.getFocusCell();
    }

    protected override void updateFocusCell(ViewerCell focusCell,
            ColumnViewerEditorActivationEvent event) {
        // Update the focus cell when we activated the editor with these 2
        // events
        if (event.eventType is ColumnViewerEditorActivationEvent.PROGRAMMATIC
                || event.eventType is ColumnViewerEditorActivationEvent.TRAVERSAL) {

            auto l = getViewer().getSelectionFromWidget_package();

            if (focusCellManager !is null) {
                focusCellManager.setFocusCell(focusCell);
            }

            if (!l.contains(focusCell.getElement())) {
                getViewer().setSelection(
                        new StructuredSelection(focusCell.getElement()),true);
            }
        }
    }
}
