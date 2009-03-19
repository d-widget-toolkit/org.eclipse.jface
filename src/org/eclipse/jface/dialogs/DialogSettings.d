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
module org.eclipse.jface.dialogs.DialogSettings;

import org.eclipse.jface.dialogs.IDialogSettings;


static import tango.text.xml.Document;
static import tango.text.xml.SaxParser;
static import tango.text.xml.PullParser;
import tango.core.Exception;

import java.lang.all;
import java.util.Enumeration;
import java.util.Collections;
import java.util.Collection;
import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
static import java.io.OutputStream;
static import tango.text.convert.Integer;
static import tango.text.convert.Float;
static import tango.text.Text;
static import tango.io.stream.Format;
static import tango.io.model.IConduit;
import tango.io.device.File;
import java.nonstandard.XmlTranscode;

/**
 * Concrete implementation of a dialog settings (<code>IDialogSettings</code>)
 * using a hash table and XML. The dialog store can be read
 * from and saved to a stream. All keys and values must be strings or array of
 * strings. Primitive types are converted to strings.
 * <p>
 * This class was not designed to be subclassed.
 *
 * Here is an example of using a DialogSettings:
 * </p>
 * <pre>
 * <code>
 * DialogSettings settings = new DialogSettings("root");
 * settings.put("Boolean1",true);
 * settings.put("Long1",100);
 * settings.put("Array1",new String[]{"aaaa1","bbbb1","cccc1"});
 * DialogSettings section = new DialogSettings("sectionName");
 * settings.addSection(section);
 * section.put("Int2",200);
 * section.put("Float2",1.1);
 * section.put("Array2",new String[]{"aaaa2","bbbb2","cccc2"});
 * settings.save("c:\\temp\\test\\dialog.xml");
 * </code>
 * </pre>
 * @noextend This class is not intended to be subclassed by clients.
 */

public class DialogSettings : IDialogSettings {
    alias tango.text.xml.Document.Document!(char) Document;
    alias tango.text.xml.Document.Document!(char).Node Element;
    // The name of the DialogSettings.
    private String name;

    /* A Map of DialogSettings representing each sections in a DialogSettings.
     It maps the DialogSettings' name to the DialogSettings */
    private Map sections;

    /* A Map with all the keys and values of this sections.
     Either the keys an values are restricted to strings. */
    private Map items;

    // A Map with all the keys mapped to array of strings.
    private Map arrayItems;

    private static const String TAG_SECTION = "section";//$NON-NLS-1$

    private static const String TAG_NAME = "name";//$NON-NLS-1$

    private static const String TAG_KEY = "key";//$NON-NLS-1$

    private static const String TAG_VALUE = "value";//$NON-NLS-1$

    private static const String TAG_LIST = "list";//$NON-NLS-1$

    private static const String TAG_ITEM = "item";//$NON-NLS-1$

