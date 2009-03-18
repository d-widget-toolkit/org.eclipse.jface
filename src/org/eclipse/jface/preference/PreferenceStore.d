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
module org.eclipse.jface.preference.PreferenceStore;

import org.eclipse.jface.preference.IPersistentPreferenceStore;
import org.eclipse.jface.preference.IPreferenceStore;

// import java.io.FileInputStream;
// import java.io.FileOutputStream;
// import java.io.IOException;
// import java.io.InputStream;
// import java.io.OutputStream;
// import java.io.PrintStream;
// import java.io.PrintWriter;
// import java.util.ArrayList;
// import java.util.Enumeration;
// import java.util.Properties;

import org.eclipse.core.commands.common.EventManager;
import org.eclipse.core.runtime.Assert;
import org.eclipse.jface.resource.JFaceResources;
import org.eclipse.jface.util.IPropertyChangeListener;
import org.eclipse.jface.util.PropertyChangeEvent;
import org.eclipse.jface.util.SafeRunnable;

import java.lang.all;
import java.util.Enumeration;
import java.util.ArrayList;
import java.util.Set;
import tango.io.stream.Format;
import tango.io.device.File;

    import tango.io.model.IConduit;
    import tango.text.Util;
    public class Properties {

        protected Properties defaults;

        private String[ String ] map;

        public this (){
        }

        public this ( Properties defaults ){
            this.defaults = defaults;
        }

        public synchronized String setProperty( String key, String value ){
            String res;
            if( auto v = key in map ){
                res = *v;
            }
            map[ key ] = value;
            return res;
        }

        public synchronized void load( InputStream inStream ){
            char[] line;
            bool eof = false;
            void readLine(){
                line.length = 0;
                char[1] rdbuf;
                int i = inStream.read( rdbuf );
                while( i is 1 && rdbuf[0] != '\n' && rdbuf[0] != '\r' ){
                    line ~= rdbuf[0];
                    i = inStream.read( rdbuf );
                }
                eof = i !is 1;
            }

            bool linecontinue = false;
            bool iskeypart = true;
            char[] key;
            char[] value;
    nextline:
            while( !eof ){
                readLine();
                line = tango.text.Util.trim( line );
                if( line.length == 0 ){
                    continue;
                }
                if( line[0] == '#' ){
                    continue;
                }
                int pos = 0;
                bool esc = false;
                if( !linecontinue ){
                    iskeypart = true;
                    key = null;
                    value = null;
                }
                else{
                    linecontinue = false;
                }
                while( pos < line.length ){
                    char c = line[pos];
                    if( esc ){
                        esc = false;
                        switch( c ){
                        case 't': c = '\t'; break;
                        case 'r': c = '\r'; break;
                        case 'n': c = '\n'; break;
                        case '\\': c = '\\'; break;
                        default:  break;
                        }
                    }
                    else{
                        if( c == '\\' ){
                            if( pos == line.length -1 ){
                                linecontinue = true;
                                goto nextline;
                            }
                            esc = true;
                            pos++;
                            continue;
                        }
                        else if( iskeypart && c == '=' ){
                            pos++;
                            iskeypart = false;
                            continue;
                        }
                    }
                    pos++;
                    if( iskeypart ){
                        key ~= c;
                    }
                    else{
                        value ~= c;
                    }
                }
                if( iskeypart ){
                    getDwtLogger().error( __FILE__, __LINE__, "put cannot find '='." );
                    continue;
                }
                key = tango.text.Util.trim( key );
                value = tango.text.Util.trim(value);

                map[ key.dup ] = value.dup;
            }
        }

        public synchronized void store( OutputStream ostr, String comments ){
            void append(char[] s){
                foreach( c; s ){
                    switch( c ){
                    case '\t': ostr.write( "\\t"  ); break;
                    case '\n': ostr.write( "\\n"  ); break;
                    case '\r': ostr.write( "\\r"  ); break;
                    case '\\': ostr.write( "\\\\" ); break;
                    case ':' : ostr.write( "\\:"  ); break;
                    default: {
                            char[1] b;
                            b[0] = c;
                            ostr.write( b ); break;
                        }
                    }
                }
            }
            if( comments.length ){
                bool lineStart = true;
                for( int idx = 0; idx < comments.length; idx++ ){
                    char[1] b;
                    if( lineStart ){
                        b[0] = '#';
                        ostr.write(b);
                    }
                    append( comments[ idx .. idx+1 ] );
                    lineStart = false;
                    if( comments[idx] is '\n' ){
                        lineStart = true;
                    }
                }
                ostr.write( "\n" );
            }
            foreach( k, v; map ){
                append(k);
                append("=");
                append(v);
                ostr.write( "\n" );
            }
        }

//         public synchronized void save( dejavu.io.OutputStream.OutputStream out_KEYWORDESCAPE, dejavu.lang.String.String comments ){
//             implMissing( __FILE__, __LINE__ );
//         }
//
//         public synchronized void loadFromXML( dejavu.io.InputStream.InputStream in_KEYWORDESCAPE ){
//             implMissing( __FILE__, __LINE__ );
//         }
//
//         public synchronized void storeToXML( dejavu.io.OutputStream.OutputStream os, dejavu.lang.String.String comment ){
//             implMissing( __FILE__, __LINE__ );
//         }
//
//         public synchronized void storeToXML( dejavu.io.OutputStream.OutputStream os, dejavu.lang.String.String comment, dejavu.lang.String.String encoding ){
//             implMissing( __FILE__, __LINE__ );
//         }

        public String getProperty( String aKey ){
            if( auto res = aKey in map ){
                return *res;
            }
            if( defaults !is null ){
                return defaults.getProperty( aKey );
            }
            return null;
        }

        public String get( String aKey ){
            if( auto res = aKey in map ){
                return *res;
            }
            return null;
        }
        public String put( String aKey, String aValue ){
            if( auto pres = aKey in map ){
                String res = *pres;
                map[ aKey ] = aValue;
                return res;
            }
            map[ aKey ] = aValue;
            return null;
        }
        public String remove( String aKey ){
            if( auto res = aKey in map ){
                map.remove(aKey);
                return *res;
            }
            return null;
        }

        public String getProperty( String key, String defaultValue ){
            if( auto res = key in map ){
                return *res;
            }
            return defaultValue;
        }

        public void list(FormatOutput!(char) print){
            foreach( k, v; map ){
                print( k )( '=' )( v ).newline;
            }
        }
        public bool containsKey( String key ){
            return ( key in map ) !is null;
        }
        public String[] propertyNames(){
            String[] res = new String[ map.length ];
            int idx;
            foreach( key, val; map ){
                res[idx] = key;
                idx++;
            }
            return res;
        }

//         public dejavu.util.Enumeration.Enumeration propertyNames(){
//             implMissing( __FILE__, __LINE__ );
//             return null;
//         }
//
//         public void list( dejavu.io.PrintStream.PrintStream out_KEYWORDESCAPE ){
//             implMissing( __FILE__, __LINE__ );
//         }
//
//         public void list( dejavu.io.PrintWriter.PrintWriter out_KEYWORDESCAPE ){
//             implMissing( __FILE__, __LINE__ );
//         }
//
//         public override char[] toUtf8(){
//             return "";
//         }

    }



