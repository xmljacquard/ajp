package org.xmljacquard.ajp;

import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.XdmMap;
import net.sf.saxon.s9api.XdmValue;
import org.junit.jupiter.api.Test;

import static java.util.Collections.singletonMap;
import static org.hamcrest.MatcherAssert.assertThat;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertThrows;

public class AjpRunnerTests {

    @Test
    public void error_if_retrieve_before_compilation() {
        final AjpRunner runnerNotCompiled = new AjpRunner();
        final IllegalStateException ise = assertThrows(IllegalStateException.class,
                                                       () -> runnerNotCompiled.getNodelist("") );

        assertThat(ise.getMessage(), containsString("must call withQuery() to compile the query "
                                                  + "before retrieving values"));
    }

    @Test
    public void can_run_jsonpath_processor() throws SaxonApiException {
        final String   query    = "$.a.b.c";
        final String   queryArg1 = "{ \"a\" : { \"b\" : { \"c\" : \"C\" } } }";
        final String   queryArg2 = "{ \"a\" : { \"b\" : { \"c\" : \"hello\" } } }";

        final XdmValue outputToMatch1 =  XdmMap.makeMap(singletonMap("$['a']['b']['c']", "C"));
        final XdmValue outputToMatch2 =  XdmMap.makeMap(singletonMap("$['a']['b']['c']", "hello"));

        final AjpRunner runner = new AjpRunner().withQuery(query);

        assertThat("Return map is not equal", runner.deepEqual(runner.getNodelist(queryArg1), outputToMatch1));
        assertThat("Return map is not equal", runner.deepEqual(runner.getNodelist(queryArg2), outputToMatch2));
    }

    @Test
    public void can_get_ixml_error_from_jsonpath_processor() {
        final String   query    = " $.a";   // error because space before '$'

        final Exception e = assertThrows(SaxonApiException.class, () -> new AjpRunner().withQuery(query));
        assertThat(e.getMessage(), containsString("failed xmlns:ixml"));
    }

    @Test
    public void can_get_ajp_error_from_jsonpath_processor() {
        final String   query    = "$[?length($.*)==4]";   // error because of function argument type

        final SaxonApiException e = assertThrows(SaxonApiException.class, () -> new AjpRunner().withQuery(query));
        assertThat(e.getMessage(), containsString("argument 1 of function length() must be a singular query."));
        assertThat(e.getErrorCode().toString(), equalTo("ajp:FCT0008"));
    }

    @Test
    public void can_get_error_summary_nineml() throws SaxonApiException {
        final String    query  = " $.a";   // error because space before '$'
        final AjpRunner runner = new AjpRunner();

        final SaxonApiException e = assertThrows(SaxonApiException.class, () -> runner.withQuery(query));
        final String errString = "Parsing error in query line 1 column 1 unexpected character: ' '.";
        assertThat(runner.getErrorSummary(e), containsString(errString));
    }

    @Test
    public void can_get_error_summary_ajp() throws SaxonApiException {
        final String    query  = "$[?length($.*)==4]";   // error because space before '$'
        final AjpRunner runner = new AjpRunner();

        final SaxonApiException e = assertThrows(SaxonApiException.class, () -> runner.withQuery(query));
        final String errString = "argument 1 of function length() must be a singular query.";
        assertThat(e.getErrorCode(), equalTo(new QName("http://xmljacquard.org/ajp", "FCT0008")));
        assertThat(runner.getErrorSummary(e), containsString(errString));
    }

    @Test
    public void can_serialize_to_json() throws SaxonApiException {
        final String   query    = "$.a.b.c";
        final String   queryArg = "{ \"a\" : { \"b\" : { \"c\" : \"hello\" } } }";

        final AjpRunner runner = new AjpRunner().withQuery(query);
        final XdmValue  nodelist      = runner.getNodelist(queryArg);
        final XdmValue  values        = runner.arrayOfValues(nodelist);
        final XdmValue  paths         = runner.arrayOfPaths(nodelist);
        final XdmValue  nodes         = runner.arrayOfNodes(nodelist);

        assertThat(runner.serializeToJson(values), equalTo("[\"hello\"]"));
        assertThat(runner.serializeToJson(paths),  equalTo("[\"$['a']['b']['c']\"]"));
        assertThat(runner.serializeToJson(nodes),  equalTo("[{\"$['a']['b']['c']\":\"hello\"}]"));
    }
}