    /**
     * Create an empty dialog settings which loads and saves its
     * content to a file.
     * Use the methods <code>load(String)</code> and <code>store(String)</code>
     * to load and store this dialog settings.
     *
     * @param sectionName the name of the section in the settings.
     */
    public this(String sectionName) {
        name = sectionName;
        items = new HashMap();
        arrayItems = new HashMap();
        sections = new HashMap();
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public IDialogSettings addNewSection(String sectionName) {
        DialogSettings section = new DialogSettings(sectionName);
        addSection(section);
        return section;
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void addSection(IDialogSettings section) {
        sections.put(stringcast(section.getName()), cast(Object)section);
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public String get(String key) {
        return stringcast(items.get(stringcast(key)));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public String[] getArray(String key) {
        return stringArrayFromObject(arrayItems.get(stringcast(key)));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public bool getBoolean(String key) {
        return stringcast(items.get(stringcast(key))) == "true";
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public double getDouble(String key) {
        String setting = stringcast(items.get(stringcast(key)));
        if (setting is null) {
            throw new NumberFormatException(
                    "There is no setting associated with the key \"" ~ key ~ "\"");//$NON-NLS-1$ //$NON-NLS-2$
        }

        return tango.text.convert.Float.toFloat(setting);
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public float getFloat(String key) {
        String setting = stringcast(items.get(stringcast(key)));
        if (setting is null) {
            throw new NumberFormatException(
                    "There is no setting associated with the key \"" ~ key ~ "\"");//$NON-NLS-1$ //$NON-NLS-2$
        }

        return tango.text.convert.Float.toFloat(setting);
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public int getInt(String key) {
        String setting = stringcast(items.get(stringcast(key)));
        if (setting is null) {
            //new Integer(null) will throw a NumberFormatException and meet our spec, but this message
            //is clearer.
            throw new NumberFormatException(
                    "There is no setting associated with the key \"" ~ key ~ "\"");//$NON-NLS-1$ //$NON-NLS-2$
        }

        return tango.text.convert.Integer.toInt(setting);
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public long getLong(String key) {
        String setting = stringcast(items.get(stringcast(key)));
        if (setting is null) {
            //new Long(null) will throw a NumberFormatException and meet our spec, but this message
            //is clearer.
            throw new NumberFormatException(
                    "There is no setting associated with the key \"" ~ key ~ "\"");//$NON-NLS-1$ //$NON-NLS-2$
        }

        return tango.text.convert.Integer.toLong(setting);
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public String getName() {
        return name;
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public IDialogSettings getSection(String sectionName) {
        return cast(IDialogSettings) sections.get(stringcast(sectionName));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public IDialogSettings[] getSections() {
        Collection values = sections.values();
        IDialogSettings[] result = arraycast!(IDialogSettings)( values.toArray() );
        return result;
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void load( tango.io.model.IConduit.InputStream input) {
        Document document = new Document();
        try {
            char[] content;
            char[1024] readbuf;
            int chunksize = 0;
            while( (chunksize=input.read(readbuf)) !is tango.io.model.IConduit.InputStream.Eof ){
                content ~=  readbuf[ 0 .. chunksize ];
            }
            document.parse( content );

            //Strip out any comments first
            foreach( n; document.query[].filter( delegate bool(Element n) {
                    return n.type is tango.text.xml.PullParser.XmlNodeType.Comment ;
                })){
                //TODO: remove() was added after tango 0.99.5
                //n.remove();
            }
            load(document, document.tree.child );
        } catch (IOException e) {
            // ignore
        } catch (TextException e) {
            // ignore
        }
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    //TODO: solve overload load(char[])
    public void load(String fileName) {
        scope file = new File( fileName );
        load( file.input );
        file.close;
    }

    /* (non-Javadoc)
     * Load the setting from the <code>document</code>
     */
    private void load(Document document, Element root) {

        name = root.attributes.name(null,TAG_NAME).value();

        foreach( n; root.query[TAG_ITEM] ){
            if( root is n.parent() ){
                String key = n.attributes.name(null,TAG_KEY).value().dup;
                String value = n.attributes.name(null,TAG_VALUE).value().dup;
                items.put(stringcast(key), stringcast(value));
            }
        }
        foreach( n; root.query[TAG_LIST].dup ){
            if( root is n.parent() ){
                auto child = n;
                String key = child.attributes.name(null,TAG_KEY).value().dup;
                char[][] valueList;
                foreach( node; root.query[TAG_ITEM].dup ){
                    if (child is node.parent()) {
                        valueList ~= node.attributes.name(null,TAG_VALUE).value().dup;
                    }
                }
                arrayItems.put(stringcast(key), new ArrayWrapperString2(valueList) );
            }
        }
        foreach( n; root.query[TAG_SECTION].dup ){
            if( root is n.parent() ){
                DialogSettings s = new DialogSettings("NoName");//$NON-NLS-1$
                s.load(document, n);
                addSection(s);
            }
        }
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, String[] value) {
        arrayItems.put(stringcast(key), new ArrayWrapperString2(value));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, double value) {
        put(key, tango.text.convert.Float.toString(value));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, float value) {
        put(key, tango.text.convert.Float.toString(value));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, int value) {
        put(key, tango.text.convert.Integer.toString(value));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, long value) {
        put(key, tango.text.convert.Integer.toString(value));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, String value) {
        items.put(stringcast(key), stringcast(value));
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void put(String key, bool value) {
        put(key, value ? "true" : "false" );
    }

    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void save(tango.io.model.IConduit.OutputStream writer) {
        save(new XMLWriter(writer));
    }


    /* (non-Javadoc)
     * Method declared on IDialogSettings.
     */
    public void save(String fileName) {
        auto stream = new tango.io.device.File.File(
                fileName,
                tango.io.device.File.File.WriteCreate);
        XMLWriter writer = new XMLWriter(stream.output);
        save(writer);
        writer.close();
    }

    /* (non-Javadoc)
     * Save the settings in the <code>document</code>.
     */
    private void save(XMLWriter out_) {
        HashMap attributes = new HashMap(2);
        attributes.put(stringcast(TAG_NAME), stringcast(name is null ? "" : name)); //$NON-NLS-1$
        out_.startTag(TAG_SECTION, attributes);
        attributes.clear();

        Object EMPTY_STR = new ArrayWrapperString("");
        foreach( key,value; items ){
            attributes.put(stringcast(TAG_KEY), key is null ? EMPTY_STR : key); //$NON-NLS-1$
            String string = stringcast(value);//cast(String) items.get(stringcast(key));
            attributes.put(stringcast(TAG_VALUE), stringcast(string is null ? "" : string)); //$NON-NLS-1$
            out_.printTag(TAG_ITEM, attributes, true);
        }

        attributes.clear();
        foreach( key,value; arrayItems ){
            attributes.put(stringcast(TAG_KEY), key is null ? EMPTY_STR : key); //$NON-NLS-1$
            out_.startTag(TAG_LIST, attributes);
            attributes.clear();
            String[] strValues = stringArrayFromObject(value);
            if (value !is null) {
                for (int index = 0; index < strValues.length; index++) {
                    String string = strValues[index];
                    attributes.put(stringcast(TAG_VALUE), stringcast(string is null ? "" : string)); //$NON-NLS-1$
                    out_.printTag(TAG_ITEM, attributes, true);
                }
            }
            out_.endTag(TAG_LIST);
            attributes.clear();
        }
        for (Iterator i = sections.values().iterator(); i.hasNext();) {
            (cast(DialogSettings) i.next()).save(out_);
        }
        out_.endTag(TAG_SECTION);
    }


    /**
     * A simple XML writer.  Using this instead of the javax.xml.transform classes allows
     * compilation against JCL Foundation (bug 80059).
     */
    private static class XMLWriter : tango.io.stream.Format.FormatOutput!(char) {
        /** current number of tabs to use for ident */
        protected int tab;

        /** the xml header */
        protected static const String XML_VERSION = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"; //$NON-NLS-1$

        /**
         * Create a new XMLWriter
         * @param output the write to used when writing to
         */
        public this(tango.io.model.IConduit.OutputStream output) {
            super( tango.text.convert.Format.Format, output);
            tab = 0;
            print(XML_VERSION);
            newline;
        }

        /**
         * write the intended end tag
         * @param name the name of the tag to end
         */
        public void endTag(String name) {
            tab--;
            printTag("/" ~ name, null, false); //$NON-NLS-1$
        }

        private void printTabulation() {
            for (int i = 0; i < tab; i++) {
                super.print('\t');
            }
        }

        /**
         * write the tag to the stream and format it by itending it and add new line after the tag
         * @param name the name of the tag
         * @param parameters map of parameters
         * @param close should the tag be ended automatically (=> empty tag)
         */
        public void printTag(String name, HashMap parameters, bool close) {
            printTag(name, parameters, true, true, close);
        }

        private void printTag(String name, HashMap parameters, bool shouldTab, bool newLine, bool close) {
            StringBuffer sb = new StringBuffer();
            sb.append('<');
            sb.append(name);
            if (parameters !is null) {
                for (Enumeration e = Collections.enumeration(parameters.keySet()); e.hasMoreElements();) {
                    sb.append(" "); //$NON-NLS-1$
                    String key = stringcast( e.nextElement());
                    sb.append(key);
                    sb.append("=\""); //$NON-NLS-1$
                    //sb.append(getEscaped(String.valueOf(parameters.get(key))));
                    sb.append(xmlEscape(stringcast(parameters.get(stringcast(key)))));
                    sb.append("\""); //$NON-NLS-1$
                }
            }
            if (close) {
                sb.append('/');
            }
            sb.append('>');
            if (shouldTab) {
                printTabulation();
            }
            if (newLine) {
                print(sb.toString());
                newline;
            } else {
                print(sb.toString());
            }
        }

        /**
         * start the tag
         * @param name the name of the tag
         * @param parameters map of parameters
         */
        public void startTag(String name, HashMap parameters) {
            startTag(name, parameters, true);
            tab++;
        }

        private void startTag(String name, HashMap parameters, bool newLine) {
            printTag(name, parameters, true, newLine, false);
        }
    }

}
