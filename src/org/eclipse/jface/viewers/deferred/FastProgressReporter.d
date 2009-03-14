/*******************************************************************************
 * Copyright (c) 2004, 2005 IBM Corporation and others.
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
module org.eclipse.jface.viewers.deferred.FastProgressReporter;

import org.eclipse.core.runtime.IProgressMonitor;

import java.lang.all;
import java.util.Set;

/**
 * A more efficient alternative to an IProgressMonitor. In particular, the implementation
 * is designed to make isCanceled() run as efficiently as possible. Currently package-visible
 * because the implementation is incomplete.
 *
 * @since 3.1
 */
final class FastProgressReporter {
    private IProgressMonitor monitor;
    private /+volatile+/ bool canceled = false;
    private int cancelCheck = 0;
//    private String taskName;
//
//    private int taskDepth = 0;
//    private int subTaskSize = 1;
//    private int totalWork = 1;
//    private int parentWork = 1;
//    private int monitorUnitsRemaining;

    private static int CANCEL_CHECK_PERIOD = 40;

    /**
     * Constructs a null FastProgressReporter
     */
    public this() {
    }

    /**
     * Constructs a FastProgressReporter that wraps the given progress monitor
     *
     * @param monitor the monitor to wrap
     * @param totalProgress the total progress to be reported
     */
    public this(IProgressMonitor monitor, int totalProgress) {
        this.monitor = monitor;
        //monitorUnitsRemaining = totalProgress;
        canceled = monitor.isCanceled();
    }

//    /**
//     * Every call to beginTask must have a corresponding call to endTask, with the
//     * same argument.
//     *
//     * @param totalWork
//     * @since 3.1
//     */
//    public void beginTask(int totalWork) {
//
//        if (monitor is null) {
//            return;
//        }
//
//        taskDepth++;
//
//        if (totalWork is 0) {
//            return;
//        }
//
//        this.totalWork *= totalWork;
//    }
//
//    public void beginSubTask(int subTaskWork) {
//        subTaskSize *= subTaskWork;
//    }
//
//    public void endSubTask(int subTaskWork) {
//        subTaskSize /= subTaskWork;
//    }
//
//    public void worked(int amount) {
//        amount *= subTaskSize;
//
//        if (amount > totalWork) {
//            amount = totalWork;
//        }
//
//        int consumed = monitorUnitsRemaining * amount / totalWork;
//
//        if (consumed > 0) {
//            monitor.worked(consumed);
//            monitorUnitsRemaining -= consumed;
//        }
//        totalWork -= amount;
//    }
//
//    public void endTask(int totalWork) {
//        taskDepth--;
//
//        if (taskDepth is 0) {
//            if (monitor !is null && monitorUnitsRemaining > 0) {
//                monitor.worked(monitorUnitsRemaining);
//            }
//        }
//
//        if (totalWork is 0) {
//            return;
//        }
//
//        this.totalWork /= totalWork;
//
//    }

    /**
     * Return whether the progress monitor has been canceled.
     *
     * @return <code>true</code> if the monitor has been cancelled, <code>false</code> otherwise.
     */
    public bool isCanceled() {
        if (monitor is null) {
            return canceled;
        }

        cancelCheck++;
        if (cancelCheck > CANCEL_CHECK_PERIOD) {
            canceled = monitor.isCanceled();
            cancelCheck = 0;
        }
        return canceled;
    }

    /**
     * Cancel the progress monitor.
     */
    public void cancel() {
        canceled = true;

        if (monitor is null) {
            return;
        }
        monitor.setCanceled(true);
    }
}
