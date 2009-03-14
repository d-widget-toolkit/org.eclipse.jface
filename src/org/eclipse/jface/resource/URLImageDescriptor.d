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
module org.eclipse.jface.resource.URLImageDescriptor;

import org.eclipse.jface.resource.ImageDescriptor;

// import java.io.BufferedInputStream;
// import java.io.IOException;
// import java.io.InputStream;
import tango.net.Uri;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
import org.eclipse.core.runtime.IStatus;
import org.eclipse.core.runtime.Status;
import org.eclipse.jface.util.Policy;

import java.lang.all;
import java.io.BufferedInputStream;
import java.io.InputStream;

/**
 * An ImageDescriptor that gets its information from a URL. This class is not
 * public API. Use ImageDescriptor#createFromURL to create a descriptor that
 * uses a URL.
 */
class URLImageDescriptor : ImageDescriptor {
    /**
     * Constant for the file protocol for optimized loading
     */
    private static final String FILE_PROTOCOL = "file";  //$NON-NLS-1$
    private Uri url;

    /**
     * Creates a new URLImageDescriptor.
     *
     * @param url
     *            The URL to load the image from. Must be non-null.
     */
    this(Uri url) {
        this.url = url;
    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    public override int opEquals(Object o) {
        if (!(cast(URLImageDescriptor)o )) {
            return false;
        }
        return (cast(URLImageDescriptor) o).url.opEquals(this.url) !is 0;
    }

    /*
     * (non-Javadoc) Method declared on ImageDesciptor. Returns null if the
     * image data cannot be read.
     */
    public override ImageData getImageData() {
        ImageData result = null;
        InputStream in_ = getStream();
        if (in_ !is null) {
            scope(exit)
                in_.close();
            try {
                result = new ImageData(in_);
            } catch (SWTException e) {
                if (e.code !is SWT.ERROR_INVALID_IMAGE) {
                    throw e;
                    // fall through otherwise
                }
            }
        }
        return result;
    }

    /**
     * Returns a stream on the image contents. Returns null if a stream could
     * not be opened.
     *
     * @return the stream for loading the data
     */
    protected InputStream getStream() {
        implMissing( __FILE__, __LINE__ );
        return null;
        //FIXME
        /+
        try {
            return new BufferedInputStream(url.openStream());
        } catch (IOException e) {
            return null;
        }
        +/
    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    public override hash_t toHash() {
        return url.toHash();
    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    /**
     * The <code>URLImageDescriptor</code> implementation of this
     * <code>Object</code> method returns a string representation of this
     * object which is suitable only for debugging.
     */
    public override String toString() {
        return "URLImageDescriptor(" ~ url.toString ~ ")"; //$NON-NLS-1$ //$NON-NLS-2$
    }

    /**
     * Returns the filename for the ImageData.
     *
     * @return {@link String} or <code>null</code> if the file cannot be found
     */
    private String getFilePath() {
//         try {
//             if (JFaceActivator.getBundleContext() is null) {
//                 if (FILE_PROTOCOL.equalsIgnoreCase(url.getProtocol()))
//                     return new Path(url.getFile()).toOSString();
//                 return null;
//             }
//
//             URL locatedURL = FileLocator.toFileURL(url);
//             if (FILE_PROTOCOL.equalsIgnoreCase(locatedURL.getProtocol()))
//                 return new Path(locatedURL.getPath()).toOSString();
//             return null;
//
//         } catch (IOException e) {
//             Policy.logException(e);
//             return null;
//         }
        return null;
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.resource.ImageDescriptor#createImage(bool,
     *      org.eclipse.swt.graphics.Device)
     */
    public override Image createImage(bool returnMissingImageOnError, Device device) {

        // Try to see if we can optimize using SWTs file based image support.
        String path = getFilePath();
        if (path is null)
            return super.createImage(returnMissingImageOnError, device);

        try {
            return new Image(device, path);
        } catch (SWTException exception) {
            // If we fail fall back to the slower input stream method.
        }
        return super.createImage(returnMissingImageOnError, device);
    }

}
