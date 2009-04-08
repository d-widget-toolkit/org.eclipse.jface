/*******************************************************************************
 * Copyright (c) 2000, 2008 IBM Corporation and others.
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
module org.eclipse.jface.action.ActionContributionItem;

import org.eclipse.jface.action.ContributionItem;
import org.eclipse.jface.action.IAction;
import org.eclipse.jface.action.LegacyActionTools;
import org.eclipse.jface.action.Action;
import org.eclipse.jface.action.IMenuCreator;
import org.eclipse.jface.action.IContributionManagerOverrides;

import org.eclipse.swt.SWT;
import org.eclipse.swt.graphics.GC;
import org.eclipse.swt.graphics.Point;
import org.eclipse.swt.widgets.Button;
import org.eclipse.swt.widgets.Composite;
import org.eclipse.swt.widgets.Display;
import org.eclipse.swt.widgets.Event;
import org.eclipse.swt.widgets.Item;
import org.eclipse.swt.widgets.Listener;
import org.eclipse.swt.widgets.Menu;
import org.eclipse.swt.widgets.MenuItem;
import org.eclipse.swt.widgets.ToolBar;
import org.eclipse.swt.widgets.ToolItem;
import org.eclipse.swt.widgets.Widget;
import org.eclipse.jface.action.ExternalActionManager;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.commands.NotEnabledException;
import org.eclipse.jface.bindings.Trigger;
import org.eclipse.jface.bindings.TriggerSequence;
import org.eclipse.jface.bindings.keys.IKeyLookup;
import org.eclipse.jface.bindings.keys.KeyLookupFactory;
import org.eclipse.jface.bindings.keys.KeyStroke;
import org.eclipse.jface.resource.ImageDescriptor;
import org.eclipse.jface.resource.JFaceResources;
import org.eclipse.jface.resource.LocalResourceManager;
import org.eclipse.jface.resource.ResourceManager;
import org.eclipse.jface.util.IPropertyChangeListener;
import org.eclipse.jface.util.Policy;
import org.eclipse.jface.util.PropertyChangeEvent;

import java.lang.all;
import java.util.Set;
import java.lang.Thread;

/**
 * A contribution item which delegates to an action.
 * <p>
 * This class may be instantiated; it is not intended to be subclassed.
 * </p>
 * @noextend This class is not intended to be subclassed by clients.
 */
public class ActionContributionItem : ContributionItem {
    alias ContributionItem.fill fill;

    /**
     * Mode bit: Show text on tool items or buttons, even if an image is
     * present. If this mode bit is not set, text is only shown on tool items if
     * there is no image present.
     *
     * @since 3.0
     */
    public static int MODE_FORCE_TEXT = 1;

    /** a string inserted in the middle of text that has been shortened */
    private static const String ellipsis = "..."; //$NON-NLS-1$

    /**
     * Stores the result of the action. False when the action returned failure.
     */
    private Boolean result = null;

    private static bool USE_COLOR_ICONS = true;

    /**
     * Returns whether color icons should be used in toolbars.
     *
     * @return <code>true</code> if color icons should be used in toolbars,
     *         <code>false</code> otherwise
     */
    public static bool getUseColorIconsInToolbars() {
        return USE_COLOR_ICONS;
    }

    /**
     * Sets whether color icons should be used in toolbars.
     *
     * @param useColorIcons
     *            <code>true</code> if color icons should be used in toolbars,
     *            <code>false</code> otherwise
     */
    public static void setUseColorIconsInToolbars(bool useColorIcons) {
        USE_COLOR_ICONS = useColorIcons;
    }

    /**
     * The presentation mode.
     */
    private int mode = 0;

    /**
     * The action.
     */
    private IAction action;

    /**
     * The listener for changes to the text of the action contributed by an
     * external source.
     */
    private const IPropertyChangeListener actionTextListener;

    /**
     * Remembers all images in use by this contribution item
     */
    private LocalResourceManager imageManager;

    /**
     * Listener for SWT button widget events.
     */
    private Listener buttonListener;

    /**
     * Listener for SWT menu item widget events.
     */
    private Listener menuItemListener;

    /**
     * Listener for action property change notifications.
     */
    private const IPropertyChangeListener propertyListener;

    /**
     * Listener for SWT tool item widget events.
     */
    private Listener toolItemListener;

    /**
     * The widget created for this item; <code>null</code> before creation and
     * after disposal.
     */
    private Widget widget = null;

    private Listener menuCreatorListener;

    /**
     * Creates a new contribution item from the given action. The id of the
     * action is used as the id of the item.
     *
     * @param action
     *            the action
     */
    public this(IAction action) {
        super(action.getId());
        this.action = action;
        actionTextListener = new class IPropertyChangeListener {
            /**
            * @see IPropertyChangeListener#propertyChange(PropertyChangeEvent)
            */
            public void propertyChange(PropertyChangeEvent event) {
                update(event.getProperty());
            }
        };
        propertyListener = new class IPropertyChangeListener {
            public void propertyChange(PropertyChangeEvent event) {
                actionPropertyChange(event);
            }
        };
    }

