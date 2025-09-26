package org.xmljacquard.ajp;

import net.sf.saxon.s9api.*;
import org.nineml.coffeesacks.RegisterCoffeeSacks;

import javax.xml.transform.Source;
import javax.xml.transform.TransformerException;
import javax.xml.transform.stream.StreamSource;

import static net.sf.saxon.Configuration.XML11;

public class XsltXpathEnvironment {

    private final static Class<XsltXpathEnvironment> THIS = XsltXpathEnvironment.class;

    @SuppressWarnings("unused")
    public final static boolean TRACING_ON  = true;
    public final static boolean TRACING_OFF = false;

    public static Processor getProcessor() {
        return getProcessor(TRACING_OFF);
    }

    @SuppressWarnings("SameParameterValue")
    public static Processor getProcessor(final boolean isTracing) {
        final Processor processor = new Processor(true);

        // N.B. Allow import modules to be found on the classpath from relative URIs
        processor.getUnderlyingConfiguration().setResourceResolver(new ClasspathResourceResolver());

        // N.B. Allow some special chars to be encoded in XDM, such as backspace (U+0008)
        processor.getUnderlyingConfiguration().setXMLVersion(XML11);

        // Registration of extension functions implementing the ixml processor, nineml by ntw.
        try {
            new RegisterCoffeeSacks().initialize(processor.getUnderlyingConfiguration());
        } catch (final TransformerException e) {
            throw new RuntimeException(e);
        }

        // Can turn on tracing for individual queries if needed for debugging
        if (isTracing) {
            processor.getUnderlyingConfiguration().setCompileWithTracing(true);
            processor.getUnderlyingConfiguration().setTraceListener(new net.sf.saxon.trace.XSLTTraceListener());
        }

        return processor;
    }

    public static XsltCompiler getXsltCompiler(final Processor processor) throws SaxonApiException {
        final XsltCompiler compiler    = processor.newXsltCompiler();
        final XsltPackage  xsltPackage = compiler.compilePackage(getPackageSource());
        compiler.importPackage(xsltPackage);
        return compiler;
    }

    public static XsltExecutable getXsltExecutable(final XsltCompiler compiler,
                                                   final Source       source) throws SaxonApiException {
        return compiler.compile(source);
    }

    private static StreamSource getPackageSource() {
        //noinspection DataFlowIssue
        return new StreamSource(THIS.getResource("/xslt/ajp/ajp.xslt").toString());
    }
}
