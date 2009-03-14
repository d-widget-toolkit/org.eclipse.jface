/*******************************************************************************
 * Copyright (c) 2004, 2006 IBM Corporation and others.
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

module org.eclipse.jface.bindings.BindingManagerEvent;

import org.eclipse.jface.bindings.BindingManager;
import org.eclipse.jface.bindings.Scheme;
import org.eclipse.jface.bindings.TriggerSequence;


import org.eclipse.core.commands.ParameterizedCommand;
import org.eclipse.core.commands.common.AbstractBitSetEvent;
import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.Collection;
import java.util.Map;
import java.util.Set;

/**
 * An instance of this class describes changes to an instance of
 * <code>BindingManager</code>.
 * <p>
 * This class is not intended to be extended by clients.
 * </p>
 *
 * @since 3.1
 * @see IBindingManagerListener#bindingManagerChanged(BindingManagerEvent)
 */
public final class BindingManagerEvent : AbstractBitSetEvent {

    /**
     * The bit used to represent whether the map of active bindings has changed.
     */
    private static const int CHANGED_ACTIVE_BINDINGS = 1;

    /**
     * The bit used to represent whether the active scheme has changed.
     */
    private static const int CHANGED_ACTIVE_SCHEME = 1 << 1;

    /**
     * The bit used to represent whether the active locale has changed.
     */
    private static const int CHANGED_LOCALE = 1 << 2;

    /**
     * The bit used to represent whether the active platform has changed.
     */
    private static const int CHANGED_PLATFORM = 1 << 3;

    /**
     * The bit used to represent whether the scheme's defined state has changed.
     */
    private static const int CHANGED_SCHEME_DEFINED = 1 << 4;

    /**
     * The binding manager that has changed; this value is never
     * <code>null</code>.
     */
    private const BindingManager manager;

    /**
     * The map of triggers (<code>Collection</code> of
     * <code>TriggerSequence</code>) by parameterized command (<code>ParameterizedCommand</code>)
     * before the change occurred. This map may be empty and it may be
     * <code>null</code>.
     */
    private const Map previousTriggersByParameterizedCommand;

    /**
     * The scheme that became defined or undefined. This value may be
     * <code>null</code> if no scheme changed its defined state.
     */
    private const Scheme scheme;

    /**
     * Creates a new instance of this class.
     *
     * @param manager
     *            the instance of the binding manager that changed; must not be
     *            <code>null</code>.
     * @param activeBindingsChanged
     *            Whether the active bindings have changed.
     * @param previousTriggersByParameterizedCommand
     *            The map of triggers (<code>TriggerSequence</code>) by
     *            fully-parameterized command (<code>ParameterizedCommand</code>)
     *            before the change occured. This map may be <code>null</code>
     *            or empty.
     * @param activeSchemeChanged
     *            true, iff the active scheme changed.
     * @param scheme
     *            The scheme that became defined or undefined; <code>null</code>
     *            if no scheme changed state.
     * @param schemeDefined
     *            <code>true</code> if the given scheme became defined;
     *            <code>false</code> otherwise.
     * @param localeChanged
     *            <code>true</code> iff the active locale changed
     * @param platformChanged
     *            <code>true</code> iff the active platform changed
     */
    public this(BindingManager manager,
            bool activeBindingsChanged,
            Map previousTriggersByParameterizedCommand,
            bool activeSchemeChanged, Scheme scheme,
            bool schemeDefined, bool localeChanged,
            bool platformChanged) {
        if (manager is null) {
            throw new NullPointerException(
                    "A binding manager event needs a binding manager"); //$NON-NLS-1$
        }
        this.manager = manager;

        if (schemeDefined && (scheme is null)) {
            throw new NullPointerException(
                    "If a scheme changed defined state, then there should be a scheme identifier"); //$NON-NLS-1$
        }
        this.scheme = scheme;

        this.previousTriggersByParameterizedCommand = previousTriggersByParameterizedCommand;

        if (activeBindingsChanged) {
            changedValues |= CHANGED_ACTIVE_BINDINGS;
        }
        if (activeSchemeChanged) {
            changedValues |= CHANGED_ACTIVE_SCHEME;
        }
        if (localeChanged) {
            changedValues |= CHANGED_LOCALE;
        }
        if (platformChanged) {
            changedValues |= CHANGED_PLATFORM;
        }
        if (schemeDefined) {
            changedValues |= CHANGED_SCHEME_DEFINED;
        }
    }

    /**
     * Returns the instance of the manager that changed.
     *
     * @return the instance of the manager that changed. Guaranteed not to be
     *         <code>null</code>.
     */
    public final BindingManager getManager() {
        return manager;
    }

    /**
     * Returns the scheme that changed.
     *
     * @return The changed scheme
     */
    public final Scheme getScheme() {
        return scheme;
    }

    /**
     * Returns whether the active bindings have changed.
     *
     * @return <code>true</code> if the active bindings have changed;
     *         <code>false</code> otherwise.
     */
    public final bool isActiveBindingsChanged() {
        return ((changedValues & CHANGED_ACTIVE_BINDINGS) !is 0);
    }

    /**
     * Computes whether the active bindings have changed for a given command
     * identifier.
     *
     * @param parameterizedCommand
     *            The fully-parameterized command whose bindings might have
     *            changed; must not be <code>null</code>.
     * @return <code>true</code> if the active bindings have changed for the
     *         given command identifier; <code>false</code> otherwise.
     */
    public final bool isActiveBindingsChangedFor(
            ParameterizedCommand parameterizedCommand) {
        TriggerSequence[] currentBindings = manager
                .getActiveBindingsFor(parameterizedCommand);
        TriggerSequence[] previousBindings;
        if (previousTriggersByParameterizedCommand !is null) {
            Collection previousBindingCollection = cast(Collection) previousTriggersByParameterizedCommand
                    .get(parameterizedCommand);
            if (previousBindingCollection is null) {
                previousBindings = null;
            } else {
                previousBindings = cast(TriggerSequence[])previousBindingCollection.toArray();
            }
        } else {
            previousBindings = null;
        }

        return !Util.opEquals(currentBindings, previousBindings);
    }

    /**
     * Returns whether or not the active scheme changed.
     *
     * @return true, iff the active scheme property changed.
     */
    public bool isActiveSchemeChanged() {
        return ((changedValues & CHANGED_ACTIVE_SCHEME) !is 0);
    }

    /**
     * Returns whether the locale has changed
     *
     * @return <code>true</code> if the locale changed; <code>false</code>
     *         otherwise.
     */
    public bool isLocaleChanged() {
        return ((changedValues & CHANGED_LOCALE) !is 0);
    }

    /**
     * Returns whether the platform has changed
     *
     * @return <code>true</code> if the platform changed; <code>false</code>
     *         otherwise.
     */
    public bool isPlatformChanged() {
        return ((changedValues & CHANGED_PLATFORM) !is 0);
    }

    /**
     * Returns whether the list of defined scheme identifiers has changed.
     *
     * @return <code>true</code> if the list of scheme identifiers has
     *         changed; <code>false</code> otherwise.
     */
    public final bool isSchemeChanged() {
        return (scheme !is null);
    }

    /**
     * Returns whether or not the scheme became defined
     *
     * @return <code>true</code> if the scheme became defined.
     */
    public final bool isSchemeDefined() {
        return (((changedValues & CHANGED_SCHEME_DEFINED) !is 0) && (scheme !is null));
    }
}
