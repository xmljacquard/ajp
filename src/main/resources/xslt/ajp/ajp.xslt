<xsl:package

        name            = "http://xmljacquard.org/ajp"
        package-version = "0.0.1"

        declared-modes  = "yes"

        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"

        xmlns:ajp   = "http://xmljacquard.org/ajp"
        xmlns:cs    = "http://nineml.com/ns/coffeesacks"

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

    <xsl:include href="get-segments.xslt"   />
    <xsl:include href="apply-segments.xslt" />

    <xsl:expose component="*"        names="*"                             visibility="private" />

    <!-- The following two functions are the only two that are required for JSONPATH processing -->
    <xsl:expose component="function" names="ajp:getSegments#1"             visibility="public"  />
    <xsl:expose component="function" names="ajp:applySegments#2"           visibility="public"  />

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

    <xsl:variable name="namespace_element" as="element()" >
        <ajp:namespace/>
    </xsl:variable>
    <xsl:variable name="ajp:NAMESPACE" as="xs:anyURI" select="namespace-uri($namespace_element)" />

    <!-- The parser is instantiated at the time of the stylesheet compilation, thanks to "static" -->
    <xsl:variable name="ajp:parser" select="cs:load-grammar('jsonpath.ixml', map { })" as="function(*)"
                  static="yes"/>

    <xsl:function name="ajp:getSegments"  as="map( xs:string, array(function(*))* )*" >
        <xsl:param name="jsonpathQuery" as="xs:string" />

        <xsl:apply-templates select="ajp:getAST($jsonpathQuery)" />
    </xsl:function>

    <xsl:function name="ajp:applySegments" as="map(xs:string, item()?)*"               >
        <xsl:param name="root"             as="item()?"                               />
        <xsl:param name="segments"         as="map(xs:string, array(function(*))* )*" />

        <xsl:sequence select="let $startNodelist  := map { '$' : $root },
                                  $returnNodelist := ajp:applySegments($startNodelist, $segments, $root)
                              return ajp:convertNulls($returnNodelist)" />
    </xsl:function>

    <!-- Produces the XML-version AST, the same as used by l:getSegments().  For debugging or reporting -->
    <xsl:function name="ajp:getAST"     as="document-node()" >
        <xsl:param name="jsonpathQuery" as="xs:string" />

        <xsl:sequence select="$ajp:parser($jsonpathQuery)" />
    </xsl:function>

    <!-- Calls the nineml ixml processor with the grammar and produces a report on ambiguities, etc -->
    <xsl:function name="ajp:hygieneReport" as="item()" >
        <xsl:sequence select="cs:hygiene-report('jsonpath.ixml')" />
    </xsl:function>

    <!-- Replace any top-level $NULL values in the nodelist with empty sequence () -->
    <xsl:function name="ajp:convertNulls"  as="map(xs:string, item()?)*"               >
        <xsl:param name="nodelist"         as="map(xs:string, item()?)*"              />

        <xsl:sequence select="for $map in $nodelist
                              return if ($map?* instance of node() and $map?* is $NULL)
                                     then map:entry(map:keys($map), ())
                                     else $map" />
    </xsl:function>

    <xsl:function name="ajp:error" >
        <xsl:param name="prefix"      as="xs:string"  />
        <xsl:param name="integer"     as="xs:integer" />
        <xsl:param name="description" as="xs:string"  />

        <xsl:variable name="localPart" as="xs:string" select="$prefix || format-integer($integer, '0000')" />
        <xsl:variable name="code"      as="xs:QName"  select="QName($ajp:NAMESPACE, 'ajp:' || $localPart)" />

        <xsl:variable name="adjustedDescription" as="xs:string"
                      select="if ($prefix eq 'INT')
                              then 'internal error: ' || $description
                              else $description
                             " />

        <xsl:sequence select="error($code, $adjustedDescription)" />
    </xsl:function>

    <xsl:function name="ajp:arrayOfValues" as="array(item()?)" >
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="fold-left($nodelist, array { }, ajp:appendValue#2)" />
    </xsl:function>

    <xsl:function name="ajp:arrayOfPaths" as="array(xs:string)" >
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="fold-left($nodelist, array { }, ajp:appendPath#2)" />
    </xsl:function>

    <xsl:function name="ajp:arrayOfNodes" as="array(map(xs:string, item()?))" >
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="fold-left($nodelist, array { }, ajp:appendNode#2)" />
    </xsl:function>

    <xsl:function name="ajp:appendValue" as="item()*" >
        <xsl:param name="zero" as="item()*" />
        <xsl:param name="seq"  as="item()"  />

        <xsl:sequence select="array:append($zero, $seq?*)" />
    </xsl:function>

    <xsl:function name="ajp:appendPath" as="item()*" >
        <xsl:param name="zero" as="item()*" />
        <xsl:param name="seq"  as="item()"  />

        <xsl:sequence select="array:append($zero, map:keys($seq))" />
    </xsl:function>

    <xsl:function name="ajp:appendNode" as="array(map(xs:string, item()?))" >
        <xsl:param name="zero" as="item()*" />
        <xsl:param name="seq"  as="map(xs:string, item()?)"  />

        <xsl:sequence select="array:append($zero, $seq)" />
    </xsl:function>

    <!-- TODO Currently uses the error from nineml; confirm for other ixml implementations -->
    <xsl:function name="ajp:errorSummary"   as="xs:string" >
        <xsl:param name="error_code"        as="xs:QName"  />
        <xsl:param name="error_description" as="xs:string" />

        <xsl:sequence select="if (namespace-uri-from-QName($error_code) eq $ajp:NAMESPACE)
                              then $error_code || ': ' || $error_description
                              else ajp:ixmlErrorSummary($error_code, $error_description)" />
    </xsl:function>

    <xsl:function name="ajp:ixmlErrorSummary" as="xs:string" >
        <xsl:param name="error_code"          as="xs:QName"  />
        <xsl:param name="error_description"   as="xs:string" />

        <!-- convert the string $error_description to XML in order to retrieve the values for the message -->
        <xsl:variable name="fail" as="element()"
                      select="($error_description => ajp:escape() => parse-xml())/failed" />

        <xsl:sequence select="'Parsing error in query line '          || $fail/line       ||
                              ' column '                              || $fail/column     ||
                              ' unexpected character: '      || $APOS || $fail/unexpected || $APOS || '.'
                             " />
    </xsl:function>


</xsl:package>