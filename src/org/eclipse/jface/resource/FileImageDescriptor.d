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
module org.eclipse.jface.resource.FileImageDescriptor;

import org.eclipse.jface.resource.ImageDescriptor;

// import java.io.BufferedInputStream;
// import java.io.FileInputStream;
// import java.io.FileNotFoundException;
// import java.io.IOException;
// import java.io.InputStream;

import org.eclipse.swt.SWT;
import org.eclipse.swt.SWTException;
import org.eclipse.swt.graphics.Device;
import org.eclipse.swt.graphics.Image;
import org.eclipse.swt.graphics.ImageData;
// import org.eclipse.core.runtime.FileLocator;
// import org.eclipse.core.runtime.Path;

import java.lang.all;
import java.io.InputStream;
import java.io.FileInputStream;
import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;

/**
 * An image descriptor that loads its image information from a file.
 */
class FileImageDescriptor : ImageDescriptor {

    /**
     * The class whose resource directory contain the file, or <code>null</code>
     * if none.
     */
//     private ClassInfo location;

    /**
     * The name of the file.
     */
    private String name;
    private void[] importdata;

    /**
     * Creates a new file image descriptor. The file has the given file name and
     * is located in the given class's resource directory. If the given class is
     * <code>null</code>, the file name must be absolute.
     * <p>
     * Note that the file is not accessed until its <code>getImageDate</code>
     * method is called.
     * </p>
     *
     * @param clazz
     *            class for resource directory, or <code>null</code>
     * @param filename
     *            the name of the file
     */
    this(ImportData importdata) {
//         this.location = clazz;
        this.name = importdata.name;
        this.importdata = importdata.data;
    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    public override int opEquals(Object o) {
        if (!( cast(FileImageDescriptor)o )) {
            return false;
        }
        FileImageDescriptor other = cast(FileImageDescriptor) o;
//         if (location !is null) {
//             if ( location.name != other.location.name ) {
//                 return false;
//             }
//         } else {
//             if (other.location !is null) {
//                 return false;
//             }
//         }
        return importdata == other.importdata;
    }

    /**
     * @see org.eclipse.jface.resource.ImageDescriptor#getImageData() The
     *      FileImageDescriptor implementation of this method is not used by
     *      {@link ImageDescriptor#createImage(bool, Device)} as of version
     *      3.4 so that the SWT OS optimised loading can be used.
     */
    public override ImageData getImageData() {
        InputStream in_ = getStream();
        ImageData result = null;
        if (in_ !is null) {
            try {
                result = new ImageData(in_);
            } catch (SWTException e) {
                if (e.code !is SWT.ERROR_INVALID_IMAGE /+&& e.code !is SWT.ERROR_UNSUPPORTED_FORMAT+/) {
                    getDwtLogger().trace( __FILE__, __LINE__, "FileImageDescriptor getImageData SWTException for name={}", name );
                    throw e;
                    // fall through otherwise
                }
            } finally {
                in_.close();
            }
        }
        return result;
    }

    /**
     * Returns a stream on the image contents. Returns null if a stream could
     * not be opened.
     *
     * @return the buffered stream on the file or <code>null</code> if the
     *         file cannot be found
     */
    private InputStream getStream() {
        InputStream is_ = null;

//         if (location !is null) {
            is_ = new ByteArrayInputStream(cast(byte[]) importdata);
//             is_ = ClassInfoGetResourceAsStream( location, name);

//         } else {
//             try {
//                 is_ = new FileInputStream(name);
//             } catch (/+FileNotFoundException+/ IOException e) {
//                 return null;
//             }
//         }
        if (is_ is null) {
            return null;
        }
        return new BufferedInputStream(is_);

    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    public override hash_t toHash() {
        int code = java.lang.all.toHash(cast(char[])importdata/+name+/);
//         if (location !is null) {
//             code += location.toHash();
//         }
        return code;
    }

    /*
     * (non-Javadoc) Method declared on Object.
     */
    /**
     * The <code>FileImageDescriptor</code> implementation of this
     * <code>Object</code> method returns a string representation of this
     * object which is suitable only for debugging.
     */
    public override String toString() {
        return Format("FileImageDescriptor(name={})", name );//$NON-NLS-3$//$NON-NLS-2$//$NON-NLS-1$
    }

    /*
     * (non-Javadoc)
     *
     * @see org.eclipse.jface.resource.ImageDescriptor#createImage(bool,
     *      org.eclipse.swt.graphics.Device)
     */
    public override Image createImage(bool returnMissingImageOnError, Device device) {
        if( importdata.length is 0 ){
            String path = getFilePath();
            if (path is null )
                return createDefaultImage(returnMissingImageOnError, device);
            try {
                return new Image(device, path);
            } catch (SWTException exception) {
                //if we fail try the default way using a stream
            }
        }
        return super.createImage(returnMissingImageOnError, device);
    }

    /**
     * Return default image if returnMissingImageOnError is true.
     *
     * @param device
     * @return Image or <code>null</code>
     */
    private Image createDefaultImage(bool returnMissingImageOnError,
            Device device) {
        try {
            if (returnMissingImageOnError)
                return new Image(device, DEFAULT_IMAGE_DATA);
        } catch (SWTException nextException) {
            return null;
        }
        return null;
    }

    /**
     * Returns the filename for the ImageData.
     *
     * @return {@link String} or <code>null</code> if the file cannot be found
     */
    private String getFilePath() {

//         if (location is null)
//             return (new Path(name)).toOSString();
//
//         URL resource = location.getResource(name);
//
//         if (resource is null)
//             return null;
//         try {
//             if (JFaceActivator.getBundleContext() is null) {// Stand-alone case
//
//                 return new Path(resource.getFile()).toOSString();
//             }
//             return new Path(FileLocator.toFileURL(resource).getPath()).toOSString();
//         } catch (IOException e) {
//             Policy.logException(e);
            return null;
//         }
    }
}
