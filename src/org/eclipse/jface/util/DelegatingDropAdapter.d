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
module org.eclipse.jface.util.DelegatingDropAdapter;

import org.eclipse.jface.util.TransferDropTargetListener;
import org.eclipse.jface.util.SafeRunnable;


import org.eclipse.swt.dnd.DND;
import org.eclipse.swt.dnd.DropTargetEvent;
import org.eclipse.swt.dnd.DropTargetListener;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.TransferData;

import java.lang.all;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

/**
 * A <code>DelegatingDropAdapter</code> is a <code>DropTargetListener</code> that
 * maintains and delegates to a set of {@link TransferDropTargetListener}s. Each
 * <code>TransferDropTargetListener</code> can then be implemented as if it were
 * the DropTarget's only <code>DropTargetListener</code>.
 * <p>
 * On <code>dragEnter</code>, <code>dragOperationChanged</code>, <code>dragOver</code>
 * and <code>drop</code>, a <i>current</i> listener is obtained from the set of all
 * <code>TransferDropTargetListeners</code>. The current listener is the first listener
 * to return <code>true</code> for
 * {@link TransferDropTargetListener#isEnabled(DropTargetEvent)}.
 * The current listener is forwarded all <code>DropTargetEvents</code> until some other
 * listener becomes the current listener, or the drop terminates.
 * </p>
 * <p>
 * After adding all <code>TransferDropTargetListeners</code> to the
 * <code>DelegatingDropAdapter</code> the combined set of <code>Transfers</code> should
 * be set in the SWT <code>DropTarget</code>. <code>#getTransfers()</code> provides the
 * set of <code>Transfer</code> types of all <code>TransferDropTargetListeners</code>.
 * </p>
 * <p>
 * The following example snippet shows a <code>DelegatingDropAdapter</code> with two
 * <code>TransferDropTargetListeners</code>. One supports dropping resources and
 * demonstrates how a listener can be disabled in the isEnabled method.
 * The other listener supports text transfer.
 * </p>
 * <code><pre>
 *      final TreeViewer viewer = new TreeViewer(shell, SWT.NONE);
 *      DelegatingDropAdapter dropAdapter = new DelegatingDropAdapter();
 *      dropAdapter.addDropTargetListener(new TransferDropTargetListener() {
 *          public Transfer getTransfer() {
 *              return ResourceTransfer.getInstance();
 *          }
 *          public bool isEnabled(DropTargetEvent event) {
 *              // disable drop listener if there is no viewer selection
 *              if (viewer.getSelection().isEmpty())
 *                  return false;
 *              return true;
 *          }
 *          public void dragEnter(DropTargetEvent event) {}
 *          public void dragLeave(DropTargetEvent event) {}
 *          public void dragOperationChanged(DropTargetEvent event) {}
 *          public void dragOver(DropTargetEvent event) {}
 *          public void drop(DropTargetEvent event) {
 *              if (event.data is null)
 *                  return;
 *              IResource[] resources = (IResource[]) event.data;
 *              if (event.detail is DND.DROP_COPY) {
 *                  // copy resources
 *              } else {
 *                  // move resources
 *              }
 *
 *          }
 *          public void dropAccept(DropTargetEvent event) {}
 *      });
 *      dropAdapter.addDropTargetListener(new TransferDropTargetListener() {
 *          public Transfer getTransfer() {
 *              return TextTransfer.getInstance();
 *          }
 *          public bool isEnabled(DropTargetEvent event) {
 *              return true;
 *          }
 *          public void dragEnter(DropTargetEvent event) {}
 *          public void dragLeave(DropTargetEvent event) {}
 *          public void dragOperationChanged(DropTargetEvent event) {}
 *          public void dragOver(DropTargetEvent event) {}
 *          public void drop(DropTargetEvent event) {
 *              if (event.data is null)
 *                  return;
 *              System.out.println(event.data);
 *          }
 *          public void dropAccept(DropTargetEvent event) {}
 *      });
 *      viewer.addDropSupport(DND.DROP_COPY | DND.DROP_MOVE, dropAdapter.getTransfers(), dropAdapter);
 * </pre></code>
 * @since 3.0
 */
public class DelegatingDropAdapter : DropTargetListener {
    private List listeners;

    private TransferDropTargetListener currentListener;

    private int originalDropType;

    this(){
        listeners = new ArrayList();
    }

    /**
     * Adds the given <code>TransferDropTargetListener</code>.
     *
     * @param listener the new listener
     */
    public void addDropTargetListener(TransferDropTargetListener listener) {
        listeners.add(cast(Object)listener);
    }

