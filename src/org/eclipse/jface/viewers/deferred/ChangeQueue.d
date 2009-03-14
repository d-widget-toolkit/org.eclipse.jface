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
module org.eclipse.jface.viewers.deferred.ChangeQueue;


import java.lang.all;
import java.util.LinkedList;
import java.util.Iterator;
import java.util.Set;

/**
 * Holds a queue of additions, removals, updates, and SET calls for a
 * BackgroundContentProvider
 */
final class ChangeQueue {
    /**
     * Represents the addition of an item
     * @since 3.1
     */
    public static const int ADD = 0;
    /**
     * Represents the removal of an item
     * @since 3.1
     */
    public static const int REMOVE = 1;
    /**
     * Represents a reset of all the items
     * @since 3.1
     */
    public static const int SET = 2;
    /**
     * Represents an update of an item
     * @since 3.1
     */
    public static const int UPDATE = 3;

    /**
     *
     * @since 3.1
     */
    public static final class Change {
        private int type;
        private Object[] elements;

        /**
         * Create a change of the specified type that affects the given elements.
         *
         * @param type one of <code>ADD</code>, <code>REMOVE</code>, <code>SET</code>, or <code>UPDATE</code>.
         * @param elements the elements affected by the change.
         *
         * @since 3.1
         */
        public this(int type, Object[] elements) {
            this.type = type;
            this.elements = elements;
        }

        /**
         * Get the type of change.
         * @return one of <code>ADD</code>, <code>REMOVE</code>, <code>SET</code>, or <code>UPDATE</code>.
         *
         * @since 3.1
         */
        public int getType() {
            return type;
        }

        /**
         * Return the elements associated with the change.
         * @return the elements affected by the change.
         *
         * @since 3.1
         */
        public Object[] getElements() {
            return elements;
        }
    }

    private LinkedList queue;
    private int workload = 0;

    public this(){
        queue = new LinkedList();
    }

    /**
     * Create a change of the given type and elements and enqueue it.
     *
     * @param type the type of change to be created
     * @param elements the elements affected by the change
     */
    public synchronized void enqueue(int type, Object[] elements) {
        enqueue(new Change(type, elements));
    }

    /**
     * Add the specified change to the queue
     * @param toQueue the change to be added
     */
    public synchronized void enqueue(Change toQueue) {
        // A SET event makes all previous adds, removes, and sets redundant... so remove
        // them from the queue
        if (toQueue.type is SET) {
            workload = 0;
            LinkedList newQueue = new LinkedList();
            for (Iterator iter = queue.iterator(); iter.hasNext();) {
                Change next = cast(Change) iter.next();

                if (next.getType() is ADD || next.getType() is REMOVE || next.getType() is SET) {
                    continue;
                }

                newQueue.add(next);
                workload += next.elements.length;
            }
            queue = newQueue;
        }

        queue.add(toQueue);
        workload += toQueue.elements.length;
    }

    /**
     * Remove the first change from the queue.
     * @return the first change
     */
    public synchronized Change dequeue() {
        Change result = cast(Change)queue.removeFirst();


        workload -= result.elements.length;
        return result;
    }

    /**
     * Return whether the queue is empty
     * @return <code>true</code> if empty, <code>false</code> otherwise
     */
    public synchronized bool isEmpty() {
        return queue.isEmpty();
    }
}
