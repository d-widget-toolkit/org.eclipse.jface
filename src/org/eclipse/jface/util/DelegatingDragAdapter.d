/*******************************************************************************
 * Copyright (c) 2000, 2006 IBM Corporation and others.
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
module org.eclipse.jface.util.DelegatingDragAdapter;

import org.eclipse.jface.util.TransferDragSourceListener;
import org.eclipse.jface.util.SafeRunnable;


import org.eclipse.swt.dnd.DragSource;
import org.eclipse.swt.dnd.DragSourceEvent;
import org.eclipse.swt.dnd.DragSourceListener;
import org.eclipse.swt.dnd.Transfer;
import org.eclipse.swt.dnd.TransferData;

import java.lang.all;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Set;

/**
 * A <code>DelegatingDragAdapter</code> is a <code>DragSourceListener</code> that
 * maintains and delegates to a set of {@link TransferDragSourceListener}s. Each
 * TransferDragSourceListener can then be implemented as if it were the
 * <code>DragSource's</code> only DragSourceListener.
 * <p>
 * When a drag is started, a subset of all <code>TransferDragSourceListeners</code>
 * is generated and stored in a list of <i>active</i> listeners. This subset is
 * calculated by forwarding {@link DragSourceListener#dragStart(DragSourceEvent)} to
 * every listener, and checking if the {@link DragSourceEvent#doit doit} field is left
 * set to <code>true</code>.
 * </p>
 * The <code>DragSource</code>'s set of supported Transfer types ({@link
 * DragSource#setTransfer(Transfer[])}) is updated to reflect the Transfer types
 * corresponding to the active listener subset.
 * <p>
 * If and when {@link #dragSetData(DragSourceEvent)} is called, a single
 * <code>TransferDragSourceListener</code> is chosen, and only it is allowed to set the
 * drag data. The chosen listener is the first listener in the subset of active listeners
 * whose Transfer supports ({@link Transfer#isSupportedType(TransferData)}) the
 * <code>dataType</code> in the <code>DragSourceEvent</code>.
 * </p>
 * <p>
 * The following example snippet shows a <code>DelegatingDragAdapter</code> with two
 * <code>TransferDragSourceListeners</code>. One implements drag of text strings,
 * the other supports file transfer and demonstrates how a listener can be disabled using
 * the dragStart method.
 * </p>
 * <code><pre>
 *      final TreeViewer viewer = new TreeViewer(shell, SWT.NONE);
 *
 *      DelegatingDragAdapter dragAdapter = new DelegatingDragAdapter();
 *      dragAdapter.addDragSourceListener(new TransferDragSourceListener() {
 *          public Transfer getTransfer() {
 *              return TextTransfer.getInstance();
 *          }
 *          public void dragStart(DragSourceEvent event) {
 *              // always enabled, can control enablement based on selection etc.
 *          }
 *          public void dragSetData(DragSourceEvent event) {
 *              event.data = "Transfer data";
 *          }
 *          public void dragFinished(DragSourceEvent event) {
 *              // no clean-up required
 *          }
 *      });
 *      dragAdapter.addDragSourceListener(new TransferDragSourceListener() {
 *          public Transfer getTransfer() {
 *              return FileTransfer.getInstance();
 *          }
 *          public void dragStart(DragSourceEvent event) {
 *              // enable drag listener if there is a viewer selection
 *              event.doit = !viewer.getSelection().isEmpty();
 *          }
 *          public void dragSetData(DragSourceEvent event) {
 *              File file1 = new File("C:/temp/file1");
 *              File file2 = new File("C:/temp/file2");
 *              event.data = new String[] {file1.getAbsolutePath(), file2.getAbsolutePath()};
 *          }
 *          public void dragFinished(DragSourceEvent event) {
 *              // no clean-up required
 *          }
 *      });
 *      viewer.addDragSupport(DND.DROP_COPY | DND.DROP_MOVE, dragAdapter.getTransfers(), dragAdapter);
 * </pre></code>
 * @since 3.0
 */
public class DelegatingDragAdapter : DragSourceListener {
    private List listeners;

    private List activeListeners;

    private TransferDragSourceListener currentListener;

    this(){
        listeners = new ArrayList();
        activeListeners = new ArrayList();
    }

    /**
     * Adds the given <code>TransferDragSourceListener</code>.
     *
     * @param listener the new listener
     */
    public void addDragSourceListener(TransferDragSourceListener listener) {
        listeners.add(cast(Object)listener);
    }

    /**
     * The drop has successfully completed. This event is forwarded to the current
     * drag listener.
     * Doesn't update the current listener, since the current listener  is already the one
     * that completed the drag operation.
     *
     * @param event the drag source event
     * @see DragSourceListener#dragFinished(DragSourceEvent)
     */
    public void dragFinished(DragSourceEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drag Finished: " + toString()); //$NON-NLS-1$
        SafeRunnable.run(new class(event) SafeRunnable {
            DragSourceEvent event_;
            this(DragSourceEvent a){
                event_=a;
            }
            public void run() {
                if (currentListener !is null) {
                    // there is a listener that can handle the drop, delegate the event
                    currentListener.dragFinished(event_);
                } else {
                    // The drag was canceled and currentListener was never set, so send the
                    // dragFinished event to all the active listeners.
                    Iterator iterator = activeListeners.iterator();
                    while (iterator.hasNext()) {
                        (cast(TransferDragSourceListener) iterator.next())
                                .dragFinished(event);
                    }
                }
            }
        });
        currentListener = null;
        activeListeners.clear();
    }

