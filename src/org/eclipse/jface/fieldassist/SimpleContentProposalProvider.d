/*******************************************************************************
 * Copyright (c) 2005, 2007 IBM Corporation and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     IBM Corporation - initial API and implementation
 *     Amir Kouchekinia <amir@pyrus.us> - bug 200762
 * Port to the D programming language:
 *     Frank Benoit <benoit@tionex.de>
 *******************************************************************************/
module org.eclipse.jface.fieldassist.SimpleContentProposalProvider;

import org.eclipse.jface.fieldassist.IContentProposalProvider;
import org.eclipse.jface.fieldassist.IContentProposal;


import java.lang.all;
import java.util.ArrayList;
import java.util.Set;

/**
 * SimpleContentProposalProvider is a class designed to map a static list of
 * Strings to content proposals.
 *
 * @see IContentProposalProvider
 * @since 3.2
 *
 */
public class SimpleContentProposalProvider : IContentProposalProvider {

    /*
     * The proposals provided.
     */
    private String[] proposals;

    /*
     * The proposals mapped to IContentProposal. Cached for speed in the case
     * where filtering is not used.
     */
    private IContentProposal[] contentProposals;

    /*
     * Boolean that tracks whether filtering is used.
     */
    private bool filterProposals = false;

    /**
     * Construct a SimpleContentProposalProvider whose content proposals are
     * always the specified array of Objects.
     *
     * @param proposals
     *            the array of Strings to be returned whenever proposals are
     *            requested.
     */
    public this(String[] proposals) {
        //super();
        this.proposals = proposals;
    }

    /**
     * Return an array of Objects representing the valid content proposals for a
     * field.
     *
     * @param contents
     *            the current contents of the field (only consulted if filtering
     *            is set to <code>true</code>)
     * @param position
     *            the current cursor position within the field (ignored)
     * @return the array of Objects that represent valid proposals for the field
     *         given its current content.
     */
    public IContentProposal[] getProposals(String contents, int position) {
        if (filterProposals) {
            ArrayList list = new ArrayList();
            for (int i = 0; i < proposals.length; i++) {
                if (proposals[i].length >= contents.length
                        && proposals[i].substring(0, contents.length)
                                .equalsIgnoreCase(contents)) {
                    list.add(cast(Object)makeContentProposal(proposals[i]));
                }
            }
            return arraycast!(IContentProposal)(list.toArray());
        }
        if (contentProposals is null) {
            contentProposals = new IContentProposal[proposals.length];
            for (int i = 0; i < proposals.length; i++) {
                contentProposals[i] = makeContentProposal(proposals[i]);
            }
        }
        return contentProposals;
    }

    /**
     * Set the Strings to be used as content proposals.
     *
     * @param items
     *            the array of Strings to be used as proposals.
     */
    public void setProposals(String[] items) {
        this.proposals = items;
        contentProposals = null;
    }

    /**
     * Set the bool that controls whether proposals are filtered according to
     * the current field content.
     *
     * @param filterProposals
     *            <code>true</code> if the proposals should be filtered to
     *            show only those that match the current contents of the field,
     *            and <code>false</code> if the proposals should remain the
     *            same, ignoring the field content.
     * @since 3.3
     */
    public void setFiltering(bool filterProposals) {
        this.filterProposals = filterProposals;
        // Clear any cached proposals.
        contentProposals = null;
    }

    /*
     * Make an IContentProposal for showing the specified String.
     */
    private IContentProposal makeContentProposal( String proposal) {
        return new class IContentProposal {
            String proposal_;
            this(){proposal_=proposal;}
            public String getContent() {
                return proposal_;
            }

            public String getDescription() {
                return null;
            }

            public String getLabel() {
                return null;
            }

            public int getCursorPosition() {
                return proposal_.length;
            }
        };
    }
}
