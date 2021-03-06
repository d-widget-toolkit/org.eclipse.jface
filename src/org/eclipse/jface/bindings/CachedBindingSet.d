/*******************************************************************************
 * Copyright (c) 2004, 2007 IBM Corporation and others.
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
module org.eclipse.jface.bindings.CachedBindingSet;

import org.eclipse.jface.bindings.TriggerSequence;
import org.eclipse.jface.bindings.Binding;


import org.eclipse.jface.util.Util;

import java.lang.all;
import java.util.Collection;
import java.util.Map;
import java.util.Set;

/**
 * <p>
 * A resolution of bindings for a given state. To see if we already have a
 * cached binding set, just create one of these binding sets and then look it up
 * in a map. If it is not already there, then add it and set the cached binding
 * resolution.
 * </p>
 *
 * @since 3.1
 */
final class CachedBindingSet {

    /**
     * A factor for computing the hash code for all cached binding sets.
     */
    private const static int HASH_FACTOR = 89;

    /**
     * <p>
     * A representation of the tree of active contexts at the time this cached
     * binding set was computed. It is a map of context id (<code>String</code>)
     * to context id (<code>String</code>). Each key represents one of the
     * active contexts or one of its ancestors, while each value represents its
     * parent. This is a way of perserving information about what the hierarchy
     * looked like.
     * </p>
     * <p>
     * This value will be <code>null</code> if the contexts were disregarded
     * in the computation. It may also be empty. All of the keys are guaranteed
     * to be non- <code>null</code>, but the values can be <code>null</code>
     * (i.e., no parent).
     * </p>
     */
    private const Map activeContextTree;

    /**
     * The map representing the resolved state of the bindings. This is a map of
     * a trigger (<code>TriggerSequence</code>) to binding (<code>Binding</code>).
     * This value may be <code>null</code> if it has not yet been initialized.
     */
    private Map bindingsByTrigger = null;

    /**
     * A map of triggers to collections of bindings. If this binding set
     * contains conflicts, they are logged here.
     *
     * @since 3.3
     */
    private Map conflictsByTrigger = null;

    /**
     * The hash code for this object. This value is computed lazily, and marked
     * as invalid when one of the values on which it is based changes.
     */
    private /+transient+/ int hashCode;

    /**
     * Whether <code>hashCode</code> still contains a valid value.
     */
    private /+transient+/ bool hashCodeComputed = false;

    /**
     * <p>
     * The list of locales that were active at the time this binding set was
     * computed. This list starts with the most specific representation of the
     * locale, and moves to more general representations. For example, this
     * array might look like ["en_US", "en", "", null].
     * </p>
     * <p>
     * This value will never be <code>null</code>, and it will never be
     * empty. It must contain at least one element, but its elements can be
     * <code>null</code>.
     * </p>
     */
    private const String[] locales;

    /**
     * <p>
     * The list of platforms that were active at the time this binding set was
     * computed. This list starts with the most specific representation of the
     * platform, and moves to more general representations. For example, this
     * array might look like ["gtk", "", null].
     * </p>
     * <p>
     * This value will never be <code>null</code>, and it will never be
     * empty. It must contain at least one element, but its elements can be
     * <code>null</code>.
     * </p>
     */
    private const String[] platforms;

    /**
     * A map of prefixes (<code>TriggerSequence</code>) to a map of
     * available completions (possibly <code>null</code>, which means there
     * is an exact match). The available completions is a map of trigger (<code>TriggerSequence</code>)
     * to command identifier (<code>String</code>). This value is
     * <code>null</code> if it has not yet been initialized.
     */
    private Map prefixTable = null;

    /**
     * <p>
     * The list of schemes that were active at the time this binding set was
     * computed. This list starts with the active scheme, and then continues
     * with all of its ancestors -- in order. For example, this might look like
     * ["emacs", "default"].
     * </p>
     * <p>
     * This value will never be <code>null</code>, and it will never be
     * empty. It must contain at least one element. Its elements cannot be
     * <code>null</code>.
     * </p>
     */
    private const String[] schemeIds;

