<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"

        xmlns:tests = "local:functions:for:test"

        expand-text = "yes"
        exclude-result-prefixes = "#all"

        version="3.0" >

    <xsl:param name="resultsURI" as="xs:string" />

    <xsl:output indent="yes" />

    <!-- Retrieve the per-consensus-test results from the HTML files -->

    <xsl:template name="consensuses" as="element(consensuses)">
        <consensuses>
            <xsl:for-each select="uri-collection($resultsURI || '?recurse=yes;select=*.html')">

                <xsl:sort />

                <xsl:variable name="testName" as="xs:string" select="replace(string(.),
                                                                             '^.*[/]([^/]*).html$',
                                                                             '$1')" />
                <query name="{$testName}" >
                    <xsl:sequence select="tests:getConsensus(unparsed-text(.))" />
                </query>
            </xsl:for-each>
        </consensuses>
    </xsl:template>

    <xsl:variable name="CONSENSUS_START" as="xs:string"
                  select="'&lt;h3 id=&quot;consensus&quot;&gt;Consensus&lt;/h3&gt;'" />

    <xsl:variable name="CONSENSUS_END"   as="xs:string"
                  select="'((&lt;/pre&gt;)|(&lt;p&gt;Not supported&lt;/p&gt;))'" />

    <xsl:variable name="PART_BEFORE"    as="xs:string"
                  select="'^.*'   || $CONSENSUS_START || '(.*)$'" />

    <xsl:variable name="PART_AFTER"     as="xs:string"
                  select="'^(.*?' || $CONSENSUS_END || ')' || '.*$'" />

    <xsl:function name="tests:getConsensus" as="element(consensus)" >
        <xsl:param name="html" as="xs:string" />

        <consensus>
            <xsl:choose>
                <xsl:when test="$html => contains($CONSENSUS_START) => not()" >
                    <none/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$html => replace($PART_BEFORE, '$1', 's')
                                                => replace($PART_AFTER,  '$1', 's')
                                                => parse-xml-fragment()" />
                </xsl:otherwise>
            </xsl:choose>
        </consensus>
    </xsl:function>

</xsl:stylesheet>