    /**
     * The cursor has entered the drop target boundaries. The current listener is
     * updated, and <code>#dragEnter()</code> is forwarded to the current listener.
     *
     * @param event the drop target event
     * @see DropTargetListener#dragEnter(DropTargetEvent)
     */
    public void dragEnter(DropTargetEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drag Enter: " + toString()); //$NON-NLS-1$
        originalDropType = event.detail;
        updateCurrentListener(event);
    }

    /**
     * The cursor has left the drop target boundaries. The event is forwarded to the
     * current listener.
     *
     * @param event the drop target event
     * @see DropTargetListener#dragLeave(DropTargetEvent)
     */
    public void dragLeave(DropTargetEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drag Leave: " + toString()); //$NON-NLS-1$
        setCurrentListener(null, event);
    }

    /**
     * The operation being performed has changed (usually due to the user changing
     * a drag modifier key while dragging). Updates the current listener and forwards
     * this event to that listener.
     *
     * @param event the drop target event
     * @see DropTargetListener#dragOperationChanged(DropTargetEvent)
     */
    public void dragOperationChanged(DropTargetEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drag Operation Changed to: " + event.detail); //$NON-NLS-1$
        originalDropType = event.detail;
        TransferDropTargetListener oldListener = getCurrentListener();
        updateCurrentListener(event);
        TransferDropTargetListener newListener = getCurrentListener();
        // only notify the current listener if it hasn't changed based on the
        // operation change. otherwise the new listener would get a dragEnter
        // followed by a dragOperationChanged with the exact same event.
        if (newListener !is null && newListener is oldListener) {
            SafeRunnable.run(new class(event,newListener) SafeRunnable {
                DropTargetEvent event_;
                TransferDropTargetListener newListener_;
                this(DropTargetEvent a,TransferDropTargetListener b){
                    event_=a;
                    newListener_=b;
                }
                public void run() {
                    newListener_.dragOperationChanged(event_);
                }
            });
        }
    }

    /**
     * The cursor is moving over the drop target. Updates the current listener and
     * forwards this event to that listener. If no listener can handle the drag
     * operation the <code>event.detail</code> field is set to <code>DND.DROP_NONE</code>
     * to indicate an invalid drop.
     *
     * @param event the drop target event
     * @see DropTargetListener#dragOver(DropTargetEvent)
     */
    public void dragOver(DropTargetEvent event) {
        TransferDropTargetListener oldListener = getCurrentListener();
        updateCurrentListener(event);
        TransferDropTargetListener newListener = getCurrentListener();

        // only notify the current listener if it hasn't changed based on the
        // drag over. otherwise the new listener would get a dragEnter
        // followed by a dragOver with the exact same event.
        if (newListener !is null && newListener is oldListener) {
            SafeRunnable.run(new class(event,newListener) SafeRunnable {
                DropTargetEvent event_;
                TransferDropTargetListener newListener_;
                this(DropTargetEvent a,TransferDropTargetListener b){
                    event_=a;
                    newListener_=b;
                }
                public void run() {
                    newListener_.dragOver(event_);
                }
            });
        }
    }

    /**
     * Forwards this event to the current listener, if there is one. Sets the
     * current listener to <code>null</code> afterwards.
     *
     * @param event the drop target event
     * @see DropTargetListener#drop(DropTargetEvent)
     */
    public void drop(DropTargetEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drop: " + toString()); //$NON-NLS-1$
        updateCurrentListener(event);
        if (getCurrentListener() !is null) {
            SafeRunnable.run(new class(event) SafeRunnable {
                DropTargetEvent event_;
                this(DropTargetEvent a){ event_=a;}
                public void run() {
                    getCurrentListener().drop(event_);
                }
            });
        }
        setCurrentListener(null, event);
    }

    /**
     * Forwards this event to the current listener if there is one.
     *
     * @param event the drop target event
     * @see DropTargetListener#dropAccept(DropTargetEvent)
     */
    public void dropAccept(DropTargetEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drop Accept: " + toString()); //$NON-NLS-1$
        if (getCurrentListener() !is null) {
            SafeRunnable.run(new class(event) SafeRunnable {
                DropTargetEvent event_;
                this(DropTargetEvent a){ event_=a;}
                public void run() {
                    getCurrentListener().dropAccept(event_);
                }
            });
        }
    }

    /**
     * Returns the listener which currently handles drop events.
     *
     * @return the <code>TransferDropTargetListener</code> which currently
     *  handles drop events.
     */
    private TransferDropTargetListener getCurrentListener() {
        return currentListener;
    }