    /**
     * The map representing the resolved state of the bindings. This is a map of
     * a command id (<code>String</code>) to triggers (<code>Collection</code>
     * of <code>TriggerSequence</code>). This value may be <code>null</code>
     * if it has not yet been initialized.
     */
    private Map triggersByCommandId = null;

    /**
     * Constructs a new instance of <code>CachedBindingSet</code>.
     *
     * @param activeContextTree
     *            The set of context identifiers that were active when this
     *            binding set was calculated; may be empty. If it is
     *            <code>null</code>, then the contexts were disregarded in
     *            the computation. This is a map of context id (
     *            <code>String</code>) to parent context id (
     *            <code>String</code>). This is a way of caching the look of
     *            the context tree at the time the binding set was computed.
     * @param locales
     *            The locales that were active when this binding set was
     *            calculated. The first element is the currently active locale,
     *            and it is followed by increasingly more general locales. This
     *            must not be <code>null</code> and must contain at least one
     *            element. The elements can be <code>null</code>, though.
     * @param platforms
     *            The platform that were active when this binding set was
     *            calculated. The first element is the currently active
     *            platform, and it is followed by increasingly more general
     *            platforms. This must not be <code>null</code> and must
     *            contain at least one element. The elements can be
     *            <code>null</code>, though.
     * @param schemeIds
     *            The scheme that was active when this binding set was
     *            calculated, followed by its ancestors. This may be
     *            <code>null</code or empty. The
     *            elements cannot be <code>null</code>.
     */
    this(Map activeContextTree, String[] locales,
            String[] platforms, String[] schemeIds) {
        if (locales is null) {
            throw new NullPointerException("The locales cannot be null."); //$NON-NLS-1$
        }

        if (locales.length is 0) {
            throw new NullPointerException("The locales cannot be empty."); //$NON-NLS-1$
        }

        if (platforms is null) {
            throw new NullPointerException("The platforms cannot be null."); //$NON-NLS-1$
        }

        if (platforms.length is 0) {
            throw new NullPointerException("The platforms cannot be empty."); //$NON-NLS-1$
        }

        this.activeContextTree = activeContextTree;
        this.locales = locales;
        this.platforms = platforms;
        this.schemeIds = schemeIds;
    }

    /**
     * Compares this binding set with another object. The objects will be equal
     * if they are both instance of <code>CachedBindingSet</code> and have
     * equivalent values for all of their properties.
     *
     * @param object
     *            The object with which to compare; may be <code>null</code>.
     * @return <code>true</code> if they are both instances of
     *         <code>CachedBindingSet</code> and have the same values for all
     *         of their properties; <code>false</code> otherwise.
     */
    public final override int opEquals(Object object) {
        if (!(cast(CachedBindingSet)object )) {
            return false;
        }

        CachedBindingSet other = cast(CachedBindingSet) object;

        if (!Util.opEquals(cast(Object)activeContextTree, cast(Object)other.activeContextTree)) {
            return false;
        }
        if (!Util.opEquals(locales, other.locales)) {
            return false;
        }
        if (!Util.opEquals(platforms, other.platforms)) {
            return false;
        }
        return Util.opEquals(schemeIds, other.schemeIds);
    }

    /**
     * Returns the map of command identifiers indexed by trigger sequence.
     *
     * @return A map of triggers (<code>TriggerSequence</code>) to bindings (<code>Binding</code>).
     *         This value may be <code>null</code> if this was not yet
     *         initialized.
     */
    final Map getBindingsByTrigger() {
        return bindingsByTrigger;
    }

    /**
     * Returns a map of conflicts for this set of contexts.
     *
     * @return A map of trigger to a collection of Bindings. May be
     *         <code>null</code>.
     * @since 3.3
     */
    final Map getConflictsByTrigger() {
        return conflictsByTrigger;
    }

