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
module org.eclipse.jface.operation.AccumulatingProgressMonitor;


import org.eclipse.swt.widgets.Display;
import org.eclipse.core.runtime.Assert;
import org.eclipse.core.runtime.IProgressMonitor;
import org.eclipse.core.runtime.IProgressMonitorWithBlocking;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.ProgressMonitorWrapper;
import org.eclipse.jface.dialogs.Dialog;

import java.lang.all;
import java.util.Set;

/**
 * A progress monitor that accumulates <code>worked</code> and <code>subtask</code>
 * calls in the following way by wrapping a standard progress monitor:
 * <ul>
 * <li> When a <code>worked</code> or <code>subtask</code> call occurs the first time,
 *      the progress monitor posts a runnable into the asynchronous SWT event queue.
 * </li>
 * <li> Subsequent calls to <code>worked</code> or <code>subtask</code> do not post
 *      a new runnable as long as a previous runnable still exists in the SWT event
 *      queue. In this case, the progress monitor just updates the internal state of
 *      the runnable that waits in the SWT event queue for its execution. If no runnable
 *      exists, a new one is created and posted into the event queue.
 * </ul>
 * <p>
 * This class is internal to the framework; clients outside JFace should not
 * use this class.
 * </p>
 */
/* package */class AccumulatingProgressMonitor : ProgressMonitorWrapper {

    /**
     * The display.
     */
    private Display display;

    /**
     * The collector, or <code>null</code> if none.
     */
    private Collector collector;

    private String currentTask = ""; //$NON-NLS-1$

    private class Collector : Runnable {
        private String subTask_;

        private double worked_;

        private IProgressMonitor monitor;

        /**
         * Create a new collector.
         * @param subTask
         * @param work
         * @param monitor
         */
        public this(String subTask_, double work, IProgressMonitor monitor) {
            this.subTask_ = subTask_;
            this.worked_ = work;
            this.monitor = monitor;
        }

        /**
         * Add worked to the work.
         * @param workedIncrement
         */
        public void worked(double workedIncrement) {
            this.worked_ = this.worked_ + workedIncrement;
        }

        /**
         * Set the subTask name.
         * @param subTaskName
         */
        public void subTask(String subTaskName) {
            this.subTask_ = subTaskName;
        }

        /**
         * Run the collector.
         */
        public void run() {
            clearCollector(this);
            if (subTask_ !is null) {
                monitor.subTask(subTask_);
            }
            if (worked_ > 0) {
                monitor.internalWorked(worked_);
            }
        }
    }

    /**
     * Creates an accumulating progress monitor wrapping the given one
     * that uses the given display.
     *
     * @param monitor the actual progress monitor to be wrapped
     * @param display the SWT display used to forward the calls
     *  to the wrapped progress monitor
     */
    public this(IProgressMonitor monitor, Display display) {
        super(monitor);
        Assert.isNotNull(display);
        this.display = display;
    }

    /* (non-Javadoc)
     * Method declared on IProgressMonitor.
     */
    public override void beginTask(String name, int totalWork) {
        synchronized (this) {
            collector = null;
        }
        display.asyncExec(new class(name,totalWork) Runnable {
            String name_;
            int totalWork_;
            this(String a, int b){
                name_=a;
                totalWork_=b;
            }
            public void run() {
                currentTask = name_;
                getWrappedProgressMonitor().beginTask(name_, totalWork_);
            }
        });
    }

    /**
     * Clears the collector object used to accumulate work and subtask calls
     * if it matches the given one.
     * @param collectorToClear
     */
    private synchronized void clearCollector(Collector collectorToClear) {
        // Check if the accumulator is still using the given collector.
        // If not, don't clear it.
        if (this.collector is collectorToClear) {
            this.collector = null;
        }
    }

    /**
     *  Creates a collector object to accumulate work and subtask calls.
     * @param subTask
     * @param work
     */
    private void createCollector(String subTask, double work) {
        collector = new Collector(subTask, work, getWrappedProgressMonitor());
        display.asyncExec(collector);
    }

    /* (non-Javadoc)
     * Method declared on IProgressMonitor.
     */
    public override void done() {
        synchronized (this) {
            collector = null;
        }
        display.asyncExec(new class Runnable {
            public void run() {
                getWrappedProgressMonitor().done();
            }
        });
    }

    /* (non-Javadoc)
     * Method declared on IProgressMonitor.
     */
    public override synchronized void internalWorked(double work) {
        if (collector is null) {
            createCollector(null, work);
        } else {
            collector.worked(work);
        }
    }

    /* (non-Javadoc)
     * Method declared on IProgressMonitor.
     */
    public override void setTaskName(String name) {
        synchronized (this) {
            collector = null;
        }
        display.asyncExec(new class(name) Runnable {
            String name_;
            this(String a){
                name_=a;
            }
            public void run() {
                currentTask = name_;
                getWrappedProgressMonitor().setTaskName(name_);
            }
        });
    }

    /* (non-Javadoc)
     * Method declared on IProgressMonitor.
     */
    public override synchronized void subTask(String name) {
        if (collector is null) {
            createCollector(name, 0);
        } else {
            collector.subTask(name);
        }
    }

    /* (non-Javadoc)
     * Method declared on IProgressMonitor.
     */
    public override synchronized void worked(int work) {
        internalWorked(work);
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.runtime.ProgressMonitorWrapper#clearBlocked()
     */
    public override void clearBlocked() {

        //If this is a monitor that can report blocking do so.
        //Don't bother with a collector as this should only ever
        //happen once and prevent any more progress.
        IProgressMonitor pm = getWrappedProgressMonitor();
        if (!(cast(IProgressMonitorWithBlocking)pm )) {
            return;
        }

        display.asyncExec(new class(pm) Runnable {
            IProgressMonitor pm_;
            this(IProgressMonitor a){ pm_=a; }
            /* (non-Javadoc)
             * @see java.lang.Runnable#run()
             */
            public void run() {
                (cast(IProgressMonitorWithBlocking) pm_).clearBlocked();
                Dialog.getBlockedHandler().clearBlocked();
            }
        });
    }

    /* (non-Javadoc)
     * @see org.eclipse.core.runtime.ProgressMonitorWrapper#setBlocked(org.eclipse.core.runtime.IStatus)
     */
    public override void setBlocked(IStatus reason) {
        //If this is a monitor that can report blocking do so.
        //Don't bother with a collector as this should only ever
        //happen once and prevent any more progress.
        IProgressMonitor pm = getWrappedProgressMonitor();
        if (!(cast(IProgressMonitorWithBlocking)pm )) {
            return;
        }

        display.asyncExec(new class(pm,reason) Runnable {
            IProgressMonitor pm_;
            IStatus reason_;
            this(IProgressMonitor a,IStatus b){
                pm_=a;
                reason_=b;
            }
            /* (non-Javadoc)
             * @see java.lang.Runnable#run()
             */
            public void run() {
                (cast(IProgressMonitorWithBlocking) pm_).setBlocked(reason_);
                //Do not give a shell as we want it to block until it opens.
                Dialog.getBlockedHandler().showBlocked(pm_, reason_, currentTask);
            }
        });
    }
}
