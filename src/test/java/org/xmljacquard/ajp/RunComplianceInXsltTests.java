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
public class RunComplianceInXsltTests {

    private static final Class<RunComplianceInXsltTests> THIS = RunComplianceInXsltTests.class;

    @Test
    public void can_produce_compliance_suite_tests_report() throws SaxonApiException, URISyntaxException {

        final Processor         processor      = getProcessor();
        final XsltCompiler      compiler       = getXsltCompiler(processor);
        final XsltExecutable    xsltExecutable = getXsltExecutable(compiler, getRunTestsSource());
        final Xslt30Transformer xslt           = xsltExecutable.load30();

        xslt.setStylesheetParameters(getStylesheetParams());

        final XdmValue          output  = xslt.callTemplate(null);

        assertThat(output, equalTo(XdmAtomicValue.makeAtomicValue(0)));
    }

    private static StreamSource getRunTestsSource() throws URISyntaxException {
        return new StreamSource(THIS.getResource("/xslt/compliance-tests-report.xslt").toURI().toString());
    }

    private static String getCtsTestsURI() {
        return THIS.getResource("/submodules/jsonpath-compliance-test-suite/cts.json").toString();
    }

    private static String getAjpTestsURI() {
        return THIS.getResource("/json/ajp.json").toString();
    }

    private static Map<QName, XdmValue> getStylesheetParams() {
        return Map.of(
                new QName("ctsTestsURI"), XdmValue.makeValue(getCtsTestsURI()),
                new QName("ajpTestsURI"), XdmValue.makeValue(getAjpTestsURI()),
                new QName("reportURL") ,  XdmValue.makeValue(Paths.get("ajp-compliance-tests-report.html").toUri())
        );
    }

}
