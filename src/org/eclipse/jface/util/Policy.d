/*******************************************************************************
 * Copyright (c) 2004, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Chris Gross (schtoo@schtoo.com) - support for ILogger added
 *       (bug 49497 [RCP] JFace dependency on org.eclipse.core.runtime enlarges standalone JFace applications)
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.util.Policy;

static import org.eclipse.core.runtime.Assert;
import org.eclipse.swt.events.DisposeEvent;
import org.eclipse.swt.events.DisposeListener;
import org.eclipse.swt.widgets.Display;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.jface.dialogs.AnimatorFactory;
import org.eclipse.jface.dialogs.ErrorSupportProvider;

import org.eclipse.jface.util.StatusHandler;
import org.eclipse.jface.util.SafeRunnableDialog;
import org.eclipse.jface.util.ILogger;

import java.lang.all;
import java.util.Set;

/**
 * The Policy class handles settings for behaviour, debug flags and logging
 * within JFace.
 *
 * @since 3.0
 */
public class Policy {

    /**
     * Constant for the the default setting for debug options.
     */
    public static const bool DEFAULT = false;

    /**
     * The unique identifier of the JFace plug-in.
     */
    public static const String JFACE = "org.eclipse.jface"; //$NON-NLS-1$

    private static ILogger log;

    private static Comparator viewerComparator;

    private static AnimatorFactory animatorFactory;

    /**
     * A flag to indicate whether unparented dialogs should be checked.
     */
    public static bool DEBUG_DIALOG_NO_PARENT = DEFAULT;

    /**
     * A flag to indicate whether actions are being traced.
     */
    public static bool TRACE_ACTIONS = DEFAULT;

    /**
     * A flag to indicate whether toolbars are being traced.
     */

    public static bool TRACE_TOOLBAR = DEFAULT;

    private static ErrorSupportProvider errorSupportProvider;

    private static StatusHandler statusHandler;

    /**
     * Returns the dummy log to use if none has been set
     */
    private static ILogger getDummyLog() {
        return new class ILogger {
            public void log(IStatus status) {
                getDwtLogger.error( __FILE__, __LINE__, status.getMessage());
                if (status.getException() !is null) {
                    auto e = status.getException();
                    getDwtLogger.error( __FILE__, __LINE__,  "Exception of type {} in {}({}): {}", e.classinfo.name, e.file, e.line, e.msg );
                    if( e.info !is null ){
                        foreach( msg; e.info ){
                            getDwtLogger.error( __FILE__, __LINE__,  "    trc: {}", msg );
                        }
                    }
//                     status.getException().printStackTrace();
                }
            }
        };
    }

    /**
     * Sets the logger used by JFace to log errors.
     *
     * @param logger
     *            the logger to use, or <code>null</code> to use the default
     *            logger
     * @since 3.1
     */
    public static void setLog(ILogger logger) {
        log = logger;
    }

    /**
     * Returns the logger used by JFace to log errors.
     * <p>
     * The default logger prints the status to <code>System.err</code>.
     * </p>
     *
     * @return the logger
     * @since 3.1
     */
    public static ILogger getLog() {
        if (log is null) {
            log = getDummyLog();
        }
        return log;
    }

    /**
     * Sets the status handler used by JFace to handle statuses.
     *
     * @param status
     *            the handler to use, or <code>null</code> to use the default
     *            one
     * @since 3.4
     */
    public static void setStatusHandler(StatusHandler status) {
        statusHandler = status;
    }

    /**
     * Returns the status handler used by JFace to handle statuses.
     *
     * @return the status handler
     * @since 3.4
     */
    public static StatusHandler getStatusHandler() {
        if (statusHandler is null) {
            statusHandler = getDummyStatusHandler();
        }
        return statusHandler;
    }

    private static StatusHandler getDummyStatusHandler() {
        return new class StatusHandler {
            private SafeRunnableDialog dialog;

            public void show(IStatus status, String title) {
                Runnable runnable = dgRunnable( (IStatus status_) {
                    if (dialog is null || dialog.getShell().isDisposed()) {
                        dialog = new SafeRunnableDialog(status_);
                        dialog.create();
                        dialog.getShell().addDisposeListener(
                                new class DisposeListener {
                                    public void widgetDisposed(
                                            DisposeEvent e) {
                                        dialog = null;
                                    }
                                });
                        dialog.open();
                    } else {
                        dialog.addStatus(status_);
                        dialog.refresh();
                    }
                }, status );
                if (Display.getCurrent() !is null) {
                    runnable.run();
                } else {
                    Display.getDefault().asyncExec(runnable);
                }
            }
        };
    }

    /**
     * Return the default comparator used by JFace to sort strings.
     *
     * @return a default comparator used by JFace to sort strings
     */
    private static Comparator getDefaultComparator() {
        return new class() Comparator {
            /**
             * Compares string s1 to string s2.
             *
             * @param s1
             *            string 1
             * @param s2
             *            string 2
             * @return Returns an integer value. Value is less than zero if
             *         source is less than target, value is zero if source and
             *         target are equal, value is greater than zero if source is
             *         greater than target.
             * @exception ClassCastException
             *                the arguments cannot be cast to Strings.
             */
            public int compare(Object s1, Object s2) {
                auto a = (cast(ArrayWrapperString) s1).array;
                auto b = (cast(ArrayWrapperString) s2).array;
                return a < b;
            }
        };
    }

    /**
     * Return the comparator used by JFace to sort strings.
     *
     * @return the comparator used by JFace to sort strings
     * @since 3.2
     */
    public static Comparator getComparator() {
        if (viewerComparator is null) {
            viewerComparator = getDefaultComparator();
        }
        return viewerComparator;
    }

    /**
     * Sets the comparator used by JFace to sort strings.
     *
     * @param comparator
     *            comparator used by JFace to sort strings
     * @since 3.2
     */
    public static void setComparator(Comparator comparator) {
        org.eclipse.core.runtime.Assert.Assert.isTrue(viewerComparator is null);
        viewerComparator = comparator;
    }

    /**
     * Sets the animator factory used by JFace to create control animator
     * instances.
     *
     * @param factory
     *            the AnimatorFactory to use.
     * @since 3.2
     * @deprecated this is no longer in use as of 3.3
     */
    public static void setAnimatorFactory(AnimatorFactory factory) {
        animatorFactory = factory;
    }

    /**
     * Returns the animator factory used by JFace to create control animator
     * instances.
     *
     * @return the animator factory used to create control animator instances.
     * @since 3.2
     * @deprecated this is no longer in use as of 3.3
     */
    public static AnimatorFactory getAnimatorFactory() {
        if (animatorFactory is null)
            animatorFactory = new AnimatorFactory();
        return animatorFactory;
    }

    /**
     * Set the error support provider for error dialogs.
     *
     * @param provider
     * @since 3.3
     */
    public static void setErrorSupportProvider(ErrorSupportProvider provider) {
        errorSupportProvider = provider;
    }

    /**
     * Return the ErrorSupportProvider for the receiver.
     *
     * @return ErrorSupportProvider or <code>null</code> if this has not been
     *         set
     * @since 3.3
     */
    public static ErrorSupportProvider getErrorSupportProvider() {
        return errorSupportProvider;
    }

    /**
     * Log the Exception to the logger.
     *
     * @param exception
     * @since 3.4
     */
    public static void logException(Exception exception) {
        getLog().log(
                new Status(IStatus.ERROR, JFACE, ExceptionGetLocalizedMessage( exception )
                        , exception));

    }

}