    /**
     * Returns the map of prefixes to a map of trigger sequence to command
     * identifiers.
     *
     * @return A map of prefixes (<code>TriggerSequence</code>) to a map of
     *         available completions (possibly <code>null</code>, which means
     *         there is an exact match). The available completions is a map of
     *         trigger (<code>TriggerSequence</code>) to command identifier (<code>String</code>).
     *         This value may be <code>null</code> if it has not yet been
     *         initialized.
     */
    final Map getPrefixTable() {
        return prefixTable;
    }

    /**
     * Returns the map of triggers indexed by command identifiers.
     *
     * @return A map of command identifiers (<code>String</code>) to
     *         triggers (<code>Collection</code> of
     *         <code>TriggerSequence</code>). This value may be
     *         <code>null</code> if this was not yet initialized.
     */
    final Map getTriggersByCommandId() {
        return triggersByCommandId;
    }

    /**
     * Computes the hash code for this cached binding set. The hash code is
     * based only on the immutable values. This allows the set to be created and
     * checked for in a hashed collection <em>before</em> doing any
     * computation.
     *
     * @return The hash code for this cached binding set.
     */
    public final override hash_t toHash() {
        if (!hashCodeComputed) {

            auto HASH_INITIAL = java.lang.all.toHash(CachedBindingSet.classinfo.name );
            hashCode = HASH_INITIAL;
            hashCode = hashCode * HASH_FACTOR
                    + Util.toHash(cast(Object)activeContextTree);
            hashCode = hashCode * HASH_FACTOR + Util.toHash(locales);
            hashCode = hashCode * HASH_FACTOR + Util.toHash(platforms);
            hashCode = hashCode * HASH_FACTOR + Util.toHash(schemeIds);
            hashCodeComputed = true;
        }

        return hashCode;
    }

    /**
     * Sets the map of command identifiers indexed by trigger.
     *
     * @param commandIdsByTrigger
     *            The map to set; must not be <code>null</code>. This is a
     *            map of triggers (<code>TriggerSequence</code>) to binding (<code>Binding</code>).
     */
    final void setBindingsByTrigger(Map commandIdsByTrigger) {
        if (commandIdsByTrigger is null) {
            throw new NullPointerException(
                    "Cannot set a null binding resolution"); //$NON-NLS-1$
        }

        this.bindingsByTrigger = commandIdsByTrigger;
    }

    /**
     * Sets the map of conflicting bindings by trigger.
     *
     * @param conflicts
     *            The map to set; must not be <code>null</code>.
     * @since 3.3
     */
    final void setConflictsByTrigger(Map conflicts) {
        if (conflicts is null) {
            throw new NullPointerException(
                    "Cannot set a null binding conflicts"); //$NON-NLS-1$
        }
        conflictsByTrigger = conflicts;
    }

    /**
     * Sets the map of prefixes to a map of trigger sequence to command
     * identifiers.
     *
     * @param prefixTable
     *            A map of prefixes (<code>TriggerSequence</code>) to a map
     *            of available completions (possibly <code>null</code>, which
     *            means there is an exact match). The available completions is a
     *            map of trigger (<code>TriggerSequence</code>) to command
     *            identifier (<code>String</code>). Must not be
     *            <code>null</code>.
     */
    final void setPrefixTable(Map prefixTable) {
        if (prefixTable is null) {
            throw new NullPointerException("Cannot set a null prefix table"); //$NON-NLS-1$
        }

        this.prefixTable = prefixTable;
    }

    /**
     * Sets the map of triggers indexed by command identifiers.
     *
     * @param triggersByCommandId
     *            The map to set; must not be <code>null</code>. This is a
     *            map of command identifiers (<code>String</code>) to
     *            triggers (<code>Collection</code> of
     *            <code>TriggerSequence</code>).
     */
    final void setTriggersByCommandId(Map triggersByCommandId) {
        if (triggersByCommandId is null) {
            throw new NullPointerException(
                    "Cannot set a null binding resolution"); //$NON-NLS-1$
        }

        this.triggersByCommandId = triggersByCommandId;
    }
}