    /**
     * Handles a property change event on the action (forwarded by nested
     * listener).
     */
    private void actionPropertyChange(PropertyChangeEvent e) {
        // This code should be removed. Avoid using free asyncExec

        if (isVisible() && widget !is null) {
            Display display = widget.getDisplay();
            if (display.getThread() is Thread.currentThread()) {
                update(e.getProperty());
            } else {
                display.asyncExec(dgRunnable( (ActionContributionItem pthis, PropertyChangeEvent e_) {
                    pthis.update(e_.getProperty());
                }, this, e));
            }

        }
    }

    /**
     * Compares this action contribution item with another object. Two action
     * contribution items are equal if they refer to the identical Action.
     */
    public override int opEquals(Object o) {
        if (!(cast(ActionContributionItem)o )) {
            return false;
        }
        return (cast(Object)action).opEquals(cast(Object)(cast(ActionContributionItem) o).action);
    }

    /**
     * The <code>ActionContributionItem</code> implementation of this
     * <code>IContributionItem</code> method creates an SWT
     * <code>Button</code> for the action using the action's style. If the
     * action's checked property has been set, the button is created and primed
     * to the value of the checked property.
     */
    public override void fill(Composite parent) {
        if (widget is null && parent !is null) {
            int flags = SWT.PUSH;
            if (action !is null) {
                if (action.getStyle() is IAction.AS_CHECK_BOX) {
                    flags = SWT.TOGGLE;
                }
                if (action.getStyle() is IAction.AS_RADIO_BUTTON) {
                    flags = SWT.RADIO;
                }
            }

            Button b = new Button(parent, flags);
            b.setData(this);
            b.addListener(SWT.Dispose, getButtonListener());
            // Don't hook a dispose listener on the parent
            b.addListener(SWT.Selection, getButtonListener());
            if (action.getHelpListener() !is null) {
                b.addHelpListener(action.getHelpListener());
            }
            widget = b;

            update(null);

            // Attach some extra listeners.
            action.addPropertyChangeListener(propertyListener);
            if (action !is null) {
                String commandId = action.getActionDefinitionId();
                ExternalActionManager.ICallback callback = ExternalActionManager
                        .getInstance().getCallback();

                if ((callback !is null) && (commandId !is null)) {
                    callback.addPropertyChangeListener(commandId,
                            actionTextListener);
                }
            }
        }
    }

    /**
     * The <code>ActionContributionItem</code> implementation of this
     * <code>IContributionItem</code> method creates an SWT
     * <code>MenuItem</code> for the action using the action's style. If the
     * action's checked property has been set, a button is created and primed to
     * the value of the checked property. If the action's menu creator property
     * has been set, a cascading submenu is created.
     */
    public override void fill(Menu parent, int index) {
        if (widget is null && parent !is null) {
            int flags = SWT.PUSH;
            if (action !is null) {
                int style = action.getStyle();
                if (style is IAction.AS_CHECK_BOX) {
                    flags = SWT.CHECK;
                } else if (style is IAction.AS_RADIO_BUTTON) {
                    flags = SWT.RADIO;
                } else if (style is IAction.AS_DROP_DOWN_MENU) {
                    flags = SWT.CASCADE;
                }
            }

            MenuItem mi = null;
            if (index >= 0) {
                mi = new MenuItem(parent, flags, index);
            } else {
                mi = new MenuItem(parent, flags);
            }
            widget = mi;

            mi.setData(this);
            mi.addListener(SWT.Dispose, getMenuItemListener());
            mi.addListener(SWT.Selection, getMenuItemListener());
            if (action.getHelpListener() !is null) {
                mi.addHelpListener(action.getHelpListener());
            }

            if (flags is SWT.CASCADE) {
                // just create a proxy for now, if the user shows it then
                // fill it in
                Menu subMenu = new Menu(parent);
                subMenu.addListener(SWT.Show, getMenuCreatorListener());
                subMenu.addListener(SWT.Hide, getMenuCreatorListener());
                mi.setMenu(subMenu);
            }

            update(null);

            // Attach some extra listeners.
            action.addPropertyChangeListener(propertyListener);
            if (action !is null) {
                String commandId = action.getActionDefinitionId();
                ExternalActionManager.ICallback callback = ExternalActionManager
                        .getInstance().getCallback();

                if ((callback !is null) && (commandId !is null)) {
                    callback.addPropertyChangeListener(commandId,
                            actionTextListener);
                }
            }
        }
    }

    /**
     * The <code>ActionContributionItem</code> implementation of this ,
     * <code>IContributionItem</code> method creates an SWT
     * <code>ToolItem</code> for the action using the action's style. If the
     * action's checked property has been set, a button is created and primed to
     * the value of the checked property. If the action's menu creator property
     * has been set, a drop-down tool item is created.
     */
    public override void fill(ToolBar parent, int index) {
        if (widget is null && parent !is null) {
            int flags = SWT.PUSH;
            if (action !is null) {
                int style = action.getStyle();
                if (style is IAction.AS_CHECK_BOX) {
                    flags = SWT.CHECK;
                } else if (style is IAction.AS_RADIO_BUTTON) {
                    flags = SWT.RADIO;
                } else if (style is IAction.AS_DROP_DOWN_MENU) {
                    flags = SWT.DROP_DOWN;
                }
            }

            ToolItem ti = null;
            if (index >= 0) {
                ti = new ToolItem(parent, flags, index);
            } else {
                ti = new ToolItem(parent, flags);
            }
            ti.setData(this);
            ti.addListener(SWT.Selection, getToolItemListener());
            ti.addListener(SWT.Dispose, getToolItemListener());

            widget = ti;

            update(null);

            // Attach some extra listeners.
            action.addPropertyChangeListener(propertyListener);
            if (action !is null) {
                String commandId = action.getActionDefinitionId();
                ExternalActionManager.ICallback callback = ExternalActionManager
                        .getInstance().getCallback();

                if ((callback !is null) && (commandId !is null)) {
                    callback.addPropertyChangeListener(commandId,
                            actionTextListener);
                }
            }
        }
    }

