/*******************************************************************************
 * Copyright (c) 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Tom Schindl <tom.schindl@bestsolution.at> - initial API and implementation
 *                                               - fix for bug 178280
 *     IBM Corporation - API refactoring and general maintenance
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.layout.TableColumnLayout;

import java.lang.all;

import org.eclipse.jface.layout.AbstractColumnLayout;

import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Layout;
import org.eclipse.swt.widgets.Scrollable;
import org.eclipse.swt.widgets.Table;
import org.eclipse.swt.widgets.TableColumn;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.jface.viewers.ColumnLayoutData;
import org.eclipse.jface.viewers.ColumnPixelData;

/**
 * The TableColumnLayout is the {@link Layout} used to maintain
 * {@link TableColumn} sizes in a {@link Table}.
 *
 * <p>
 * <b>You can only add the {@link Layout} to a container whose <i>only</i>
 * child is the {@link Table} control you want the {@link Layout} applied to.
 * Don't assign the layout directly the {@link Table}</b>
 * </p>
 *
 * @since 3.3
 */
public class TableColumnLayout : AbstractColumnLayout {

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.layout.AbstractColumnLayout#getColumnCount(org.eclipse.swt.widgets.Scrollable)
     */
    override int getColumnCount(Scrollable tableTree) {
        return (cast(Table) tableTree).getColumnCount();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.layout.AbstractColumnLayout#setColumnWidths(org.eclipse.swt.widgets.Scrollable,
     *      int[])
     */
    override void setColumnWidths(Scrollable tableTree, int[] widths) {
        TableColumn[] columns = (cast(Table) tableTree).getColumns();
        for (int i = 0; i < widths.length; i++) {
            columns[i].setWidth(widths[i]);
        }
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.layout.AbstractColumnLayout#getLayoutData(int)
     */
    override ColumnLayoutData getLayoutData(Scrollable tableTree, int columnIndex) {
        TableColumn column = (cast(Table) tableTree).getColumn(columnIndex);
        return cast(ColumnLayoutData) column.getData(LAYOUT_DATA);
    }

    Composite getComposite(Widget column) {
        return (cast(TableColumn) column).getParent().getParent();
    }

    /* (non-Javadoc)
     * @see org.eclipse.jface.layout.AbstractColumnLayout#updateColumnData(org.eclipse.swt.widgets.Widget)
     */
    override void updateColumnData(Widget column) {
        TableColumn tColumn = cast(TableColumn) column;
        Table t = tColumn.getParent();

        if( ! IS_GTK || t.getColumn(t.getColumnCount()-1) !is tColumn ){
            tColumn.setData(LAYOUT_DATA,new ColumnPixelData(tColumn.getWidth()));
            layout(t.getParent(), true);
        }
    }
}