/**
 * A concrete preference store implementation based on an internal
 * <code>java.util.Properties</code> object, with support for persisting the
 * non-default preference values to files or streams.
 * <p>
 * This class was not designed to be subclassed.
 * </p>
 *
 * @see IPreferenceStore
 * @noextend This class is not intended to be subclassed by clients.
 */
public class PreferenceStore : EventManager,
        IPersistentPreferenceStore {

    /**
     * The mapping from preference name to preference value (represented as
     * strings).
     */
    private Properties properties;

    /**
     * The mapping from preference name to default preference value (represented
     * as strings); <code>null</code> if none.
     */
    private Properties defaultProperties;

    /**
     * Indicates whether a value as been changed by <code>setToDefault</code>
     * or <code>setValue</code>; initially <code>false</code>.
     */
    private bool dirty = false;

    /**
     * The file name used by the <code>load</code> method to load a property
     * file. This filename is used to save the properties file when
     * <code>save</code> is called.
     */
    private String filename;

    /**
     * Creates an empty preference store.
     * <p>
     * Use the methods <code>load(InputStream)</code> and
     * <code>save(InputStream)</code> to load and store this preference store.
     * </p>
     *
     * @see #load(InputStream)
     * @see #save(OutputStream, String)
     */
    public this() {
        defaultProperties = new Properties();
        properties = new Properties(defaultProperties);
    }

    /**
     * Creates an empty preference store that loads from and saves to the a
     * file.
     * <p>
     * Use the methods <code>load()</code> and <code>save()</code> to load
     * and store this preference store.
     * </p>
     *
     * @param filename
     *            the file name
     * @see #load()
     * @see #save()
     */
    public this(String filename) {
        this();
        Assert.isNotNull(filename);
        this.filename = filename;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void addPropertyChangeListener(IPropertyChangeListener listener) {
        addListenerObject(cast(Object)listener);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public bool contains(String name) {
        return (properties.containsKey(name) || defaultProperties
                .containsKey(name));
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void firePropertyChangeEvent(String name, Object oldValue,
            Object newValue) {
        final Object[] finalListeners = getListeners();
        // Do we need to fire an event.
        if (finalListeners.length > 0
                && (oldValue is null || !oldValue.opEquals(newValue))) {
            final PropertyChangeEvent pe = new PropertyChangeEvent(this, name,
                    oldValue, newValue);
            for (int i = 0; i < finalListeners.length; ++i) {
                SafeRunnable.run(new class(JFaceResources.getString("PreferenceStore.changeError"),cast(IPropertyChangeListener) finalListeners[i]) SafeRunnable { //$NON-NLS-1$
                    IPropertyChangeListener l;
                    this(char[] s,IPropertyChangeListener b){
                        super(s);
                        l = b;
                    }
                    public void run() {
                        l.propertyChange(pe);
                    }
                });
            }
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public bool getBoolean(String name) {
        return getBoolean(properties, name);
    }

    /**
     * Helper function: gets bool for a given name.
     *
     * @param p
     * @param name
     * @return bool
     */
    private bool getBoolean(Properties p, String name) {
        String value = p !is null ? p.getProperty(name) : null;
        if (value is null) {
            return BOOLEAN_DEFAULT_DEFAULT;
        }
        if (value.equals(IPreferenceStore.TRUE)) {
            return true;
        }
        return false;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public bool getDefaultBoolean(String name) {
        return getBoolean(defaultProperties, name);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public double getDefaultDouble(String name) {
        return getDouble(defaultProperties, name);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public float getDefaultFloat(String name) {
        return getFloat(defaultProperties, name);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public int getDefaultInt(String name) {
        return getInt(defaultProperties, name);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public long getDefaultLong(String name) {
        return getLong(defaultProperties, name);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public String getDefaultString(String name) {
        return getString(defaultProperties, name);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public double getDouble(String name) {
        return getDouble(properties, name);
    }

    /**
     * Helper function: gets double for a given name.
     *
     * @param p
     * @param name
     * @return double
     */
    private double getDouble(Properties p, String name) {
        String value = p !is null ? p.getProperty(name) : null;
        if (value is null) {
            return DOUBLE_DEFAULT_DEFAULT;
        }
        double ival = DOUBLE_DEFAULT_DEFAULT;
        try {
            ival = (new Double(value)).doubleValue();
        } catch (NumberFormatException e) {
        }
        return ival;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public float getFloat(String name) {
        return getFloat(properties, name);
    }

    /**
     * Helper function: gets float for a given name.
     *
     * @param p
     * @param name
     * @return float
     */
    private float getFloat(Properties p, String name) {
        String value = p !is null ? p.getProperty(name) : null;
        if (value is null) {
            return FLOAT_DEFAULT_DEFAULT;
        }
        float ival = FLOAT_DEFAULT_DEFAULT;
        try {
            ival = (new Float(value)).floatValue();
        } catch (NumberFormatException e) {
        }
        return ival;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public int getInt(String name) {
        return getInt(properties, name);
    }

    /**
     * Helper function: gets int for a given name.
     *
     * @param p
     * @param name
     * @return int
     */
    private int getInt(Properties p, String name) {
        String value = p !is null ? p.getProperty(name) : null;
        if (value is null) {
            return INT_DEFAULT_DEFAULT;
        }
        int ival = 0;
        try {
            ival = Integer.parseInt(value);
        } catch (NumberFormatException e) {
        }
        return ival;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public long getLong(String name) {
        return getLong(properties, name);
    }

    /**
     * Helper function: gets long for a given name.
     *
     * @param p
     *            the properties storage (may be <code>null</code>)
     * @param name
     *            the name of the property
     * @return the long or a default value of if:
     *         <ul>
     *         <li>properties storage is <code>null</code></li>
     *         <li>property is not found</li>
     *         <li>property value is not a number</li>
     *         </ul>
     * @see IPreferenceStore#LONG_DEFAULT_DEFAULT
     */
    private long getLong(Properties p, String name) {
        String value = p !is null ? p.getProperty(name) : null;
        if (value is null) {
            return LONG_DEFAULT_DEFAULT;
        }
        long ival = LONG_DEFAULT_DEFAULT;
        try {
            ival = Long.parseLong(value);
        } catch (NumberFormatException e) {
        }
        return ival;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public String getString(String name) {
        return getString(properties, name);
    }

    /**
     * Helper function: gets string for a given name.
     *
     * @param p
     *            the properties storage (may be <code>null</code>)
     * @param name
     *            the name of the property
     * @return the value or a default value of if:
     *         <ul>
     *         <li>properties storage is <code>null</code></li>
     *         <li>property is not found</li>
     *         <li>property value is not a number</li>
     *         </ul>
     * @see IPreferenceStore#STRING_DEFAULT_DEFAULT
     */
    private String getString(Properties p, String name) {
        String value = p !is null ? p.getProperty(name) : null;
        if (value is null) {
            return STRING_DEFAULT_DEFAULT;
        }
        return value;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public bool isDefault(String name) {
        return (!properties.containsKey(name) && defaultProperties
                .containsKey(name));
    }

    /**
     * Prints the contents of this preference store to the given print stream.
     *
     * @param out
     *            the print stream
     */
    public void list(FormatOutput!(char) out_) {
        properties.list(out_);
    }

//     /**
//      * Prints the contents of this preference store to the given print writer.
//      *
//      * @param out
//      *            the print writer
//      */
//     public void list(PrintWriter out_) {
//         properties.list(out_);
//     }

    /**
     * Loads this preference store from the file established in the constructor
     * <code>PreferenceStore(java.lang.String)</code> (or by
     * <code>setFileName</code>). Default preference values are not affected.
     *
     * @exception java.io.IOException
     *                if there is a problem loading this store
     */
    public void load() {
        if (filename is null) {
            throw new IOException("File name not specified");//$NON-NLS-1$
        }
        File in_ = new File(filename, File.ReadExisting);
        load(in_.input);
        in_.close();
    }

    /**
     * Loads this preference store from the given input stream. Default
     * preference values are not affected.
     *
     * @param in
     *            the input stream
     * @exception java.io.IOException
     *                if there is a problem loading this store
     */
    public void load(InputStream in_)  {
        properties.load(in_);
        dirty = false;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public bool needsSaving() {
        return dirty;
    }

    /**
     * Returns an enumeration of all preferences known to this store which have
     * current values other than their default value.
     *
     * @return an array of preference names
     */
    public String[] preferenceNames() {
        String[] list;
        foreach( prop; properties.propertyNames() ){
            list ~= prop;
        }
        return list;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void putValue(String name, String value) {
        String oldValue = getString(name);
        if (oldValue is null || !oldValue.equals(value)) {
            setValue(properties, name, value);
            dirty = true;
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void removePropertyChangeListener(IPropertyChangeListener listener) {
        removeListenerObject(cast(Object)listener);
    }

    /**
     * Saves the non-default-valued preferences known to this preference store
     * to the file from which they were originally loaded.
     *
     * @exception java.io.IOException
     *                if there is a problem saving this store
     */
    public void save() {
        if (filename is null) {
            throw new IOException("File name not specified");//$NON-NLS-1$
        }
        File out_ = null;
        try {
            out_ = new File(filename,File.WriteCreate);
            save(out_, null);
        } finally {
            if (out_ !is null) {
                out_.close();
            }
        }
    }

    /**
     * Saves this preference store to the given output stream. The given string
     * is inserted as header information.
     *
     * @param out
     *            the output stream
     * @param header
     *            the header
     * @exception java.io.IOException
     *                if there is a problem saving this store
     */
    public void save(OutputStream out_, String header) {
        properties.store(out_, header);
        dirty = false;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setDefault(String name, double value) {
        setValue(defaultProperties, name, value);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setDefault(String name, float value) {
        setValue(defaultProperties, name, value);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setDefault(String name, int value) {
        setValue(defaultProperties, name, value);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setDefault(String name, long value) {
        setValue(defaultProperties, name, value);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setDefault(String name, String value) {
        setValue(defaultProperties, name, value);
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setDefault(String name, bool value) {
        setValue(defaultProperties, name, value);
    }

    /**
     * Sets the name of the file used when loading and storing this preference
     * store.
     * <p>
     * Afterward, the methods <code>load()</code> and <code>save()</code>
     * can be used to load and store this preference store.
     * </p>
     *
     * @param name
     *            the file name
     * @see #load()
     * @see #save()
     */
    public void setFilename(String name) {
        filename = name;
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setToDefault(String name) {
        String oldValue = properties.get(name);
        properties.remove(name);
        dirty = true;
        String newValue;
        if (defaultProperties !is null) {
            newValue = defaultProperties.get(name);
        }
        firePropertyChangeEvent(name, stringcast(oldValue), stringcast(newValue));
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setValue(String name, double value) {
        double oldValue = getDouble(name);
        if (oldValue !is value) {
            setValue(properties, name, value);
            dirty = true;
            firePropertyChangeEvent(name, new Double(oldValue), new Double(
                    value));
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setValue(String name, float value) {
        float oldValue = getFloat(name);
        if (oldValue !is value) {
            setValue(properties, name, value);
            dirty = true;
            firePropertyChangeEvent(name, new Float(oldValue), new Float(value));
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setValue(String name, int value) {
        int oldValue = getInt(name);
        if (oldValue !is value) {
            setValue(properties, name, value);
            dirty = true;
            firePropertyChangeEvent(name, new Integer(oldValue), new Integer(
                    value));
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setValue(String name, long value) {
        long oldValue = getLong(name);
        if (oldValue !is value) {
            setValue(properties, name, value);
            dirty = true;
            firePropertyChangeEvent(name, new Long(oldValue), new Long(value));
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setValue(String name, String value) {
        String oldValue = getString(name);
        if (oldValue is null || !oldValue.equals(value)) {
            setValue(properties, name, value);
            dirty = true;
            firePropertyChangeEvent(name, stringcast(oldValue), stringcast(value));
        }
    }

    /*
     * (non-Javadoc) Method declared on IPreferenceStore.
     */
    public void setValue(String name, bool value) {
        bool oldValue = getBoolean(name);
        if (oldValue !is value) {
            setValue(properties, name, value);
            dirty = true;
            firePropertyChangeEvent(name, oldValue ? Boolean.TRUE
                    : Boolean.FALSE, value ? Boolean.TRUE : Boolean.FALSE);
        }
    }

    /**
     * Helper method: sets value for a given name.
     *
     * @param p
     * @param name
     * @param value
     */
    private void setValue(Properties p, String name, double value) {
        Assert.isTrue(p !is null);
        p.put(name, Double.toString(value));
    }

    /**
     * Helper method: sets value for a given name.
     *
     * @param p
     * @param name
     * @param value
     */
    private void setValue(Properties p, String name, float value) {
        Assert.isTrue(p !is null);
        p.put(name, Float.toString(value));
    }

    /**
     * Helper method: sets value for a given name.
     *
     * @param p
     * @param name
     * @param value
     */
    private void setValue(Properties p, String name, int value) {
        Assert.isTrue(p !is null);
        p.put(name, Integer.toString(value));
    }

    /**
     * Helper method: sets the value for a given name.
     *
     * @param p
     * @param name
     * @param value
     */
    private void setValue(Properties p, String name, long value) {
        Assert.isTrue(p !is null);
        p.put(name, Long.toString(value));
    }

    /**
     * Helper method: sets the value for a given name.
     *
     * @param p
     * @param name
     * @param value
     */
    private void setValue(Properties p, String name, String value) {
        // SWT: allow null value
        Assert.isTrue(p !is null /+&& value !is null+/);
        p.put(name, value);
    }

    /**
     * Helper method: sets the value for a given name.
     *
     * @param p
     * @param name
     * @param value
     */
    private void setValue(Properties p, String name, bool value) {
        Assert.isTrue(p !is null);
        p.put(name, value is true ? IPreferenceStore.TRUE
                : IPreferenceStore.FALSE);
    }
}
