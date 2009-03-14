/*******************************************************************************
 * Copyright (c) 2005, 2007 IBM Corporation and others.
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

module org.eclipse.jface.viewers.TreeNodeContentProvider;

import org.eclipse.jface.viewers.ITreeContentProvider;
import org.eclipse.jface.viewers.Viewer;
import org.eclipse.jface.viewers.TreeNode;

import java.lang.all;

/**
 * <p>
 * A content provider that expects every element to be a <code>TreeNode</code>.
 * Most methods delegate to <code>TreeNode</code>. <code>dispose()</code>
 * and <code>inputChanged(Viewer, Object, Object)</code> do nothing by
 * default.
 * </p>
 * <p>
 * This class and all of its methods may be overridden or extended.
 * </p>
 *
 * @since 3.2
 * @see org.eclipse.jface.viewers.TreeNode
 */
public class TreeNodeContentProvider : ITreeContentProvider {
    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.viewers.IContentProvider#dispose()
     */
    public void dispose() {
        // Do nothing
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.viewers.ITreeContentProvider#getChildren(java.lang.Object)
     */
    public Object[] getChildren(Object parentElement) {
        TreeNode node = cast(TreeNode) parentElement;
        return node.getChildren();
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.viewers.IStructuredContentProvider#getElements(java.lang.Object)
     */
    public Object[] getElements(Object inputElement) {
        if ( auto tn = cast(ArrayWrapperT!(TreeNode)) inputElement ) {
            return tn.array;
        }
        return null;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.viewers.ITreeContentProvider#getParent(java.lang.Object)
     */
    public Object getParent(Object element) {
        TreeNode node = cast(TreeNode) element;
        return node.getParent();
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.viewers.ITreeContentProvider#hasChildren(java.lang.Object)
     */
    public bool hasChildren(Object element) {
        TreeNode node = cast(TreeNode) element;
        return node.hasChildren();
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.jface.viewers.IContentProvider#inputChanged(org.eclipse.jface.viewers.Viewer,
     *      java.lang.Object, java.lang.Object)
     */
    public void inputChanged(Viewer viewer, Object oldInput,
          Object newInput) {
        // Do nothing
    }
}

