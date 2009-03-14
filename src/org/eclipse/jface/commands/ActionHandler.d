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
module org.eclipse.jface.commands.ActionHandler;


import org.eclipse.swt.widgets.Event;
import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.commands.HandlerEvent;
import org.eclipse.core.commands.IHandlerListener;
import org.eclipse.jface.action.IAction;
import org.eclipse.jface.util.IPropertyChangeListener;
import org.eclipse.jface.util.PropertyChangeEvent;

import java.lang.all;
import java.util.Set;

/**
 * <p>
 * This class adapts instances of <code>IAction</code> to
 * <code>IHandler</code>.
 * </p>
 *
 * @since 3.1
 */
public final class ActionHandler : AbstractHandler {

    /**
     * The wrapped action. This value is never <code>null</code>.
     */
    private const IAction action;

    /**
     * The property change listener hooked on to the action. This is initialized
     * when the first listener is attached to this handler, and is removed when
     * the handler is disposed or the last listener is removed.
     */
    private IPropertyChangeListener propertyChangeListener;

    /**
     * Creates a new instance of this class given an instance of
     * <code>IAction</code>.
     *
     * @param action
     *            the action. Must not be <code>null</code>.
     */
    public this(IAction action) {
        if (action is null) {
            throw new NullPointerException();
        }

        this.action = action;
    }

    public override final void addHandlerListener(IHandlerListener handlerListener) {
        if (!hasListeners()) {
            attachListener();
        }

        super.addHandlerListener(handlerListener);
    }

    /**
     * When a listener is attached to this handler, then this registers a
     * listener with the underlying action.
     *
     * @since 3.1
     */
    private final void attachListener() {
        if (propertyChangeListener is null) {
            propertyChangeListener = new class() IPropertyChangeListener {
                public final void propertyChange(
                        PropertyChangeEvent propertyChangeEvent) {
                    String property = propertyChangeEvent.getProperty();
                    fireHandlerChanged(new HandlerEvent(this.outer,
                            IAction.ENABLED.equals(property), IAction.HANDLED
                                    .equals(property)));
                }
            };
        }

        this.action.addPropertyChangeListener(propertyChangeListener);
    }

    /**
     * When no more listeners are registered, then this is used to removed the
     * property change listener from the underlying action.
     */
    private final void detachListener() {
        this.action.removePropertyChangeListener(propertyChangeListener);
        propertyChangeListener = null;
    }

    /**
     * Removes the property change listener from the action.
     *
     * @see org.eclipse.core.commands.IHandler#dispose()
     */
    public override final void dispose() {
        if (hasListeners()) {
            action.removePropertyChangeListener(propertyChangeListener);
        }
    }

    public final Object execute(ExecutionEvent event) {
        if ((action.getStyle() is IAction.AS_CHECK_BOX)
                || (action.getStyle() is IAction.AS_RADIO_BUTTON)) {
            action.setChecked(!action.isChecked());
        }
        Object trigger = event.getTrigger();
        try {
            if (auto ev = cast(Event)trigger) {
                action.runWithEvent(ev);
            } else {
                action.runWithEvent(new Event());
            }
        } catch (Exception e) {
            throw new ExecutionException(
                    "While executing the action, an exception occurred", e); //$NON-NLS-1$
        }
        return null;
    }

    /**
     * Returns the action associated with this handler
     *
     * @return the action associated with this handler (not null)
     * @since 3.1
     */
    public final IAction getAction() {
        return action;
    }

    public override final bool isEnabled() {
        return action.isEnabled();
    }

    public override final bool isHandled() {
        return action.isHandled();
    }

    public override final void removeHandlerListener(
            IHandlerListener handlerListener) {
        super.removeHandlerListener(handlerListener);

        if (!hasListeners()) {
            detachListener();
        }
    }

    public override final String toString() {
        return "ActionHandler(" ~ (cast(Object)action).toString ~ ")";
    }
}
