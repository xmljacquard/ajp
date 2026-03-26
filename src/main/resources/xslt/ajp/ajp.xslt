<xsl:package

        name            = "http://xmljacquard.org/ajp"
        package-version = "0.0.1"

        declared-modes  = "yes"

        xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"

        xmlns:ajp = "http://xmljacquard.org/ajp"
        xmlns:cs  = "http://nineml.com/ns/coffeesacks"

        version="3.0" >

    <!-- ajp - A JSONPATH Processor - an XSLT package using ixml (nineml) to implements RFC9535 -->

    <!-- Copyright 2025 xmljacquard.org

         Licensed under the Apache License, Version 2.0 (the "License");
         you may not use this file except in compliance with the License.
         You may obtain a copy of the License at

         http://www.apache.org/licenses/LICENSE-2.0

         Unless required by applicable law or agreed to in writing, software
         distributed under the License is distributed on an "AS IS" BASIS,
         WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
         See the License for the specific language governing permissions and
         limitations under the License.
    -->

    <xsl:include href="ajp-common.xslt" />

    <!-- The following two declarations use nineml/CoffeeSacks for the parser and hygiene repot -->

    <!-- The parser is instantiated at the time of the stylesheet compilation, thanks to "static" -->
    <xsl:variable name="ajp:parser" select="cs:load-grammar(resolve-uri('jsonpath.ixml'), map { })"
                  as="function(*)" static="yes"/>

    <!-- Calls the nineml ixml processor with the grammar and produces a report on ambiguities, etc -->
    <xsl:function name="ajp:hygieneReport" as="item()" >
        <xsl:sequence select="cs:hygiene-report(resolve-uri('jsonpath.ixml'))" />
    </xsl:function>

    <xsl:expose component="*"        names="*"                             visibility="private" />

    <!-- Create the function for processing the jsonpath query string provided as an argument  -->
    <xsl:expose component="function" names="ajp:getProcessor#1"            visibility="public"  />

    <!-- This function allow retrieving the abstract syntax tree of the query                  -->
    <xsl:expose component="function" names="ajp:getAST#1"                  visibility="public"  />

    <!-- Use the two following functions for retrieving arrays of returned values or paths     -->
    <xsl:expose component="function" names="ajp:arrayOfValues#1"           visibility="public"  />
    <xsl:expose component="function" names="ajp:arrayOfPaths#1"            visibility="public"  />
    <xsl:expose component="function" names="ajp:arrayOfNodes#1"            visibility="public"  />

    <!-- Produce the nineml hygiene report (ex: grammar ambiguities)                           -->
    <xsl:expose component="function" names="ajp:hygieneReport#0"           visibility="public"  />

    <!-- Utility functions that can be used for replacing otherwise non-printing characters.   -->
    <xsl:expose component="function" names="ajp:replaceNonPrintingChars#1" visibility="public"  />
    <xsl:expose component="function" names="ajp:replaceHigherPlaneChars#1" visibility="public"  />

    <!-- Utility function for replacing control chars ('\r', '\n', etc) in printed query       -->
    <xsl:expose component="function" names="ajp:escape#1"                  visibility="public"  />

    <!-- The URI of the namespace used by AJP; useful for matching against $err:code values.   -->
    <xsl:expose component="variable" names="ajp:NAMESPACE"                 visibility="public"  />

    <!-- Construct a text summary of parsing / query compilation errors                        -->
    <xsl:expose component="function" names="ajp:errorSummary#2"            visibility="public"  />

</xsl:package>