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
module org.eclipse.jface.viewers.TreeSelection;

import org.eclipse.jface.viewers.StructuredSelection;
import org.eclipse.jface.viewers.ITreeSelection;
import org.eclipse.jface.viewers.CustomHashtable;
import org.eclipse.jface.viewers.TreePath;
import org.eclipse.jface.viewers.IElementComparer;


import org.eclipse.core.runtime.Assert;

import java.lang.all;
import java.util.List;
import java.util.ArrayList;

/**
 * A concrete implementation of the <code>ITreeSelection</code> interface,
 * suitable for instantiating.
 * <p>
 * This class is not intended to be subclassed.
 * </p>
 *
 * @since 3.2
 */
public class TreeSelection : StructuredSelection, ITreeSelection {

    /* Implementation note.  This class extends StructuredSelection because many pre-existing
     * JFace viewer clients assumed that the only implementation of IStructuredSelection
     * was StructuredSelection.  By extending StructuredSelection rather than implementing
     * ITreeSelection directly, we avoid this problem.
     * For more details, see Bug 121939 [Viewers] TreeSelection should subclass StructuredSelection.
     */

    private TreePath[] paths = null;
    private CustomHashtable element2TreePaths = null;

    /**
     * The canonical empty selection. This selection should be used instead of
     * <code>null</code>.
     */
    public static const TreeSelection EMPTY;

    private static const TreePath[] EMPTY_TREE_PATHS = null;
    static this(){
        EMPTY = new TreeSelection();
    }

    private static class InitializeData {
        List selection;
        TreePath[] paths;
        CustomHashtable element2TreePaths;

        private this(TreePath[] paths, IElementComparer comparer) {
            this.paths= new TreePath[paths.length];
            System.arraycopy(paths, 0, this.paths, 0, paths.length);
            element2TreePaths = new CustomHashtable(comparer);
            int size = paths.length;
            selection = new ArrayList(size);
            for (int i = 0; i < size; i++) {
                Object lastSegment= paths[i].getLastSegment();
                Object mapped= element2TreePaths.get(lastSegment);
                if (mapped is null) {
                    selection.add(lastSegment);
                    element2TreePaths.put(lastSegment, paths[i]);
                } else if ( cast(List)mapped ) {
                    (cast(List)mapped).add( cast(Object)paths[i]);
                } else {
                    List newMapped= new ArrayList();
                    newMapped.add(mapped);
                    newMapped.add(paths[i]);
                    element2TreePaths.put(lastSegment, cast(Object) newMapped);
                }
            }
        }
    }

    /**
     * Constructs a selection based on the elements identified by the given tree
     * paths.
     *
     * @param paths
     *            tree paths
     */
    public this(TreePath[] paths) {
        this(new InitializeData(paths, null));
    }

    /**
     * Constructs a selection based on the elements identified by the given tree
     * paths.
     *
     * @param paths
     *            tree paths
     * @param comparer
     *            the comparer, or <code>null</code> if default equals is to be used
     */
    public this(TreePath[] paths, IElementComparer comparer) {
        this(new InitializeData(paths, comparer));
    }

    /**
     * Constructs a selection based on the elements identified by the given tree
     * path.
     *
     * @param treePath
     *            tree path, or <code>null</code> for an empty selection
     */
    public this(TreePath treePath) {
        this(treePath !is null ? [ treePath ] : EMPTY_TREE_PATHS, null);
    }

    /**
     * Constructs a selection based on the elements identified by the given tree
     * path.
     *
     * @param treePath
     *            tree path, or <code>null</code> for an empty selection
     * @param comparer
     *            the comparer, or <code>null</code> if default equals is to be used
     */
    public this(TreePath treePath, IElementComparer comparer) {
        this(treePath !is null ? [ treePath ] : EMPTY_TREE_PATHS, comparer);
    }

    /**
     * Creates a new tree selection based on the initialization data.
     *
     * @param data the data
     */
    private this(InitializeData data) {
        super(data.selection);
        paths= data.paths;
        element2TreePaths= data.element2TreePaths;
    }

    /**
     * Creates a new empty selection. See also the static field
     * <code>EMPTY</code> which contains an empty selection singleton.
     * <p>
     * Note that TreeSelection.EMPTY is not equals() to StructuredViewer.EMPTY.
     * </p>
     *
     * @see #EMPTY
     */
    public this() {
        super();
    }

    /**
     * Returns the element comparer passed in when the tree selection
     * has been created or <code>null</code> if no comparer has been
     * provided.
     *
     * @return the element comparer or <code>null</code>
     *
     * @since 3.2
     */
    public IElementComparer getElementComparer() {
        if (element2TreePaths is null)
            return null;
        return element2TreePaths.getComparer();
    }

    public override int opEquals(Object obj) {
        if (!(cast(TreeSelection)obj)) {
            // Fall back to super implementation, see bug 135837.
            return super.opEquals(obj);
        }
        TreeSelection selection = cast(TreeSelection) obj;
        int size = getPaths().length;
        if (selection.getPaths().length is size) {
            IElementComparer comparerOrNull = (getElementComparer() is selection
                    .getElementComparer()) ? getElementComparer() : null;
            if (size > 0) {
                for (int i = 0; i < paths.length; i++) {
                    if (!paths[i].opEquals(selection.paths[i], comparerOrNull)) {
                        return false;
                    }
                }
            }
            return true;
        }
        return false;
    }

    public override hash_t toHash() {
        int code = this.classinfo.toHash();
        if (paths !is null) {
            for (int i = 0; i < paths.length; i++) {
                code = code * 17 + paths[i].toHash(getElementComparer());
            }
        }
        return code;
    }

    public TreePath[] getPaths() {
        return paths is null ? EMPTY_TREE_PATHS : paths.dup;
    }

    public TreePath[] getPathsFor(Object element) {
        Object value= element2TreePaths is null ? null : element2TreePaths.get(element);
        if (value is null) {
            return EMPTY_TREE_PATHS;
        } else if (cast(TreePath)value ) {
            return [ cast(TreePath)value ];
        } else if (cast(List)value ) {
            auto l= cast(List)value;
            return arraycast!(TreePath)( l.toArray() );
        } else {
            // should not happen:
            Assert.isTrue(false, "Unhandled case"); //$NON-NLS-1$
            return null;
        }
    }
}
