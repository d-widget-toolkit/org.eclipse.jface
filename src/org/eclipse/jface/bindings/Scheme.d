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

module org.eclipse.jface.bindings.Scheme;

import org.eclipse.jface.bindings.ISchemeListener;
import org.eclipse.jface.bindings.SchemeEvent;


import org.eclipse.core.commands.common.NamedHandleObject;
import org.eclipse.core.commands.common.NotDefinedException;
import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.Iterator;
import java.util.Set;
import java.util.HashSet;

/**
 * <p>
 * An instance of <code>IScheme</code> is a handle representing a binding
 * scheme as defined by the extension point <code>org.eclipse.ui.bindings</code>.
 * The identifier of the handle is the identifier of the scheme being represented.
 * </p>
 * <p>
 * An instance of <code>IScheme</code> can be obtained from an instance of
 * <code>ICommandManager</code> for any identifier, whether or not a scheme
 * with that identifier is defined in the plugin registry.
 * </p>
 * <p>
 * The handle-based nature of this API allows it to work well with runtime
 * plugin activation and deactivation. If a scheme is defined, that means that
 * its corresponding plug-in is active. If the plug-in is then deactivated, the
 * scheme will still exist but it will be undefined. An attempt to use an
 * undefined scheme will result in a <code>NotDefinedException</code>
 * being thrown.
 * </p>
 * <p>
 * This class is not intended to be extended by clients.
 * </p>
 *
 * @since 3.1
 * @see ISchemeListener
 * @see org.eclipse.core.commands.CommandManager
 */
public final class Scheme : NamedHandleObject, Comparable {

    /**
     * The collection of all objects listening to changes on this scheme. This
     * value is <code>null</code> if there are no listeners.
     */
    private Set listeners = null;

    /**
     * The parent identifier for this scheme. This is the identifier of the
     * scheme from which this scheme inherits some of its bindings. This value
     * can be <code>null</code> if the scheme has no parent.
     */
    private String parentId = null;

    /**
     * Constructs a new instance of <code>Scheme</code> with an identifier.
     *
     * @param id
     *            The identifier to create; must not be <code>null</code>.
     */
    this(String id) {
        super(id);
    }

    /**
     * Registers an instance of <code>ISchemeListener</code> to listen for
     * changes to attributes of this instance.
     *
     * @param schemeListener
     *            the instance of <code>ISchemeListener</code> to register.
     *            Must not be <code>null</code>. If an attempt is made to
     *            register an instance of <code>ISchemeListener</code> which
     *            is already registered with this instance, no operation is
     *            performed.
     */
    public final void addSchemeListener(ISchemeListener schemeListener) {
        if (schemeListener is null) {
            throw new NullPointerException("Can't add a null scheme listener."); //$NON-NLS-1$
        }

        if (listeners is null) {
            listeners = new HashSet();
        }

        listeners.add(cast(Object)schemeListener);
    }

    /*
     * (non-Javadoc)
     *
     * @see java.lang.Comparable#compareTo(java.lang.Object)
     */
    public final int compareTo(Object object) {
        Scheme scheme = cast(Scheme) object;
        int compareTo = Util.compare(this.id, scheme.id);
        if (compareTo is 0) {
            compareTo = Util.compare(this.name, scheme.name);
            if (compareTo is 0) {
                compareTo = Util.compare(this.parentId, scheme.parentId);
                if (compareTo is 0) {
                    compareTo = Util.compare(this.description,
                            scheme.description);
                    if (compareTo is 0) {
                        compareTo = Util.compare(this.defined, scheme.defined);
                    }
                }
            }
        }

        return compareTo;
    }
    public final override int opCmp( Object object ){
        return compareTo( object );
    }

