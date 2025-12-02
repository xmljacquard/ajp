package org.xmljacquard.ajp;

import net.sf.saxon.s9api.*;

import javax.xml.transform.stream.StreamSource;
import java.net.URISyntaxException;

import static net.sf.saxon.s9api.XdmAtomicValue.makeAtomicValue;
import static net.sf.saxon.s9api.XdmFunctionItem.getSystemFunction;
import static net.sf.saxon.s9api.XdmValue.makeValue;
import static org.xmljacquard.ajp.XsltXpathEnvironment.*;

// Compiles a jsonpath query and allows it to be run against multiple json query arguments (i.e. json documents)
public class AjpRunner {

    private static final Class<AjpRunner> THIS = AjpRunner.class;

    public static final String AJPR_NAMESPACE   = "http://xmljacquard.org/ajp/runner";

    public static final QName  GET_PROCESSOR    = new QName(AJPR_NAMESPACE, "getProcessor" );
    public static final QName  RUN_PROCESSOR    = new QName(AJPR_NAMESPACE, "runProcessor" );
    public static final QName  ERROR_SUMMARY    = new QName(AJPR_NAMESPACE, "errorSummary" );
    public static final QName  ARRAY_OF_VALUES  = new QName(AJPR_NAMESPACE, "arrayOfValues");
    public static final QName  ARRAY_OF_PATHS   = new QName(AJPR_NAMESPACE, "arrayOfPaths" );
    public static final QName  ARRAY_OF_NODES   = new QName(AJPR_NAMESPACE, "arrayOfNodes" );

    private final XsltExecutable xsltExecutable = getXsltExecutable();

    private XdmValue compiledQuery = null;

    public AjpRunner withQuery(final String jsonpathQuery) throws SaxonApiException {
        if (compiledQuery != null) {
            throw new IllegalStateException("query already compiled for this instance.");
        }

        compiledQuery = getJsonpathProcessor(xsltExecutable.load30(), new XdmValue[] { makeValue(jsonpathQuery) } );

        return this;
    }

    public XdmValue getNodelist(final String jsonString) throws SaxonApiException {
        if (compiledQuery == null) {
            throw new IllegalStateException("must call withQuery() to compile the query before retrieving values");
        }
        return getNodelist( parseJson(jsonString) );
    }

    public XdmValue getNodelist(final XdmValue jsonValue) throws SaxonApiException {
        if (compiledQuery == null) {
            throw new IllegalStateException("must call withQuery() to compile the query before retrieving values");
        }
        return xsltExecutable.load30().callFunction(RUN_PROCESSOR, new XdmValue[] { jsonValue, compiledQuery } );
    }

    public String getErrorSummary(final SaxonApiException e) throws SaxonApiException {
        final QName errorCode = e.getErrorCode() != null ? e.getErrorCode() : new QName("a", "b");
        return xsltExecutable.load30().callFunction(ERROR_SUMMARY,
                                                    new XdmValue[] { makeValue(errorCode),
                                                                     makeValue(e.getMessage())
                                                                   }
                                                   ).toString();
    }

    public XdmValue arrayOfValues(final XdmValue nodelist) throws SaxonApiException {
        return callRunnerNodelistMethod(nodelist, ARRAY_OF_VALUES);
    }

    public XdmValue arrayOfPaths(final XdmValue nodelist) throws SaxonApiException {
        return callRunnerNodelistMethod(nodelist, ARRAY_OF_PATHS);
    }

    public XdmValue arrayOfNodes(final XdmValue nodelist) throws SaxonApiException {
        return callRunnerNodelistMethod(nodelist, ARRAY_OF_NODES);
    }

    private XdmValue callRunnerNodelistMethod(final XdmValue nodelist,
                                              final QName functionName) throws SaxonApiException {
        return xsltExecutable.load30().callFunction(functionName, new XdmValue[] { nodelist } );
    }

    private static XsltExecutable getXsltExecutable()  {
        try {
            final Processor     processor = getProcessor();
            final XsltCompiler  compiler  = getXsltCompiler(processor);

            return XsltXpathEnvironment.getXsltExecutable(compiler, getRunnerSource());
        } catch (SaxonApiException | URISyntaxException e) {
            throw new RuntimeException(e);
        }
    }

    @SuppressWarnings("DataFlowIssue")
    private static StreamSource getRunnerSource() throws URISyntaxException {
        return new StreamSource(THIS.getResource("/xslt/ajp-runner.xslt").toURI().toString());
    }

    private static XdmValue getJsonpathProcessor(final Xslt30Transformer xslt30Transformer,
                                                        final XdmValue[]        parameters) throws SaxonApiException {
        return xslt30Transformer.callFunction(GET_PROCESSOR, parameters);
    }

    private static final String XPATH_FUNCTIONS_NS       = "http://www.w3.org/2005/xpath-functions";

    private static final QName  PARSE_JSON_FUNCTION_NAME = new QName(XPATH_FUNCTIONS_NS, "parse-json");
    private static final QName  DEEP_EQUAL_FUNCTION_NAME = new QName(XPATH_FUNCTIONS_NS, "deep-equal");
    private static final QName  SERIALIZE_FUNCTION_NAME  = new QName(XPATH_FUNCTIONS_NS, "serialize" );

    private static final XdmMap SERIALIZE_JSON_METHOD = new XdmMap().put(makeAtomicValue("method"), makeValue("json"));

    private XdmValue parseJson(final String jsonString) throws SaxonApiException {
        final XdmFunctionItem parseJsonFn =
                getSystemFunction(xsltExecutable.getProcessor(), PARSE_JSON_FUNCTION_NAME, 1);

        return parseJsonFn.call(xsltExecutable.getProcessor(), new XdmAtomicValue(jsonString));
    }

    public boolean deepEqual(final XdmValue value1, final XdmValue value2) throws SaxonApiException {
        final XdmFunctionItem parseJsonFn =
                getSystemFunction(xsltExecutable.getProcessor(), DEEP_EQUAL_FUNCTION_NAME, 2);

        return parseJsonFn.call(xsltExecutable.getProcessor(), value1, value2)
                          .stream()
                          .asAtomic()
                          .getBooleanValue();
    }

    public String serializeToJson(final XdmValue jsonStuff) throws SaxonApiException {
        final XdmFunctionItem serializeFn =
                getSystemFunction(xsltExecutable.getProcessor(), SERIALIZE_FUNCTION_NAME, 2);

        return serializeFn.call(xsltExecutable.getProcessor(), jsonStuff, SERIALIZE_JSON_METHOD)
                .stream()
                .asString();
    }

}
