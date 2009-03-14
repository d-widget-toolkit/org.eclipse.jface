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
module org.eclipse.jface.wizard.ProgressMonitorPart;


import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.Font;
import org.eclipse.swt.graphics.FontMetrics;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.layout.GridData;
import org.eclipse.swt.layout.GridLayout;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Control;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Label;
import org.eclipse.swt.widgets.Layout;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.IProgressMonitorWithBlocking;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.jface.dialogs.ProgressIndicator;
import org.eclipse.jface.resource.JFaceResources;

import java.lang.all;
import java.util.Set;

/**
 * A standard implementation of an IProgressMonitor. It consists
 * of a label displaying the task and subtask name, and a
 * progress indicator to show progress. In contrast to
 * <code>ProgressMonitorDialog</code> this class only implements
 * <code>IProgressMonitor</code>.
 */
public class ProgressMonitorPart : Composite,
        IProgressMonitorWithBlocking {

    /** the label */
    protected Label fLabel;

    /** the current task name */
    protected String fTaskName;

    /** the current sub task name */
    protected String fSubTaskName;

    /** the progress indicator */
    protected ProgressIndicator fProgressIndicator;

    /** the cancel component */
    protected Control fCancelComponent;

    /** true if canceled */
    protected bool fIsCanceled;

    /** current blocked status */
    protected IStatus blockedStatus;

    /** the cancel lister attached to the cancel component */
    protected Listener fCancelListener;
    private void init_fCancelListener(){
        fCancelListener = new class Listener {
            public void handleEvent(Event e) {
                setCanceled(true);
                if (fCancelComponent !is null) {
                    fCancelComponent.setEnabled(false);
                }
            }
        };
    }
    /**
     * Creates a ProgressMonitorPart.
     * @param parent The SWT parent of the part.
     * @param layout The SWT grid bag layout used by the part. A client
     * can supply the layout to control how the progress monitor part
     * is layed out. If null is passed the part uses its default layout.
     */
    public this(Composite parent, Layout layout) {
        this(parent, layout, SWT.DEFAULT);
    }

    /**
     * Creates a ProgressMonitorPart.
     * @param parent The SWT parent of the part.
     * @param layout The SWT grid bag layout used by the part. A client
     * can supply the layout to control how the progress monitor part
     * is layed out. If null is passed the part uses its default layout.
     * @param progressIndicatorHeight The height of the progress indicator in pixel.
     */
    public this(Composite parent, Layout layout,
            int progressIndicatorHeight) {
        init_fCancelListener();
        super(parent, SWT.NONE);
        initialize(layout, progressIndicatorHeight);
    }

    /**
     * Attaches the progress monitor part to the given cancel
     * component.
     * @param cancelComponent the control whose selection will
     * trigger a cancel
     */
    public void attachToCancelComponent(Control cancelComponent) {
        Assert.isNotNull(cancelComponent);
        fCancelComponent = cancelComponent;
        fCancelComponent.addListener(SWT.Selection, fCancelListener);
    }

    /**
     * Implements <code>IProgressMonitor.beginTask</code>.
     * @see IProgressMonitor#beginTask(java.lang.String, int)
     */
    public void beginTask(String name, int totalWork) {
        fTaskName = name;
        updateLabel();
        if (totalWork is IProgressMonitor.UNKNOWN || totalWork is 0) {
            fProgressIndicator.beginAnimatedTask();
        } else {
            fProgressIndicator.beginTask(totalWork);
        }
    }

    /**
     * Implements <code>IProgressMonitor.done</code>.
     * @see IProgressMonitor#done()
     */
    public void done() {
        fLabel.setText("");//$NON-NLS-1$
        fProgressIndicator.sendRemainingWork();
        fProgressIndicator.done();
    }

    /**
     * Escapes any occurrence of '&' in the given String so that
     * it is not considered as a mnemonic
     * character in SWT ToolItems, MenuItems, Button and Labels.
     * @param in the original String
     * @return The converted String
     */
    protected static String escapeMetaCharacters(String in_) {
        if (in_ is null || in_.indexOf('&') < 0) {
            return in_;
        }
        int length = in_.length;
        StringBuffer out_ = new StringBuffer(length + 1);
        for (int i = 0; i < length; i++) {
            char c = in_.charAt(i);
            if (c is '&') {
                out_.append("&&");//$NON-NLS-1$
            } else {
                out_.append(c);
            }
        }
        return out_.toString();
    }

    /**
     * Creates the progress monitor's UI parts and layouts them
     * according to the given layout. If the layout is <code>null</code>
     * the part's default layout is used.
     * @param layout The layout for the receiver.
     * @param progressIndicatorHeight The suggested height of the indicator
     */
    protected void initialize(Layout layout, int progressIndicatorHeight) {
        if (layout is null) {
            GridLayout l = new GridLayout();
            l.marginWidth = 0;
            l.marginHeight = 0;
            l.numColumns = 1;
            layout = l;
        }
        setLayout(layout);

        fLabel = new Label(this, SWT.LEFT);
        fLabel.setLayoutData(new GridData(GridData.FILL_HORIZONTAL));

        if (progressIndicatorHeight is SWT.DEFAULT) {
            GC gc = new GC(fLabel);
            FontMetrics fm = gc.getFontMetrics();
            gc.dispose();
            progressIndicatorHeight = fm.getHeight();
        }

        fProgressIndicator = new ProgressIndicator(this);
        GridData gd = new GridData();
        gd.horizontalAlignment = GridData.FILL;
        gd.grabExcessHorizontalSpace = true;
        gd.verticalAlignment = GridData.CENTER;
        gd.heightHint = progressIndicatorHeight;
        fProgressIndicator.setLayoutData(gd);
    }

    /**
     * Implements <code>IProgressMonitor.internalWorked</code>.
     * @see IProgressMonitor#internalWorked(double)
     */
    public void internalWorked(double work) {
        fProgressIndicator.worked(work);
    }

    /**
     * Implements <code>IProgressMonitor.isCanceled</code>.
     * @see IProgressMonitor#isCanceled()
     */
    public bool isCanceled() {
        return fIsCanceled;
    }

    /**
     * Detach the progress monitor part from the given cancel
     * component
     * @param cc
     */
    public void removeFromCancelComponent(Control cc) {
        Assert.isTrue(fCancelComponent is cc && fCancelComponent !is null);
        fCancelComponent.removeListener(SWT.Selection, fCancelListener);
        fCancelComponent = null;
    }

    /**
     * Implements <code>IProgressMonitor.setCanceled</code>.
     * @see IProgressMonitor#setCanceled(bool)
     */
    public void setCanceled(bool b) {
        fIsCanceled = b;
    }

    /**
     * Sets the progress monitor part's font.
     */
    public override void setFont(Font font) {
        super.setFont(font);
        fLabel.setFont(font);
        fProgressIndicator.setFont(font);
    }

    /*
     *  (non-Javadoc)
     * @see org.eclipse.core.runtime.IProgressMonitor#setTaskName(java.lang.String)
     */
    public void setTaskName(String name) {
        fTaskName = name;
        updateLabel();
    }

    /*
     *  (non-Javadoc)
     * @see org.eclipse.core.runtime.IProgressMonitor#subTask(java.lang.String)
     */
    public void subTask(String name) {
        fSubTaskName = name;
        updateLabel();
    }

    /**
     * Updates the label with the current task and subtask names.
     */
    protected void updateLabel() {
        if (blockedStatus is null) {
            String text = taskLabel();
            fLabel.setText(text);
        } else {
            fLabel.setText(blockedStatus.getMessage());
        }

        //Force an update as we are in the UI Thread
        fLabel.update();
    }

    /**
     * Return the label for showing tasks
     * @return String
     */
    private String taskLabel() {
        bool hasTask= fTaskName !is null && fTaskName.length > 0;
        bool hasSubtask= fSubTaskName !is null && fSubTaskName.length > 0;

        if (hasTask) {
            if (hasSubtask)
                return escapeMetaCharacters(JFaceResources.format(
                        "Set_SubTask", [ fTaskName, fSubTaskName ] ));//$NON-NLS-1$
            return escapeMetaCharacters(fTaskName);

        } else if (hasSubtask) {
            return escapeMetaCharacters(fSubTaskName);

        } else {
            return ""; //$NON-NLS-1$
        }
    }

    /**
     * Implements <code>IProgressMonitor.worked</code>.
     * @see IProgressMonitor#worked(int)
     */
    public void worked(int work) {
        internalWorked(work);
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.runtime.IProgressMonitorWithBlocking#clearBlocked()
     */
    public void clearBlocked() {
        blockedStatus = null;
        updateLabel();

    }

    /* (non-Javadoc)
     * @see org.eclipse.core.runtime.IProgressMonitorWithBlocking#setBlocked(org.eclipse.core.runtime.IStatus)
     */
    public void setBlocked(IStatus reason) {
        blockedStatus = reason;
        updateLabel();

    }
}
