<xsl:stylesheet
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"

        xmlns:ajp = "http://xmljacquard.org/ajp"
        xmlns:cs  = "http://nineml.com/ns/coffeesacks"

        version="3.0" >

    <!-- ajp - A JSONPATH Processor - an XSLT stylesheet for Saxon-JS using ixml (jwixml) to implements RFC9535 -->

    <!-- Copyright 2025-2026 xmljacquard.org

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

    <xsl:include href="../jwiXML/coffeeSacks.3.xsl"      />
    <xsl:include href="../jwiXML/jwiXML.processor.3.xsl" />
    <xsl:include href="ajp-common.xslt"                  />

    <xsl:variable name="ajp:parser" as="function(*)"
                  select="cs:load-grammar(resolve-uri('jsonpath.ixml'))"  />

    <xsl:function name="ajp:evaluate" as="map(xs:string, item()?)*" visibility="public">
        <xsl:param name="jsonpathQuery" as="xs:string" />
        <xsl:param name="rootString"    as="xs:string" />

        <xsl:variable name="processor" as="function(*)" select="ajp:getProcessor($jsonpathQuery)" />

        <xsl:variable name="root" as="item()?" select="parse-json($rootString)" />

        <xsl:sequence select="$processor($root)" />
    </xsl:function>

    <xsl:function name="ajp:evaluateToArray" as="array(map(xs:string, item()?))" visibility="public">
        <xsl:param name="jsonpathQuery" as="xs:string" />
        <xsl:param name="rootString"    as="xs:string" />

        <xsl:sequence select="array { ajp:evaluate($jsonpathQuery, $rootString) }" />
    </xsl:function>

    <xsl:function name="ajp:getType" as="xs:string" >
        <xsl:param name="thing" as="item()?" />

        <xsl:sequence select="if (count($thing) eq 0)
                              then 'empty'
                              else if ($thing instance of map(*))
                              then 'map'
                              else if ($thing instance of array(*))
                              then 'array'
                              else if ($thing instance of xs:anyAtomicType)
                              then 'atomic'
                              else 'unknown'
                             " />
    </xsl:function>

    <xsl:function name="ajp:print-json" as="xs:string?" >
        <xsl:param name="values" as="item()*" />

        <xsl:variable name="toPrint" as="item()?"
                      select="if (count($values) eq 0)
                              then ()
                              else if (count($values) eq 1)
                              then $values
                              else array { $values }" />

        <xsl:sequence select="serialize($toPrint, map { 'method' : 'json',
                                                        'indent' : true() })" />
    </xsl:function>

</xsl:stylesheet>