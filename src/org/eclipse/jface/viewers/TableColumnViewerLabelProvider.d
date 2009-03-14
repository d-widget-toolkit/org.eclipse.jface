/*******************************************************************************
 * Copyright (c) 2006, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Tom Shindl <tom.schindl@bestsolution.at> - initial API and implementation
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/

module org.eclipse.jface.viewers.TableColumnViewerLabelProvider;

import org.eclipse.jface.viewers.WrappedViewerLabelProvider;
import org.eclipse.jface.viewers.ITableLabelProvider;
import org.eclipse.jface.viewers.ITableColorProvider;
import org.eclipse.jface.viewers.ITableFontProvider;
import org.eclipse.jface.viewers.IBaseLabelProvider;
import org.eclipse.jface.viewers.ViewerCell;

import java.lang.all;
import java.util.Set;

/**
 * TableColumnViewerLabelProvider is the mapping from the table based providers
 * to the ViewerLabelProvider.
 *
 * @since 3.3
 * @see ITableLabelProvider
 * @see ITableColorProvider
 * @see ITableFontProvider
 *
 */
class TableColumnViewerLabelProvider : WrappedViewerLabelProvider {

    private ITableLabelProvider tableLabelProvider;

    private ITableColorProvider tableColorProvider;

    private ITableFontProvider tableFontProvider;

    /**
     * Create a new instance of the receiver.
     *
     * @param labelProvider
     *            instance of a table based label provider
     * @see ITableLabelProvider
     * @see ITableColorProvider
     * @see ITableFontProvider
     */
    public this(IBaseLabelProvider labelProvider) {
        super(labelProvider);

        if ( auto i = cast(ITableLabelProvider)labelProvider )
            tableLabelProvider = i;

        if (auto i = cast(ITableColorProvider)labelProvider )
            tableColorProvider = i;

        if (auto i = cast(ITableFontProvider)labelProvider )
            tableFontProvider = i;
    }



    /* (non-Javadoc)
     * @see org.eclipse.jface.viewers.WrappedViewerLabelProvider#update(org.eclipse.jface.viewers.ViewerCell)
     */
    public override void update(ViewerCell cell) {

        Object element = cell.getElement();
        int index = cell.getColumnIndex();

        if (tableLabelProvider is null) {
            cell.setText(getLabelProvider().getText(element));
            cell.setImage(getLabelProvider().getImage(element));
        } else {
            cell.setText(tableLabelProvider.getColumnText(element, index));
            cell.setImage(tableLabelProvider.getColumnImage(element, index));
        }

        if (tableColorProvider is null) {
            if (getColorProvider() !is null) {
                cell.setBackground(getColorProvider().getBackground(element));
                cell.setForeground(getColorProvider().getForeground(element));
            }

        } else {
            cell.setBackground(tableColorProvider
                    .getBackground(element, index));
            cell.setForeground(tableColorProvider
                    .getForeground(element, index));

        }

        if (tableFontProvider is null) {
            if (getFontProvider() !is null)
                cell.setFont(getFontProvider().getFont(element));
        } else
            cell.setFont(tableFontProvider.getFont(element, index));

    }


}