    /**
     * Returns the action associated with this contribution item.
     *
     * @return the action
     */
    public IAction getAction() {
        return action;
    }

    /**
     * Returns the listener for SWT button widget events.
     *
     * @return a listener for button events
     */
    private Listener getButtonListener() {
        if (buttonListener is null) {
            buttonListener = new class Listener {
                public void handleEvent(Event event) {
                    switch (event.type) {
                    case SWT.Dispose:
                        handleWidgetDispose(event);
                        break;
                    case SWT.Selection:
                        Widget ew = event.widget;
                        if (ew !is null) {
                            handleWidgetSelection(event, (cast(Button) ew)
                                    .getSelection());
                        }
                        break;
                    default:
                    }
                }
            };
        }
        return buttonListener;
    }

    /**
     * Returns the listener for SWT menu item widget events.
     *
     * @return a listener for menu item events
     */
    private Listener getMenuItemListener() {
        if (menuItemListener is null) {
            menuItemListener = new class Listener {
                public void handleEvent(Event event) {
                    switch (event.type) {
                    case SWT.Dispose:
                        handleWidgetDispose(event);
                        break;
                    case SWT.Selection:
                        Widget ew = event.widget;
                        if (ew !is null) {
                            handleWidgetSelection(event, (cast(MenuItem) ew)
                                    .getSelection());
                        }
                        break;
                    default:
                    }
                }
            };
        }
        return menuItemListener;
    }

    /**
     * Returns the presentation mode, which is the bitwise-or of the
     * <code>MODE_*</code> constants. The default mode setting is 0, meaning
     * that for menu items, both text and image are shown (if present), but for
     * tool items, the text is shown only if there is no image.
     *
     * @return the presentation mode settings
     *
     * @since 3.0
     */
    public int getMode() {
        return mode;
    }

    /**
     * Returns the listener for SWT tool item widget events.
     *
     * @return a listener for tool item events
     */
    private Listener getToolItemListener() {
        if (toolItemListener is null) {
            toolItemListener = new class Listener {
                public void handleEvent(Event event) {
                    switch (event.type) {
                    case SWT.Dispose:
                        handleWidgetDispose(event);
                        break;
                    case SWT.Selection:
                        Widget ew = event.widget;
                        if (ew !is null) {
                            handleWidgetSelection(event, (cast(ToolItem) ew)
                                    .getSelection());
                        }
                        break;
                    default:
                    }
                }
            };
        }
        return toolItemListener;
    }

    /**
     * Handles a widget dispose event for the widget corresponding to this item.
     */
    private void handleWidgetDispose(Event e) {
        // Check if our widget is the one being disposed.
        if (e.widget is widget) {
            // Dispose of the menu creator.
            if (action.getStyle() is IAction.AS_DROP_DOWN_MENU
                    && menuCreatorCalled) {
                IMenuCreator mc = action.getMenuCreator();
                if (mc !is null) {
                    mc.dispose();
                }
            }

            // Unhook all of the listeners.
            action.removePropertyChangeListener(propertyListener);
            if (action !is null) {
                String commandId = action.getActionDefinitionId();
                ExternalActionManager.ICallback callback = ExternalActionManager
                        .getInstance().getCallback();

                if ((callback !is null) && (commandId !is null)) {
                    callback.removePropertyChangeListener(commandId,
                            actionTextListener);
                }
            }

            // Clear the widget field.
            widget = null;

            disposeOldImages();
        }
    }

