/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Chris Gross (schtoo@schtoo.com) - support for ISafeRunnableRunner added
 *       (bug 49497 [RCP] JFace dependency on org.eclipse.core.runtime enlarges standalone JFace applications)
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.util.SafeRunnable;

import org.eclipse.jface.util.ISafeRunnableRunner;
import org.eclipse.jface.util.SafeRunnableDialog;
import org.eclipse.jface.util.Policy;
import org.eclipse.core.runtime.ISafeRunnable;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.OperationCanceledException;
import org.eclipse.core.runtime.Status;
import org.eclipse.jface.resource.JFaceResources;

import java.lang.all;
import java.util.Set;

/**
 * Implements a default implementation of ISafeRunnable. The default
 * implementation of <code>handleException</code> opens a dialog to show any
 * errors as they accumulate.
 * <p>
 * This may be executed on any thread.
 */
public abstract class SafeRunnable : ISafeRunnable {

    private static bool ignoreErrors = false;

    private static ISafeRunnableRunner runner;

    private String message;

    /**
     * Creates a new instance of SafeRunnable with a default error message.
     */
    public this() {
        // do nothing
    }

    /**
     * Creates a new instance of SafeRunnable with the given error message.
     *
     * @param message
     *            the error message to use
     */
    public this(String message) {
        this.message = message;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.core.runtime.ISafeRunnable#handleException(java.lang.Throwable)
     */
    public void handleException(Exception e) {
        // Workaround to avoid interactive error dialogs during
        // automated testing
        if (ignoreErrors)
            return;

        if (message is null)
            message = JFaceResources.getString("SafeRunnable.errorMessage"); //$NON-NLS-1$

        Policy.getStatusHandler().show(
                new Status(IStatus.ERROR, Policy.JFACE, message, e),
                JFaceResources.getString("SafeRunnable.errorMessage")); //$NON-NLS-1$
    }

    /**
     * Flag to avoid interactive error dialogs during automated testing.
     *
     * @param flag
     * @return true if errors should be ignored
     * @deprecated use getIgnoreErrors()
     */
    public static bool getIgnoreErrors(bool flag) {
        return ignoreErrors;
    }

    /**
     * Flag to avoid interactive error dialogs during automated testing.
     *
     * @return true if errors should be ignored
     *
     * @since 3.0
     */
    public static bool getIgnoreErrors() {
        return ignoreErrors;
    }

    /**
     * Flag to avoid interactive error dialogs during automated testing.
     *
     * @param flag
     *            set to true if errors should be ignored
     */
    public static void setIgnoreErrors(bool flag) {
        ignoreErrors = flag;
    }

    /**
     * Returns the safe runnable runner.
     *
     * @return the safe runnable runner
     *
     * @since 3.1
     */
    public static ISafeRunnableRunner getRunner() {
        if (runner is null) {
            runner = createDefaultRunner();
        }
        return runner;
    }

    /**
     * Creates the default safe runnable runner.
     *
     * @return the default safe runnable runner
     * @since 3.1
     */
    private static ISafeRunnableRunner createDefaultRunner() {
        return new class ISafeRunnableRunner {
            public void run(ISafeRunnable code) {
                try {
                    code.run();
                } catch (Exception e) {
                    handleException(code, e);
//                 } catch (LinkageError e) {
//                     handleException(code, e);
                }
            }

            private void handleException(ISafeRunnable code, Exception e) {
                if (!(cast(OperationCanceledException)e )) {
                    try {
                        Policy.getLog()
                                .log(
                                        new Status(IStatus.ERROR, Policy.JFACE,
                                                IStatus.ERROR,
                                                "Exception occurred", e)); //$NON-NLS-1$
                    } catch (Exception ex) {
                        ExceptionPrintStackTrace(e);
                    }
                }
                code.handleException(e);
            }
        };
    }

    /**
     * Sets the safe runnable runner.
     *
     * @param runner
     *            the runner to set, or <code>null</code> to reset to the
     *            default runner
     * @since 3.1
     */
    public static void setRunner(ISafeRunnableRunner runner) {
        SafeRunnable.runner = runner;
    }

    /**
     * Runs the given safe runnable using the safe runnable runner. This is a
     * convenience method, equivalent to:
     * <code>SafeRunnable.getRunner().run(runnable)</code>.
     *
     * @param runnable
     *            the runnable to run
     * @since 3.1
     */
    public static void run(ISafeRunnable runnable) {
        getRunner().run(runnable);
    }

}

import tango.core.Tuple;
import tango.core.Traits;

class _DgSafeRunnableT(Dg,T...) : SafeRunnable {

    alias ParameterTupleOf!(Dg) DgArgs;
    static assert( is(DgArgs == Tuple!(T)),
                "Delegate args not correct" );

    Dg dg;
    T t;

    private this( Dg dg, T t ){
        this.dg = dg;
        static if( T.length > 0 ){
            this.t = t;
        }
    }

    public void run( ){
        dg(t);
    }
}

public _DgSafeRunnableT!(Dg,T) dgSafeRunnable(Dg,T...)( Dg dg, T args ){
    return new _DgSafeRunnableT!(Dg,T)(dg,args);
}
