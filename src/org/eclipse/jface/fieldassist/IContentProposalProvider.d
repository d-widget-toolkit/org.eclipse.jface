/*******************************************************************************
 * Copyright (c) 2005, 2006 IBM Corporation and others.
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
module org.eclipse.jface.fieldassist.IContentProposalProvider;

import org.eclipse.jface.fieldassist.IContentProposal;

import java.lang.all;

/**
 * IContentProposalProvider provides an array of IContentProposals that are
 * appropriate for a textual dialog field, given the field's current content and
 * the current cursor position.
 *
 * @since 3.2
 */
public interface IContentProposalProvider {

    /**
     * Return an array of Objects representing the valid content proposals for a
     * field.
     *
     * @param contents
     *            the current contents of the text field
     * @param position
     *            the current position of the cursor in the contents
     *
     * @return the array of {@link IContentProposal} that represent valid
     *         proposals for the field.
     */
    IContentProposal[] getProposals(String contents, int position);
}