    /**
     * Handles a widget selection event.
     */
    private void handleWidgetSelection(Event e, bool selection) {

        Widget item = e.widget;
        if (item !is null) {
            int style = item.getStyle();

            if ((style & (SWT.TOGGLE | SWT.CHECK)) !is 0) {
                if (action.getStyle() is IAction.AS_CHECK_BOX) {
                    action.setChecked(selection);
                }
            } else if ((style & SWT.RADIO) !is 0) {
                if (action.getStyle() is IAction.AS_RADIO_BUTTON) {
                    action.setChecked(selection);
                }
            } else if ((style & SWT.DROP_DOWN) !is 0) {
                if (e.detail is 4) { // on drop-down button
                    if (action.getStyle() is IAction.AS_DROP_DOWN_MENU) {
                        IMenuCreator mc = action.getMenuCreator();
                        menuCreatorCalled = true;
                        ToolItem ti = cast(ToolItem) item;
                        // we create the menu as a sub-menu of "dummy" so that
                        // we can use
                        // it in a cascading menu too.
                        // If created on a SWT control we would get an SWT
                        // error...
                        // Menu dummy= new Menu(ti.getParent());
                        // Menu m= mc.getMenu(dummy);
                        // dummy.dispose();
                        if (mc !is null) {
                            Menu m = mc.getMenu(ti.getParent());
                            if (m !is null) {
                                // position the menu below the drop down item
                                Point point = ti.getParent().toDisplay(
                                        new Point(e.x, e.y));
                                m.setLocation(point.x, point.y); // waiting
                                                                    // for SWT
                                // 0.42
                                m.setVisible(true);
                                return; // we don't fire the action
                            }
                        }
                    }
                }
            }

            ExternalActionManager.IExecuteCallback callback = null;
            String actionDefinitionId = action.getActionDefinitionId();
            if (actionDefinitionId !is null) {
                Object obj = cast(Object) ExternalActionManager.getInstance()
                        .getCallback();
                if (null !is cast(ExternalActionManager.IExecuteCallback)obj ) {
                    callback = cast(ExternalActionManager.IExecuteCallback) obj;
                }
            }

            // Ensure action is enabled first.
            // See 1GAN3M6: ITPUI:WINNT - Any IAction in the workbench can be
            // executed while disabled.
            if (action.isEnabled()) {
                bool trace = Policy.TRACE_ACTIONS;

                long ms = 0L;
                if (trace) {
                    ms = System.currentTimeMillis();
                    getDwtLogger.info( __FILE__, __LINE__, "Running action: {}", action.getText()); //$NON-NLS-1$
                }

                IPropertyChangeListener resultListener = null;
                if (callback !is null) {
                    resultListener = new class IPropertyChangeListener {
                        public void propertyChange(PropertyChangeEvent event) {
                            // Check on result
                            if (event.getProperty().equals(IAction.RESULT)) {
                                if (null !is cast(Boolean)event.getNewValue() ) {
                                    result = cast(Boolean) event.getNewValue();
                                }
                            }
                        }
                    };
                    action.addPropertyChangeListener(resultListener);
                    callback.preExecute(action, e);
                }

                action.runWithEvent(e);

                if (callback !is null) {
                    if (result is null || result.opEquals(Boolean.TRUE)) {
                        callback.postExecuteSuccess(action, Boolean.TRUE);
                    } else {
                        callback.postExecuteFailure(action,
                                new ExecutionException(action.getText()
                                        ~ " returned failure.")); //$NON-NLS-1$
                    }
                }

                if (resultListener !is null) {
                    result = null;
                    action.removePropertyChangeListener(resultListener);
                }
                if (trace) {
                    getDwtLogger.info( __FILE__, __LINE__, "{} ms to run action: {}",(System.currentTimeMillis() - ms), action.getText()); //$NON-NLS-1$
                }
            } else {
                if (callback !is null) {
                    callback.notEnabled(action, new NotEnabledException(action
                            .getText()
                            ~ " is not enabled.")); //$NON-NLS-1$
                }
            }
        }
    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    public override hash_t toHash() {
        return (cast(Object)action).toHash();
    }

    /**
     * Returns whether the given action has any images.
     *
     * @param actionToCheck
     *            the action
     * @return <code>true</code> if the action has any images,
     *         <code>false</code> if not
     */
    private bool hasImages(IAction actionToCheck) {
        return actionToCheck.getImageDescriptor() !is null
                || actionToCheck.getHoverImageDescriptor() !is null
                || actionToCheck.getDisabledImageDescriptor() !is null;
    }

    /**
     * Returns whether the command corresponding to this action is active.
     */
    private bool isCommandActive() {
        IAction actionToCheck = getAction();

        if (actionToCheck !is null) {
            String commandId = actionToCheck.getActionDefinitionId();
            ExternalActionManager.ICallback callback = ExternalActionManager
                    .getInstance().getCallback();

            if (callback !is null) {
                return callback.isActive(commandId);
            }
        }
        return true;
    }

    /**
     * The action item implementation of this <code>IContributionItem</code>
     * method returns <code>true</code> for menu items and <code>false</code>
     * for everything else.
     */
    public override bool isDynamic() {
        if (cast(MenuItem)widget ) {
            // Optimization. Only recreate the item is the check or radio style
            // has changed.
            bool itemIsCheck = (widget.getStyle() & SWT.CHECK) !is 0;
            bool actionIsCheck = getAction() !is null
                    && getAction().getStyle() is IAction.AS_CHECK_BOX;
            bool itemIsRadio = (widget.getStyle() & SWT.RADIO) !is 0;
            bool actionIsRadio = getAction() !is null
                    && getAction().getStyle() is IAction.AS_RADIO_BUTTON;
            return (itemIsCheck !is actionIsCheck)
                    || (itemIsRadio !is actionIsRadio);
        }
        return false;
    }

    /*
     * (non-Javadoc) Method declared on IContributionItem.
     */
    public override bool isEnabled() {
        return action !is null && action.isEnabled();
    }

    /**
     * Returns <code>true</code> if this item is allowed to enable,
     * <code>false</code> otherwise.
     *
     * @return if this item is allowed to be enabled
     * @since 2.0
     */
    protected bool isEnabledAllowed() {
        if (getParent() is null) {
            return true;
        }
        auto value = getParent().getOverrides().getEnabled(this);
        return (value is null) ? true : value.value;
    }

    /**
     * The <code>ActionContributionItem</code> implementation of this
     * <code>ContributionItem</code> method extends the super implementation
     * by also checking whether the command corresponding to this action is
     * active.
     */
    public override bool isVisible() {
        return super.isVisible() && isCommandActive();
    }

    /**
     * Sets the presentation mode, which is the bitwise-or of the
     * <code>MODE_*</code> constants.
     *
     * @param mode
     *            the presentation mode settings
     *
     * @since 3.0
     */
    public void setMode(int mode) {
        this.mode = mode;
        update();
    }

    /**
     * The action item implementation of this <code>IContributionItem</code>
     * method calls <code>update(null)</code>.
     */
    public override final void update() {
        update(null);
    }

    /**
     * Synchronizes the UI with the given property.
     *
     * @param propertyName
     *            the name of the property, or <code>null</code> meaning all
     *            applicable properties
     */
    public override void update(String propertyName) {
        if (widget !is null) {
            // determine what to do
            bool textChanged = propertyName is null
                    || propertyName.equals(IAction.TEXT);
            bool imageChanged = propertyName is null
                    || propertyName.equals(IAction.IMAGE);
            bool tooltipTextChanged = propertyName is null
                    || propertyName.equals(IAction.TOOL_TIP_TEXT);
            bool enableStateChanged = propertyName is null
                    || propertyName.equals(IAction.ENABLED)
                    || propertyName
                            .equals(IContributionManagerOverrides.P_ENABLED);
            bool checkChanged = (action.getStyle() is IAction.AS_CHECK_BOX || action
                    .getStyle() is IAction.AS_RADIO_BUTTON)
                    && (propertyName is null || propertyName
                            .equals(IAction.CHECKED));

            if (cast(ToolItem)widget ) {
                ToolItem ti = cast(ToolItem) widget;
                String text = action.getText();
                // the set text is shown only if there is no image or if forced
                // by MODE_FORCE_TEXT
                bool showText = text !is null
                        && ((getMode() & MODE_FORCE_TEXT) !is 0 || !hasImages(action));

                // only do the trimming if the text will be used
                if (showText && text !is null) {
                    text = Action.removeAcceleratorText(text);
                    text = Action.removeMnemonics(text);
                }

                if (textChanged) {
                    String textToSet = showText ? text : ""; //$NON-NLS-1$
                    bool rightStyle = (ti.getParent().getStyle() & SWT.RIGHT) !is 0;
                    if (rightStyle || !ti.getText().equals(textToSet)) {
                        // In addition to being required to update the text if
                        // it
                        // gets nulled out in the action, this is also a
                        // workaround
                        // for bug 50151: Using SWT.RIGHT on a ToolBar leaves
                        // blank space
                        ti.setText(textToSet);
                    }
                }

                if (imageChanged) {
                    // only substitute a missing image if it has no text
                    updateImages(!showText);
                }

                if (tooltipTextChanged || textChanged) {
                    String toolTip = action.getToolTipText();
                    if ((toolTip is null) || (toolTip.length is 0)) {
                        toolTip = text;
                    }

                    ExternalActionManager.ICallback callback = ExternalActionManager
                            .getInstance().getCallback();
                    String commandId = action.getActionDefinitionId();
                    if ((callback !is null) && (commandId !is null)
                            && (toolTip !is null)) {
                        String acceleratorText = callback
                                .getAcceleratorText(commandId);
                        if (acceleratorText !is null
                                && acceleratorText.length !is 0) {
                            toolTip = JFaceResources.format(
                                    "Toolbar_Tooltip_Accelerator", //$NON-NLS-1$
                                    [ toolTip, acceleratorText ]);
                        }
                    }

                    // if the text is showing, then only set the tooltip if
                    // different
                    if (!showText || toolTip !is null && !toolTip.equals(text)) {
                        ti.setToolTipText(toolTip);
                    } else {
                        ti.setToolTipText(null);
                    }
                }

                if (enableStateChanged) {
                    bool shouldBeEnabled = action.isEnabled()
                            && isEnabledAllowed();

                    if (ti.getEnabled() !is shouldBeEnabled) {
                        ti.setEnabled(shouldBeEnabled);
                    }
                }

                if (checkChanged) {
                    bool bv = action.isChecked();

                    if (ti.getSelection() !is bv) {
                        ti.setSelection(bv);
                    }
                }
                return;
            }

            if (cast(MenuItem)widget ) {
                MenuItem mi = cast(MenuItem) widget;

                if (textChanged) {
                    int accelerator = 0;
                    String acceleratorText = null;
                    IAction updatedAction = getAction();
                    String text = null;
                    accelerator = updatedAction.getAccelerator();
                    ExternalActionManager.ICallback callback = ExternalActionManager
                            .getInstance().getCallback();

                    // Block accelerators that are already in use.
                    if ((accelerator !is 0) && (callback !is null)
                            && (callback.isAcceleratorInUse(accelerator))) {
                        accelerator = 0;
                    }

                    /*
                     * Process accelerators on GTK in a special way to avoid Bug
                     * 42009. We will override the native input method by
                     * allowing these reserved accelerators to be placed on the
                     * menu. We will only do this for "Ctrl+Shift+[0-9A-FU]".
                     */
                    String commandId = updatedAction
                            .getActionDefinitionId();
                    if (("gtk".equals(SWT.getPlatform())) && (cast(ExternalActionManager.IBindingManagerCallback)callback ) //$NON-NLS-1$
                            && (commandId !is null)) {
                        ExternalActionManager.IBindingManagerCallback bindingManagerCallback = cast(ExternalActionManager.IBindingManagerCallback) callback;
                        IKeyLookup lookup = KeyLookupFactory.getDefault();
                        TriggerSequence[] triggerSequences = bindingManagerCallback
                                .getActiveBindingsFor(commandId);
                        for (int i = 0; i < triggerSequences.length; i++) {
                            TriggerSequence triggerSequence = triggerSequences[i];
                            Trigger[] triggers = triggerSequence
                                    .getTriggers();
                            if (triggers.length is 1) {
                                Trigger trigger = triggers[0];
                                if (cast(KeyStroke)trigger ) {
                                    KeyStroke currentKeyStroke = cast(KeyStroke) trigger;
                                    int currentNaturalKey = currentKeyStroke
                                            .getNaturalKey();
                                    if ((currentKeyStroke.getModifierKeys() is (lookup
                                            .getCtrl() | lookup.getShift()))
                                            && ((currentNaturalKey >= '0' && currentNaturalKey <= '9')
                                                    || (currentNaturalKey >= 'A' && currentNaturalKey <= 'F') || (currentNaturalKey is 'U'))) {
                                        accelerator = currentKeyStroke
                                                .getModifierKeys()
                                                | currentNaturalKey;
                                        acceleratorText = triggerSequence
                                                .format();
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    if (accelerator is 0) {
                        if ((callback !is null) && (commandId !is null)) {
                            acceleratorText = callback
                                    .getAcceleratorText(commandId);
                        }
                    }

                    IContributionManagerOverrides overrides = null;

                    if (getParent() !is null) {
                        overrides = getParent().getOverrides();
                    }

                    if (overrides !is null) {
                        text = getParent().getOverrides().getText(this);
                    }

                    mi.setAccelerator(accelerator);

                    if (text is null) {
                        text = updatedAction.getText();
                    }

                    if (text !is null && acceleratorText is null) {
                        // use extracted accelerator text in case accelerator
                        // cannot be fully represented in one int (e.g.
                        // multi-stroke keys)
                        acceleratorText = LegacyActionTools
                                .extractAcceleratorText(text);
                        if (acceleratorText is null && accelerator !is 0) {
                            acceleratorText = Action
                                    .convertAccelerator(accelerator);
                        }
                    }

                    if (text is null) {
                        text = ""; //$NON-NLS-1$
                    } else {
                        text = Action.removeAcceleratorText(text);
                    }

                    if (acceleratorText is null) {
                        mi.setText(text);
                    } else {
                        mi.setText(text ~ '\t' ~ acceleratorText);
                    }
                }

                if (imageChanged) {
                    updateImages(false);
                }

                if (enableStateChanged) {
                    bool shouldBeEnabled = action.isEnabled()
                            && isEnabledAllowed();

                    if (mi.getEnabled() !is shouldBeEnabled) {
                        mi.setEnabled(shouldBeEnabled);
                    }
                }

                if (checkChanged) {
                    bool bv = action.isChecked();

                    if (mi.getSelection() !is bv) {
                        mi.setSelection(bv);
                    }
                }

                return;
            }

            if (cast(Button)widget ) {
                Button button = cast(Button) widget;

                if (imageChanged) {
                    updateImages(false);
                }

                if (textChanged) {
                    String text = action.getText();
                    bool showText = text !is null && ((getMode() & MODE_FORCE_TEXT) !is 0 || !hasImages(action));
                    // only do the trimming if the text will be used
                    if (showText) {
                        text = Action.removeAcceleratorText(text);
                    }
                    String textToSet = showText ? text : ""; //$NON-NLS-1$
                    button.setText(textToSet);
                }

                if (tooltipTextChanged) {
                    button.setToolTipText(action.getToolTipText());
                }

                if (enableStateChanged) {
                    bool shouldBeEnabled = action.isEnabled()
                            && isEnabledAllowed();

                    if (button.getEnabled() !is shouldBeEnabled) {
                        button.setEnabled(shouldBeEnabled);
                    }
                }

                if (checkChanged) {
                    bool bv = action.isChecked();

                    if (button.getSelection() !is bv) {
                        button.setSelection(bv);
                    }
                }
                return;
            }
        }
    }

    /**
     * Updates the images for this action.
     *
     * @param forceImage
     *            <code>true</code> if some form of image is compulsory, and
     *            <code>false</code> if it is acceptable for this item to have
     *            no image
     * @return <code>true</code> if there are images for this action,
     *         <code>false</code> if not
     */
    private bool updateImages(bool forceImage) {

        ResourceManager parentResourceManager = JFaceResources.getResources();

        if (cast(ToolItem)widget ) {
            if (USE_COLOR_ICONS) {
                ImageDescriptor image = action.getHoverImageDescriptor();
                if (image is null) {
                    image = action.getImageDescriptor();
                }
                ImageDescriptor disabledImage = action
                        .getDisabledImageDescriptor();

                // Make sure there is a valid image.
                if (image is null && forceImage) {
                    image = ImageDescriptor.getMissingImageDescriptor();
                }

                LocalResourceManager localManager = new LocalResourceManager(
                        parentResourceManager);

                // performance: more efficient in SWT to set disabled and hot
                // image before regular image
                (cast(ToolItem) widget)
                        .setDisabledImage(disabledImage is null ? null
                                : localManager
                                        .createImageWithDefault(disabledImage));
                (cast(ToolItem) widget).setImage(image is null ? null
                        : localManager.createImageWithDefault(image));

                disposeOldImages();
                imageManager = localManager;

                return image !is null;
            }
            ImageDescriptor image = action.getImageDescriptor();
            ImageDescriptor hoverImage = action.getHoverImageDescriptor();
            ImageDescriptor disabledImage = action.getDisabledImageDescriptor();

            // If there is no regular image, but there is a hover image,
            // convert the hover image to gray and use it as the regular image.
            if (image is null && hoverImage !is null) {
                image = ImageDescriptor.createWithFlags(action
                        .getHoverImageDescriptor(), SWT.IMAGE_GRAY);
            } else {
                // If there is no hover image, use the regular image as the
                // hover image,
                // and convert the regular image to gray
                if (hoverImage is null && image !is null) {
                    hoverImage = image;
                    image = ImageDescriptor.createWithFlags(action
                            .getImageDescriptor(), SWT.IMAGE_GRAY);
                }
            }

            // Make sure there is a valid image.
            if (hoverImage is null && image is null && forceImage) {
                image = ImageDescriptor.getMissingImageDescriptor();
            }

            // Create a local resource manager to remember the images we've
            // allocated for this tool item
            LocalResourceManager localManager = new LocalResourceManager(
                    parentResourceManager);

            // performance: more efficient in SWT to set disabled and hot image
            // before regular image
            (cast(ToolItem) widget).setDisabledImage(disabledImage is null ? null
                    : localManager.createImageWithDefault(disabledImage));
            (cast(ToolItem) widget).setHotImage(hoverImage is null ? null
                    : localManager.createImageWithDefault(hoverImage));
            (cast(ToolItem) widget).setImage(image is null ? null : localManager
                    .createImageWithDefault(image));

            // Now that we're no longer referencing the old images, clear them
            // out.
            disposeOldImages();
            imageManager = localManager;

            return image !is null;
        } else if (cast(Item)widget  || cast(Button)widget ) {

            // Use hover image if there is one, otherwise use regular image.
            ImageDescriptor image = action.getHoverImageDescriptor();
            if (image is null) {
                image = action.getImageDescriptor();
            }
            // Make sure there is a valid image.
            if (image is null && forceImage) {
                image = ImageDescriptor.getMissingImageDescriptor();
            }

            // Create a local resource manager to remember the images we've
            // allocated for this widget
            LocalResourceManager localManager = new LocalResourceManager(
                    parentResourceManager);

            if (cast(Item)widget) {
                (cast(Item) widget).setImage(image is null ? null : localManager
                        .createImageWithDefault(image));
            } else if (cast(Button)widget) {
                (cast(Button) widget).setImage(image is null ? null : localManager
                        .createImageWithDefault(image));
            }

            // Now that we're no longer referencing the old images, clear them
            // out.
            disposeOldImages();
            imageManager = localManager;

            return image !is null;
        }
        return false;
    }

    /**
     * Dispose any images allocated for this contribution item
     */
    private void disposeOldImages() {
        if (imageManager !is null) {
            imageManager.dispose();
            imageManager = null;
        }
    }

    /**
     * Shorten the given text <code>t</code> so that its length doesn't exceed
     * the width of the given ToolItem.The default implementation replaces
     * characters in the center of the original string with an ellipsis ("...").
     * Override if you need a different strategy.
     *
     * @param textValue
     *            the text to shorten
     * @param item
     *            the tool item the text belongs to
     * @return the shortened string
     *
     */
    protected String shortenText(String textValue, ToolItem item) {
        if (textValue is null) {
            return null;
        }

        GC gc = new GC(item.getParent());

        int maxWidth = item.getImage().getBounds().width * 4;

        if (gc.textExtent(textValue).x < maxWidth) {
            gc.dispose();
            return textValue;
        }

        for (int i = textValue.length; i > 0; i--) {
            String test = textValue.substring(0, i);
            test = test ~ ellipsis;
            if (gc.textExtent(test).x < maxWidth) {
                gc.dispose();
                return test;
            }

        }
        gc.dispose();
        // If for some reason we fall through abort
        return textValue;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.action.ContributionItem#dispose()
     */
    public void dispose() {
        if (widget !is null) {
            widget.dispose();
            widget = null;
        }
        holdMenu = null;
    }

    /**
     * Handle show and hide on the proxy menu for IAction.AS_DROP_DOWN_MENU
     * actions.
     *
     * @return the appropriate listener
     * @since 3.4
     */
    private Listener getMenuCreatorListener() {
        if (menuCreatorListener is null) {
            menuCreatorListener = new class Listener {
                public void handleEvent(Event event) {
                    switch (event.type) {
                    case SWT.Show:
                        handleShowProxy(cast(Menu) event.widget);
                        break;
                    case SWT.Hide:
                        handleHideProxy(cast(Menu) event.widget);
                        break;
                    default:
                    }
                }
            };
        }
        return menuCreatorListener;
    }

    /**
     * This is the easiest way to hold the menu until we can swap it in to the
     * proxy.
     */
    private Menu holdMenu = null;

    private bool menuCreatorCalled = false;

    /**
     * The proxy menu is being shown, we better get the real menu.
     *
     * @param proxy
     *            the proxy menu
     * @since 3.4
     */
    private void handleShowProxy(Menu proxy) {
        proxy.removeListener(SWT.Show, getMenuCreatorListener());
        IMenuCreator mc = action.getMenuCreator();
        menuCreatorCalled  = true;
        if (mc is null) {
            return;
        }
        holdMenu = mc.getMenu(proxy.getParentMenu());
        if (holdMenu is null) {
            return;
        }
        copyMenu(holdMenu, proxy);
    }

    /**
     * Create MenuItems in the proxy menu that can execute the real menu items
     * if selected. Create proxy menus for any real item submenus.
     *
     * @param realMenu
     *            the real menu to copy from
     * @param proxy
     *            the proxy menu to populate
     * @since 3.4
     */
    private void copyMenu(Menu realMenu, Menu proxy) {
        if (realMenu.isDisposed() || proxy.isDisposed()) {
            return;
        }

        // we notify the real menu so it can populate itself if it was
        // listening for SWT.Show
        realMenu.notifyListeners(SWT.Show, null);

        final Listener passThrough = new class Listener {
            public void handleEvent(Event event) {
                if (!event.widget.isDisposed()) {
                    Widget realItem = cast(Widget) event.widget.getData();
                    if (!realItem.isDisposed()) {
                        int style = event.widget.getStyle();
                        if (event.type is SWT.Selection
                                && ((style & (SWT.TOGGLE | SWT.CHECK)) !is 0)
                                && (null !is cast(MenuItem)realItem )) {
                            (cast(MenuItem) realItem)
                                    .setSelection((cast(MenuItem) event.widget)
                                            .getSelection());
                        }
                        event.widget = realItem;
                        realItem.notifyListeners(event.type, event);
                    }
                }
            }
        };

        MenuItem[] items = realMenu.getItems();
        for (int i = 0; i < items.length; i++) {
            final MenuItem realItem = items[i];
            final MenuItem proxyItem = new MenuItem(proxy, realItem.getStyle());
            proxyItem.setData(realItem);
            proxyItem.setAccelerator(realItem.getAccelerator());
            proxyItem.setEnabled(realItem.getEnabled());
            proxyItem.setImage(realItem.getImage());
            proxyItem.setSelection(realItem.getSelection());
            proxyItem.setText(realItem.getText());

            // pass through any events
            proxyItem.addListener(SWT.Selection, passThrough);
            proxyItem.addListener(SWT.Arm, passThrough);
            proxyItem.addListener(SWT.Help, passThrough);

            final Menu itemMenu = realItem.getMenu();
            if (itemMenu !is null) {
                // create a proxy for any sub menu items
                final Menu subMenu = new Menu(proxy);
                subMenu.setData(itemMenu);
                proxyItem.setMenu(subMenu);
                subMenu.addListener(SWT.Show, new class(subMenu, itemMenu) Listener {
                    Menu subMenu_;
                    Menu itemMenu_;
                    this(Menu a,Menu b){
                        subMenu_=a;
                        itemMenu_=b;
                    }
                    void handleEvent(Event event){
                        event.widget.removeListener(SWT.Show, this);
                        if (event.type is SWT.Show) {
                            copyMenu(itemMenu_, subMenu_);
                        }
                    }
                });
                subMenu.addListener(SWT.Help, passThrough);
                subMenu.addListener(SWT.Hide, passThrough);
            }
        }
    }

    /**
     * The proxy menu is being hidden, so we need to make it go away.
     *
     * @param proxy
     *            the proxy menu
     * @since 3.4
     */
    private void handleHideProxy(Menu proxy) {
        proxy.removeListener(SWT.Hide, getMenuCreatorListener());
        proxy.getDisplay().asyncExec(dgRunnable( (Menu proxy_) {
                if (!proxy_.isDisposed()) {
                    MenuItem parentItem = proxy_.getParentItem();
                    proxy_.dispose();
                    parentItem.setMenu(holdMenu);
                }
                if (holdMenu !is null && !holdMenu.isDisposed()) {
                    holdMenu.notifyListeners(SWT.Hide, null);
                }
                holdMenu = null;
        }, proxy ));
    }

    /**
     * Return the widget associated with this contribution item. It should not
     * be cached, as it can be disposed and re-created by its containing
     * ContributionManager, which controls all of the widgets lifecycle methods.
     * <p>
     * This can be used to set layout data on the widget if appropriate. The
     * actual type of the widget can be any valid control for this
     * ContributionItem's current ContributionManager.
     * </p>
     *
     * @return the widget, or <code>null</code> depending on the lifecycle.
     * @since 3.4
     */
    public Widget getWidget() {
        return widget;
    }
}