    /**
     * <p>
     * Defines this scheme by giving it a name, and possibly a description and a
     * parent identifier as well. The defined property for the scheme automatically
     * becomes <code>true</code>.
     * </p>
     * <p>
     * Notification is sent to all listeners that something has changed.
     * </p>
     *
     * @param name
     *            The name of this scheme; must not be <code>null</code>.
     * @param description
     *            The description for this scheme; may be <code>null</code>.
     * @param parentId
     *            The parent identifier for this scheme; may be
     *            <code>null</code>.
     */
    public final void define(String name, String description,
            String parentId) {
        if (name is null) {
            throw new NullPointerException(
                    "The name of a scheme cannot be null"); //$NON-NLS-1$
        }

        bool definedChanged = !this.defined;
        this.defined = true;

        bool nameChanged = !Util.opEquals(this.name, name);
        this.name = name;

        bool descriptionChanged = !Util.opEquals(this.description,
                description);
        this.description = description;

        bool parentIdChanged = !Util.opEquals(this.parentId, parentId);
        this.parentId = parentId;

        fireSchemeChanged(new SchemeEvent(this, definedChanged, nameChanged,
                descriptionChanged, parentIdChanged));
    }

    /**
     * Notifies all listeners that this scheme has changed. This sends the given
     * event to all of the listeners, if any.
     *
     * @param event
     *            The event to send to the listeners; must not be
     *            <code>null</code>.
     */
    private final void fireSchemeChanged(SchemeEvent event) {
        if (event is null) {
            throw new NullPointerException(
                    "Cannot send a null event to listeners."); //$NON-NLS-1$
        }

        if (listeners is null) {
            return;
        }

        Iterator listenerItr = listeners.iterator();
        while (listenerItr.hasNext()) {
            final ISchemeListener listener = cast(ISchemeListener) listenerItr
                    .next();
            listener.schemeChanged(event);
        }
    }

    /**
     * <p>
     * Returns the identifier of the parent of the scheme represented by this
     * handle.
     * </p>
     * <p>
     * Notification is sent to all registered listeners if this attribute
     * changes.
     * </p>
     *
     * @return the identifier of the parent of the scheme represented by this
     *         handle. May be <code>null</code>.
     * @throws NotDefinedException
     *             if the scheme represented by this handle is not defined.
     */
    public final String getParentId() {
        if (!defined) {
            throw new NotDefinedException(
                    "Cannot get the parent identifier from an undefined scheme. "  //$NON-NLS-1$
                    ~ id);
        }

        return parentId;
    }

    /**
     * Unregisters an instance of <code>ISchemeListener</code> listening for
     * changes to attributes of this instance.
     *
     * @param schemeListener
     *            the instance of <code>ISchemeListener</code> to unregister.
     *            Must not be <code>null</code>. If an attempt is made to
     *            unregister an instance of <code>ISchemeListener</code> which
     *            is not already registered with this instance, no operation is
     *            performed.
     */
    public final void removeSchemeListener(ISchemeListener schemeListener) {
        if (schemeListener is null) {
            throw new NullPointerException("Cannot remove a null listener."); //$NON-NLS-1$
        }

        if (listeners is null) {
            return;
        }

        listeners.remove(cast(Object)schemeListener);

        if (listeners.isEmpty()) {
            listeners = null;
        }
    }

    /**
     * The string representation of this command -- for debugging purposes only.
     * This string should not be shown to an end user.
     *
     * @return The string representation; never <code>null</code>.
     */
    public override final String toString() {
        if (string is null) {
            string = Format("Scheme({},{},{},{},{})",id,name,description,parentId,defined);
        }
        return string;
    }

    /**
     * Makes this scheme become undefined. This has the side effect of changing
     * the name, description and parent identifier to <code>null</code>.
     * Notification is sent to all listeners.
     */
    public override final void undefine() {
        string = null;

        bool definedChanged = defined;
        defined = false;

        bool nameChanged = name !is null;
        name = null;

        bool descriptionChanged = description !is null;
        description = null;

        bool parentIdChanged = parentId !is null;
        parentId = null;

        fireSchemeChanged(new SchemeEvent(this, definedChanged, nameChanged,
                descriptionChanged, parentIdChanged));
    }
}
