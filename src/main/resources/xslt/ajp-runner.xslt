<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"

        xmlns:ajp   = "http://xmljacquard.org/ajp"
        xmlns:ajpr  = "http://xmljacquard.org/ajp/runner"

        version="3.0" >

    <xsl:use-package name="http://xmljacquard.org/ajp" package-version="*" />

    <xsl:template name="xsl:initial-template" >
        <!-- Nothing to do; have an XSLT environment that allows us to call XPath functions in an XSLT package -->
    </xsl:template>

    <xsl:function name="ajpr:getProcessor" as="function(item()?) as map(xs:string, item()?)*"
                                                                                     visibility="public">
        <xsl:param name="jsonpathQuery" as="xs:string" />

        <xsl:sequence select="ajp:getProcessor($jsonpathQuery)" />
    </xsl:function>

    <xsl:function name="ajpr:runProcessor" as="map(xs:string, item()?)*"             visibility="public">
        <xsl:param name="root"             as="item()?"                                       />
        <xsl:param name="processor"        as="function(item()?) as map(xs:string, item()?)*" />

        <xsl:sequence select="$processor($root)" />
    </xsl:function>

    <xsl:variable name="LT" as="xs:string" select="'&lt;'" />

    <xsl:function name="ajpr:errorSummary" as="xs:string"                             visibility="public">
        <xsl:param name="error_code"        as="xs:QName"  />
        <xsl:param name="error_description" as="xs:string" />

        <xsl:sequence select="ajp:errorSummary($error_code, $error_description)" />
    </xsl:function>

    <xsl:function name="ajpr:arrayOfValues" as="array(item()?)"                       visibility="public">
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="ajp:arrayOfValues($nodelist)" />
    </xsl:function>

    <xsl:function name="ajpr:arrayOfPaths" as="array(xs:string)"                      visibility="public">
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="ajp:arrayOfPaths($nodelist)" />
    </xsl:function>

    <xsl:function name="ajpr:arrayOfNodes" as="array( map(xs:string, item()?) )"      visibility="public">
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="ajp:arrayOfNodes($nodelist)" />
    </xsl:function>

</xsl:stylesheet>