    /**
     * Returns the transfer data type supported by the given listener.
     * Returns <code>null</code> if the listener does not support any of the
     * specified data types.
     *
     * @param dataTypes available data types
     * @param listener <code>TransferDropTargetListener</code> to use for testing
     *  supported data types.
     * @return the transfer data type supported by the given listener or
     *  <code>null</code>.
     */
    private TransferData getSupportedTransferType(TransferData[] dataTypes,
            TransferDropTargetListener listener) {
        for (int i = 0; i < dataTypes.length; i++) {
            if (listener.getTransfer().isSupportedType(dataTypes[i])) {
                return dataTypes[i];
            }
        }
        return null;
    }

    /**
     * Returns the combined set of <code>Transfer</code> types of all
     * <code>TransferDropTargetListeners</code>.
     *
     * @return the combined set of <code>Transfer</code> types
     */
    public Transfer[] getTransfers() {
        Transfer[] types = new Transfer[listeners.size()];
        for (int i = 0; i < listeners.size(); i++) {
            TransferDropTargetListener listener = cast(TransferDropTargetListener) listeners
                    .get(i);
            types[i] = listener.getTransfer();
        }
        return types;
    }

    /**
     * Returns <code>true</code> if there are no listeners to delegate events to.
     *
     * @return <code>true</code> if there are no <code>TransferDropTargetListeners</code>
     *  <code>false</code> otherwise
     */
    public bool isEmpty() {
        return listeners.isEmpty();
    }

    /**
     * Removes the given <code>TransferDropTargetListener</code>.
     * Listeners should not be removed while a drag and drop operation is in progress.
     *
     * @param listener the listener to remove
     */
    public void removeDropTargetListener(TransferDropTargetListener listener) {
        if (currentListener is listener) {
            currentListener = null;
        }
        listeners.remove(cast(Object)listener);
    }

    /**
     * Sets the current listener to <code>listener</code>. Sends the given
     * <code>DropTargetEvent</code> if the current listener changes.
     *
     * @return <code>true</code> if the new listener is different than the previous
     *  <code>false</code> otherwise
     */
    private bool setCurrentListener(TransferDropTargetListener listener,
            DropTargetEvent event) {
        if (currentListener is listener) {
            return false;
        }
        if (currentListener !is null) {
            SafeRunnable.run(new class(event) SafeRunnable {
                DropTargetEvent event_;
                this(DropTargetEvent a){ event_=a;}
                public void run() {
                    currentListener.dragLeave(event_);
                }
            });
        }
        currentListener = listener;
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Current drop listener: " + listener); //$NON-NLS-1$
        if (currentListener !is null) {
            SafeRunnable.run(new class(event) SafeRunnable {
                DropTargetEvent event_;
                this(DropTargetEvent a){ event_=a;}
                public void run() {
                    currentListener.dragEnter(event_);
                }
            });
        }
        return true;
    }

    /**
     * Updates the current listener to one that can handle the drop. There can be many
     * listeners and each listener may be able to handle many <code>TransferData</code>
     * types. The first listener found that can handle a drop of one of the given
     * <code>TransferData</code> types will be selected.
     * If no listener can handle the drag operation the <code>event.detail</code> field
     * is set to <code>DND.DROP_NONE</code> to indicate an invalid drop.
     *
     * @param event the drop target event
     */
    private void updateCurrentListener(DropTargetEvent event) {
        int originalDetail = event.detail;
        // revert the detail to the "original" drop type that the User indicated.
        // this is necessary because the previous listener may have changed the detail
        // to something other than what the user indicated.
        event.detail = originalDropType;

        Iterator iter = listeners.iterator();
        while (iter.hasNext()) {
            TransferDropTargetListener listener = cast(TransferDropTargetListener) iter
                    .next();
            TransferData dataType = getSupportedTransferType(event.dataTypes,
                    listener);
            if (dataType !is null) {
                TransferData originalDataType = event.currentDataType;
                // set the data type supported by the drop listener
                event.currentDataType = dataType;
                if (listener.isEnabled(event)) {
                    // if the listener stays the same, set its previously determined
                    // event detail
                    if (!setCurrentListener(listener, event)) {
                        event.detail = originalDetail;
                    }
                    return;
                }
                event.currentDataType = originalDataType;
            }
        }
        setCurrentListener(null, event);
        event.detail = DND.DROP_NONE;

        // -always- ensure that expand/scroll are on...otherwise
        // if a valid drop target is a child of an invalid one
        // you can't get there...
        event.feedback = DND.FEEDBACK_EXPAND | DND.FEEDBACK_SCROLL;
    }
}