    /**
     * The drop data is requested.
     * Updates the current listener and then forwards the event to it.
     *
     * @param event the drag source event
     * @see DragSourceListener#dragSetData(DragSourceEvent)
     */
    public void dragSetData(DragSourceEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drag Set Data: " + toString()); //$NON-NLS-1$

        updateCurrentListener(event); // find a listener that can provide the given data type
        if (currentListener !is null) {
            SafeRunnable.run(new class(event) SafeRunnable {
                DragSourceEvent event_;
                this(DragSourceEvent a){
                    event_=a;
                }
                public void run() {
                    currentListener.dragSetData(event_);
                }
            });
        }
    }

    /**
     * A drag operation has started.
     * Forwards this event to each listener. A listener must set <code>event.doit</code>
     * to <code>false</code> if it cannot handle the drag operation. If a listener can
     * handle the drag, it is added to the list of active listeners.
     * The drag is aborted if there are no listeners that can handle it.
     *
     * @param event the drag source event
     * @see DragSourceListener#dragStart(DragSourceEvent)
     */
    public void dragStart(DragSourceEvent event) {
        //      if (Policy.DEBUG_DRAG_DROP)
        //          System.out.println("Drag Start: " + toString()); //$NON-NLS-1$
        bool doit = false; // true if any one of the listeners can handle the drag
        List transfers = new ArrayList(listeners.size());

        activeListeners.clear();
        for (int i = 0; i < listeners.size(); i++) {
            TransferDragSourceListener listener = cast(TransferDragSourceListener) listeners
                    .get(i);
            event.doit = true; // restore event.doit
            SafeRunnable.run(new class(event,listener) SafeRunnable {
                TransferDragSourceListener listener_;
                DragSourceEvent event_;
                this(DragSourceEvent a,TransferDragSourceListener b){
                    event_=a;
                    listener_=b;
                }
                public void run() {
                    listener_.dragStart(event_);
                }
            });
            if (event.doit) { // the listener can handle this drag
                transfers.add(listener.getTransfer());
                activeListeners.add(cast(Object)listener);
            }
            doit |= event.doit;
        }

        if (doit) {
            (cast(DragSource) event.widget).setTransfer(arraycast!(Transfer)( transfers
                    .toArray()));
        }

        event.doit = doit;
    }

    /**
     * Returns the <code>Transfer<code>s from every <code>TransferDragSourceListener</code>.
     *
     * @return the combined <code>Transfer</code>s
     */
    public Transfer[] getTransfers() {
        Transfer[] types = new Transfer[listeners.size()];
        for (int i = 0; i < listeners.size(); i++) {
            TransferDragSourceListener listener = cast(TransferDragSourceListener) listeners
                    .get(i);
            types[i] = listener.getTransfer();
        }
        return types;
    }

    /**
     * Returns <code>true</code> if there are no listeners to delegate drag events to.
     *
     * @return <code>true</code> if there are no <code>TransferDragSourceListeners</code>
     *  <code>false</code> otherwise.
     */
    public bool isEmpty() {
        return listeners.isEmpty();
    }

    /**
     * Removes the given <code>TransferDragSourceListener</code>.
     * Listeners should not be removed while a drag and drop operation is in progress.
     *
     * @param listener the <code>TransferDragSourceListener</code> to remove
     */
    public void removeDragSourceListener(TransferDragSourceListener listener) {
        listeners.remove(cast(Object)listener);
        if (currentListener is listener) {
            currentListener = null;
        }
        if (activeListeners.contains(cast(Object)listener)) {
            activeListeners.remove(cast(Object)listener);
        }
    }

    /**
     * Updates the current listener to one that can handle the drag. There can
     * be many listeners and each listener may be able to handle many <code>TransferData</code>
     * types.  The first listener found that supports one of the <code>TransferData</ode>
     * types specified in the <code>DragSourceEvent</code> will be selected.
     *
     * @param event the drag source event
     */
    private void updateCurrentListener(DragSourceEvent event) {
        currentListener = null;
        if (event.dataType is null) {
            return;
        }
        Iterator iterator = activeListeners.iterator();
        while (iterator.hasNext()) {
            TransferDragSourceListener listener = cast(TransferDragSourceListener) iterator
                    .next();

            if (listener.getTransfer().isSupportedType(event.dataType)) {
                //              if (Policy.DEBUG_DRAG_DROP)
                //                  System.out.println("Current drag listener: " + listener); //$NON-NLS-1$
                currentListener = listener;
                return;
            }
        }
    }

}
