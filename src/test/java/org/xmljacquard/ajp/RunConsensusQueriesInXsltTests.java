package org.xmljacquard.ajp;

import net.sf.saxon.s9api.*;
import org.junit.jupiter.api.Test;

import javax.xml.transform.stream.StreamSource;
import java.net.URISyntaxException;
import java.nio.file.Paths;
import java.util.Map;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.equalTo;
import static org.xmljacquard.ajp.XsltXpathEnvironment.*;

@SuppressWarnings("DataFlowIssue")
public class RunConsensusQueriesInXsltTests {

    private static final Class<RunConsensusQueriesInXsltTests> THIS = RunConsensusQueriesInXsltTests.class;

    @Test
    public void can_produce_consensus_queries_report() throws SaxonApiException, URISyntaxException {
        final Processor         processor      = getProcessor();
        final XsltCompiler      compiler       = getXsltCompiler(processor);
        final XsltExecutable    xsltExecutable = getXsltExecutable(compiler, getRunTestsSource());
        final Xslt30Transformer xslt           = xsltExecutable.load30();

        xslt.setStylesheetParameters(getStylesheetParams());

        final XdmValue          output  = xslt.callTemplate(null);

        assertThat(output, equalTo(XdmAtomicValue.makeAtomicValue(0)));
    }

    private static StreamSource getRunTestsSource() throws URISyntaxException {
        return new StreamSource(THIS.getResource("/xslt/consensus-queries-report.xslt").toURI().toString());
    }

    private static String getQueriesURI() {
        return THIS.getResource("/submodules/json-path-comparison/queries/").toString();
    }

    private static String getResultsURI() {
        return THIS.getResource("/submodules/json-path-comparison/docs/results/").toString();
    }

    private static Map<QName, XdmValue> getStylesheetParams() {
        return Map.of(
                new QName("queriesURI"), XdmValue.makeValue(getQueriesURI()),
                new QName("resultsURI"), XdmValue.makeValue(getResultsURI()),
                new QName("reportURL") , XdmValue.makeValue(Paths.get("ajp-consensus-report.html").toUri())
        );
    }

}
