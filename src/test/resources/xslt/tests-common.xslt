<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"

        xmlns:tests = "local:functions:for:test"

        expand-text = "yes"
        exclude-result-prefixes = "#all"

        version="3.0" >

    <xsl:variable name="CHECK_MARK_UNICODE" as="xs:string" select="'&#x2713;'" />
    <xsl:variable name="X_MARK_UNICODE"     as="xs:string" select="'&#x2717;'" />

    <xsl:function name="tests:prettyPrintJson" as="xs:string?" >
        <xsl:param name="items" as="item()*" />

        <xsl:variable name="fixedUpItems" as="item()*"
                      select="if (count($items) gt 1)
                                  then array { $items }
                                  else         $items" />

        <xsl:sequence select="serialize( $fixedUpItems, map { 'method' : 'json' } )" />
    </xsl:function>

    <xsl:function name="tests:xmlOrText" >
        <xsl:param name="input" />

        <xsl:try>
            <xsl:sequence select="parse-xml($input)" />
            <xsl:catch>
                <xsl:sequence select="'NOT XML: ' || string($input)" />
            </xsl:catch>
        </xsl:try>
    </xsl:function>

</xsl:stylesheet>