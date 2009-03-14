/*******************************************************************************
 * Copyright (c) 2000, 2007 IBM Corporation and others.
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
module org.eclipse.jface.util.SafeRunnableDialog;


import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.jface.dialogs.ErrorDialog;
import org.eclipse.jface.dialogs.IDialogConstants;
import org.eclipse.jface.resource.JFaceResources;
import org.eclipse.jface.viewers.CellLabelProvider;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.ISelectionChangedListener;
import org.eclipse.jface.viewers.IStructuredContentProvider;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.jface.viewers.SelectionChangedEvent;
import org.eclipse.jface.viewers.TableViewer;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.ViewerCell;
import org.eclipse.jface.viewers.ViewerComparator;
import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.Collection;
import java.util.ArrayList;
import java.util.Set;

/**
 * SafeRunnableDialog is a dialog that can show the results of multiple safe
 * runnable errors.
 *
 */
class SafeRunnableDialog : ErrorDialog {

    private TableViewer statusListViewer;

    private Collection statuses;

    /**
     * Create a new instance of the receiver on a status.
     *
     * @param status
     *            The status to display.
     */
    this(IStatus status) {

        super(null, JFaceResources.getString("error"), status.getMessage(), //$NON-NLS-1$
                status, IStatus.ERROR);
        statuses = new ArrayList();
        setShellStyle(SWT.DIALOG_TRIM | SWT.MODELESS | SWT.RESIZE | SWT.MIN | SWT.MAX
                | getDefaultOrientation());

        setStatus(status);
        statuses.add(cast(Object)status);

        setBlockOnOpen(false);

        String reason = JFaceResources
                .getString("SafeRunnableDialog_checkDetailsMessage"); //$NON-NLS-1$
        if (status.getException() !is null) {
            reason = status.getException().msg is null ? status
                    .getException().toString() : status.getException()
                    .msg;
        }
        this.message = JFaceResources.format(JFaceResources
                .getString("SafeRunnableDialog_reason"), [ //$NON-NLS-1$
                status.getMessage(), reason ]);
    }

    /**
     * Method which should be invoked when new errors become available for
     * display
     */
    void refresh() {

        if (AUTOMATED_MODE)
            return;

        createStatusList(cast(Composite) dialogArea);
        updateEnablements();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.dialogs.ErrorDialog#createDialogArea(org.eclipse.swt.widgets.Composite)
     */
    protected override Control createDialogArea(Composite parent) {
        Control area = super.createDialogArea(parent);
        createStatusList(cast(Composite) area);
        return area;
    }

    /**
     * Create the status list if required.
     *
     * @param parent
     *            the Control to create it in.
     */
    private void createStatusList(Composite parent) {
        if (isMultipleStatusDialog()) {
            if (statusListViewer is null) {
                // The job list doesn't exist so create it.
                setMessage(JFaceResources
                        .getString("SafeRunnableDialog_MultipleErrorsMessage")); //$NON-NLS-1$
                getShell()
                        .setText(
                                JFaceResources
                                        .getString("SafeRunnableDialog_MultipleErrorsTitle")); //$NON-NLS-1$
                createStatusListArea(parent);
                showDetailsArea();
            }
            refreshStatusList();
        }
    }

    /*
     * Update the button enablements
     */
    private void updateEnablements() {
        Button details = getButton(IDialogConstants.DETAILS_ID);
        if (details !is null) {
            details.setEnabled(true);
        }
    }

    /**
     * This method sets the message in the message label.
     *
     * @param messageString -
     *            the String for the message area
     */
    private void setMessage(String messageString) {
        // must not set null text in a label
        message = messageString is null ? "" : messageString; //$NON-NLS-1$
        if (messageLabel is null || messageLabel.isDisposed()) {
            return;
        }
        messageLabel.setText(message);
    }

    /**
     * Create an area that allow the user to select one of multiple jobs that
     * have reported errors
     *
     * @param parent -
     *            the parent of the area
     */
    private void createStatusListArea(Composite parent) {
        // Display a list of jobs that have reported errors
        statusListViewer = new TableViewer(parent, SWT.SINGLE | SWT.H_SCROLL
                | SWT.V_SCROLL | SWT.BORDER);
        statusListViewer.setComparator(getViewerComparator());
        Control control = statusListViewer.getControl();
        GridData data = new GridData(GridData.FILL_BOTH
                | GridData.GRAB_HORIZONTAL | GridData.GRAB_VERTICAL);
        data.heightHint = convertHeightInCharsToPixels(10);
        control.setLayoutData(data);
        statusListViewer.setContentProvider(getStatusContentProvider());
        statusListViewer.setLabelProvider(getStatusListLabelProvider());
        statusListViewer
                .addSelectionChangedListener(new class ISelectionChangedListener {
                    public void selectionChanged(SelectionChangedEvent event) {
                        handleSelectionChange();
                    }
                });
        applyDialogFont(parent);
        statusListViewer.setInput(this);
    }

    /**
     * Return the label provider for the status list.
     *
     * @return CellLabelProvider
     */
    private CellLabelProvider getStatusListLabelProvider() {
        return new class CellLabelProvider {
            /*
             * (non-Javadoc)
             *
             * @see org.eclipse.jface.viewers.CellLabelProvider#update(org.eclipse.jface.viewers.ViewerCell)
             */
            public void update(ViewerCell cell) {
                cell.setText((cast(IStatus) cell.getElement()).getMessage());

            }
        };
    }

    /**
     * Return the content provider for the statuses.
     *
     * @return IStructuredContentProvider
     */
    private IStructuredContentProvider getStatusContentProvider() {
        return new class IStructuredContentProvider {
            /*
             * (non-Javadoc)
             *
             * @see org.eclipse.jface.viewers.IStructuredContentProvider#getElements(java.lang.Object)
             */
            public Object[] getElements(Object inputElement) {
                return statuses.toArray();
            }

            /*
             * (non-Javadoc)
             *
             * @see org.eclipse.jface.viewers.IContentProvider#dispose()
             */
            public void dispose() {

            }

            /*
             * (non-Javadoc)
             *
             * @see org.eclipse.jface.viewers.IContentProvider#inputChanged(org.eclipse.jface.viewers.Viewer,
             *      java.lang.Object, java.lang.Object)
             */
            public void inputChanged(Viewer viewer, Object oldInput,
                    Object newInput) {

            }
        };
    }

    /*
     * Return whether there are multiple errors to be displayed
     */
    private bool isMultipleStatusDialog() {
        return statuses.size() > 1;
    }

    /**
     * Return a viewer sorter for looking at the jobs.
     *
     * @return ViewerSorter
     */
    private ViewerComparator getViewerComparator() {
        return new class ViewerComparator {
            /*
             * (non-Javadoc)
             *
             * @see org.eclipse.jface.viewers.ViewerComparator#compare(org.eclipse.jface.viewers.Viewer,
             *      java.lang.Object, java.lang.Object)
             */
            public int compare(Viewer testViewer, Object e1, Object e2) {
                String message1 = (cast(IStatus) e1).getMessage();
                String message2 = (cast(IStatus) e2).getMessage();
                if (message1 is null)
                    return 1;
                if (message2 is null)
                    return -1;

                //TODO: was compareTo, is this sufficient?
                return message1 < message2;
            }
        };
    }

    /**
     * Refresh the contents of the viewer.
     */
    void refreshStatusList() {
        if (statusListViewer !is null
                && !statusListViewer.getControl().isDisposed()) {
            statusListViewer.refresh();
            Point newSize = getShell().computeSize(SWT.DEFAULT, SWT.DEFAULT);
            getShell().setSize(newSize);
        }
    }

    /**
     * Get the single selection. Return null if the selection is not just one
     * element.
     *
     * @return IStatus or <code>null</code>.
     */
    private IStatus getSingleSelection() {
        ISelection rawSelection = statusListViewer.getSelection();
        if (rawSelection !is null
                && cast(IStructuredSelection)rawSelection ) {
            IStructuredSelection selection = cast(IStructuredSelection) rawSelection;
            if (selection.size() is 1) {
                return cast(IStatus) selection.getFirstElement();
            }
        }
        return null;
    }

    /**
     * The selection in the multiple job list has changed. Update widget
     * enablements and repopulate the list.
     */
    void handleSelectionChange() {
        IStatus newSelection = getSingleSelection();
        setStatus(newSelection);
        updateEnablements();
        showDetailsArea();
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.dialogs.ErrorDialog#shouldShowDetailsButton()
     */
    protected override bool shouldShowDetailsButton() {
        return true;
    }

    /**
     * Add the status to the receiver.
     * @param status
     */
    public void addStatus(IStatus status) {
        statuses.add(cast(Object)status);
        refresh();

    }


}
