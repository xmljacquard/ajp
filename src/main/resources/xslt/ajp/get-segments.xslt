<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"

        xmlns:ajp   = "http://xmljacquard.org/ajp"

        version="3.0" >

    <xsl:include href="selector-functions.xslt"  />
    <xsl:include href="extension-functions.xslt" />

    <xsl:mode on-no-match="fail"/>

    <xsl:template match="/"                  as="map( xs:string, array(function(*))+ )*" >
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="jsonpath-query"     as="map( xs:string, array(function(*))+ )*" >
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="segments"           as="map( xs:string, array(function(*))+ )*" >
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="segment"            as="map( xs:string, array(function(*))+ )" >
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="child-segment"      as="map( xs:string, array(function(*))+ )" >
        <xsl:map-entry key="'child'" >
            <xsl:apply-templates />
        </xsl:map-entry>
    </xsl:template>

    <xsl:template match="descendant-segment" as="map( xs:string, array(function(*))+ )" >
        <xsl:map-entry key="'descendant'" >
            <xsl:apply-templates />
        </xsl:map-entry>
    </xsl:template>

    <xsl:template match="member-name-shorthand" as="array(function(*))" >
        <xsl:sequence select="[ ajp:nameSelectorKeys(?, .),                 ajp:wildcardSelectorTest#3 ]" />
    </xsl:template>

    <xsl:template match="name-selector"         as="array(function(*))" >
        <xsl:variable name="key" as="xs:string" select="ajp:expand(string-literal)"/>

        <xsl:sequence select="[ ajp:nameSelectorKeys(?, $key),              ajp:wildcardSelectorTest#3 ]" />
    </xsl:template>

    <xsl:template match="wildcard-selector"     as="array(function(*))" >
        <xsl:sequence select="[ ajp:wildcardSelectorKeys#1,                 ajp:wildcardSelectorTest#3 ]" />
    </xsl:template>

    <xsl:template match="index-selector"        as="array(function(*))" >

        <!-- Check the integer value -->
        <xsl:if test="not(ajp:isValidIJsonInteger(xs:integer(.)))" >
            <xsl:sequence select="ajp:error('SEL', 1, 'integer value of index-selector '            ||
                                                      'not within IJSON bounds (RFC9535 Sect 2.1) ' ||
                                                      'value: ' || .)" />
        </xsl:if>

        <xsl:sequence select="[ ajp:indexSelectorKeys(?, ajp:integer(.)),   ajp:wildcardSelectorTest#3 ]" />
    </xsl:template>

    <xsl:template match="slice-selector"        as="array(function(*))" >

        <!-- Check the integer values of the slice parameters -->
        <xsl:for-each select="start | end | step" >
            <xsl:if test="not(ajp:isValidIJsonInteger(xs:integer(.)))" >
                <xsl:sequence select="ajp:error('SEL', 2, 'integer value of slice parameter ' ||
                                                          'not within IJSON bounds (RFC9535 Sect 2.1) ' ||
                                                          'slice parameter: ' || name(.) || ' value: ' || .)" />
            </xsl:if>
        </xsl:for-each>

        <xsl:sequence select="[ ajp:sliceSelectorKeys(?, start, end, step), ajp:wildcardSelectorTest#3 ]" />
    </xsl:template>

    <xsl:template match="filter-selector"       as="array(function(*))" >
        <xsl:variable name="filterSelectorTest" as="function(item(), item()?, item()?) as xs:boolean" >
            <xsl:apply-templates />
        </xsl:variable>

        <xsl:sequence select="[ ajp:wildcardSelectorKeys#1,                 $filterSelectorTest ]" />
    </xsl:template>

    <xsl:template match="logical-expr"          as="function(item(), item()?, item()?) as xs:boolean" >
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="logical-or-expr"       as="function(item(), item()?, item()?) as xs:boolean" >

        <xsl:variable name="operands" as="(function(item(), item()?, item()?) as xs:boolean)*" >
            <xsl:apply-templates />
        </xsl:variable>

        <xsl:sequence select="if (count(operands) eq 1)
                              then                            $operands
                              else ajp:logicalOrExpr(?, ?, ?, $operands)" />
    </xsl:template>

    <xsl:template match="logical-and-expr"      as="function(item(), item()?, item()?) as xs:boolean" >

        <xsl:variable name="operands" as="(function(item(), item()?, item()?) as xs:boolean)*" >
            <xsl:apply-templates />
        </xsl:variable>

        <xsl:sequence select="if (count(operands) eq 1)
                              then                             $operands
                              else ajp:logicalAndExpr(?, ?, ?, $operands)" />
    </xsl:template>

    <xsl:template match="paren-expr"            as="function(item(), item()?, item()?) as xs:boolean" >

        <xsl:variable name="operand" as="function(item(), item()?, item()?) as xs:boolean" >
            <xsl:apply-templates select="logical-expr"/>
        </xsl:variable>

        <xsl:sequence select="if (exists(logical-not-op))
                              then ajp:logicalNotExpr(?, ?, ?, $operand)
                              else                             $operand
                              " />
    </xsl:template>

    <xsl:template match="test-expr[filter-query]"  as="function(item(), item()?, item()?) as xs:boolean" >

        <xsl:variable name="query" as="function(item(), item()?, item()?) as map(xs:string, item()?)*" >
            <xsl:apply-templates select="filter-query"/>
        </xsl:variable>

        <xsl:variable name="queryToLogical"        as="function(item(), item()?, item()?) as xs:boolean"
                      select="ajp:nodesToLogical(?, ?, ?, $query)" />

        <xsl:sequence select="if (exists(logical-not-op))
                              then ajp:logicalNotExpr(?, ?, ?, $queryToLogical)
                              else                             $queryToLogical
                             " />
    </xsl:template>

    <xsl:template match="test-expr[function-expr]" as="function(item(), item()?, item()?) as xs:boolean" >

        <xsl:variable name="function" as="function(*)*" >
            <xsl:apply-templates select="function-expr" />
        </xsl:variable>

        <xsl:variable name="functionName" as="xs:string"  select="function-expr/function-name"   />
        <xsl:variable name="functionType" as="element()?" select="ajp:returnType($functionName)" />

        <xsl:variable name="resultToLogical" as="function(item(), item()?, item()?) as xs:boolean" >
            <xsl:choose>
                <xsl:when test="$functionType is $VALUE_TYPE" >
                    <xsl:sequence select="ajp:error('FCT', 3, 'function extension of ValueType '  ||
                                                              'not allowed for test expression: ' ||
                                                              $functionName || '().')" />
                </xsl:when>
                <xsl:when test="$functionType is $NODES_TYPE" >
                    <xsl:sequence select="ajp:nodesToLogical(?, ?, ?, $function)" />
                </xsl:when>
                <xsl:when test="$functionType is $LOGICAL_TYPE" >
                    <xsl:sequence select="$function" />
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <xsl:sequence select="if (exists(logical-not-op))
                              then ajp:logicalNotExpr(?, ?, ?, $resultToLogical)
                              else                           $resultToLogical
                              " />
    </xsl:template>

    <xsl:template match="comparison-expr" as="function(item(), item()?, item()?) as xs:boolean" >

        <xsl:variable name="operands" as="(function(item(), item()?, item()?) as item()?)*" >
            <xsl:apply-templates select="comparable" />
        </xsl:variable>

        <xsl:variable name="operator" as="xs:string" select="comparison-op" />

        <xsl:sequence select="ajp:comparisonExpr(?, ?, ?, $operands[1], $operator, $operands[2])" />
    </xsl:template>

    <xsl:template match="comparable[literal]" as="function(item(), item()?, item()?) as item()?" >
        <xsl:apply-templates />
    </xsl:template>

    <xsl:template match="comparable[singular-query]" as="function(item(), item()?, item()?) as item()?" >
        <xsl:variable name="query" as="function(item(), item()?, item()?) as map(xs:string, item()?)*" >
            <xsl:apply-templates select="singular-query" />
        </xsl:variable>

        <xsl:sequence select="ajp:singularQuery(?, ?, ?, $query)" />
    </xsl:template>

    <xsl:template match="comparable[function-expr]" as="function(item(), item()?, item()?) as item()?" >
        <xsl:variable name="function" as="function(*)*" >
            <xsl:apply-templates select="function-expr" />
        </xsl:variable>

        <xsl:variable name="functionName" as="xs:string"  select="function-expr/function-name"    />
        <xsl:variable name="functionType" as="element()?" select="ajp:returnType($functionName)" />

        <xsl:choose>
            <xsl:when test="$functionType is $VALUE_TYPE" >
                <xsl:sequence select="$function" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ajp:error('FCT', 4, 'the function '                   || $functionName || '() ' ||
                                                          'cannot be used in a comparison ' ||
                                                          'expression; it is of type '      || $functionType || ' ' ||
                                                          'but it must be '                 || $VALUE_TYPE   || '.')
                                     " />
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template>

    <xsl:template match="literal" as="function(item(), item()?, item()?) as item()?" >
        <xsl:variable name="literalValue" as="item()?"
                      select="if (exists(number))
                              then xs:numeric(number)
                              else if (exists(string-literal))
                              then ajp:expand(string-literal)
                              else if (exists(true))
                              then true()
                              else if (exists(false))
                              then false()
                              else if (exists(null))
                              then $NULL
                              else ajp:error('INT', 2, 'impossible literal type: ' || name(.) || ' ' ||
                                                       'of value: '                || string(*/*))
                             " />

        <xsl:sequence select="function($key as item(), $item as item()?, $root as item()?) { $literalValue }" />
    </xsl:template>

    <xsl:template match="filter-query" as="function(item(), item()?, item()?) as map(xs:string, item()?)*" >

        <xsl:variable name="segments" as="map( xs:string, array(function(*))+ )*" >
            <!-- segments under either jsonpath-query or rel-query -->
            <xsl:apply-templates select="*/segments" />
        </xsl:variable>

        <xsl:sequence select="ajp:applySubSegments(?, ?, ?, $segments, exists(rel-query))" />
    </xsl:template>

    <xsl:template match="singular-query" as="function(item(), item()?, item()?) as map(xs:string, item()?)*" >

        <xsl:variable name="segments" as="map( xs:string, array(function(*))+ )*" >
            <!-- singular-query-segments segments under either rel-singular-query or abs-singular-query -->
            <xsl:apply-templates select="*/singular-query-segments" />
        </xsl:variable>

        <xsl:sequence select="ajp:applySubSegments(?, ?, ?, $segments, exists(rel-singular-query))" />
    </xsl:template>

    <xsl:template match="singular-query-segments" as="map( xs:string, array(function(*))+ )*" >
        <xsl:apply-templates />
    </xsl:template>

    <!-- N.B. Only used under the singular-query-segments -->
    <xsl:template match="index-segment | name-segment"  as="map( xs:string, array(function(*))+ )" >
        <xsl:map-entry key="'child'" >
            <xsl:apply-templates />
        </xsl:map-entry>
    </xsl:template>

    <xsl:template match="function-expr" as="function(item(), item()?, item()?) as item()*" >

        <xsl:variable name="functionName"     as="xs:string"  select="function-name" />
        <xsl:variable name="numberFormalArgs" as="xs:integer" select="ajp:getExtFunc($functionName)?paramTypes
                                                                      => array:size()" />

        <xsl:variable name="arguments"    as="(function(item(), item()?, item()?) as item()*)*" >
            <xsl:apply-templates select="function-argument" >
                <xsl:with-param name="functionName" select="$functionName" />
            </xsl:apply-templates>
        </xsl:variable>

        <xsl:if test="count($arguments) ne $numberFormalArgs">
            <xsl:sequence select="ajp:error('FCT', 5, ' bad number of arguments for: ' || $functionName || '()' ||
                                                      ' was : '                        || count($arguments) ||
                                                      ' but must be: '                 || $numberFormalArgs)" />
        </xsl:if>

        <xsl:sequence select="ajp:functionExpr(?, ?, ?, $functionName, $arguments)" />

    </xsl:template>

    <xsl:template match="function-argument[literal]" as="function(item(), item()?, item()?) as item()*" >
        <xsl:param    name="functionName" as="xs:string" />

        <xsl:variable name="argumentType" as="element()" select="ajp:argumentAtPosition($functionName, position())" />

        <xsl:variable name="literal" as="function(item(), item()?, item()?) as item()?">
            <xsl:apply-templates />
        </xsl:variable>

        <xsl:variable name="isBooleanLiteral" as="xs:boolean" select="exists(literal/child::true)
                                                                      or
                                                                      exists(literal/child::false)" />
        <xsl:choose>
            <xsl:when test="$argumentType is $VALUE_TYPE" >
                <xsl:sequence select="$literal" />
            </xsl:when>
            <xsl:when test="($argumentType is $LOGICAL_TYPE) and $isBooleanLiteral" >
                <xsl:sequence select="$literal" />
            </xsl:when>
            <xsl:when test="$argumentType is $NODES_TYPE" >
                <xsl:sequence select="ajp:error('FCT', 6,  'argument '     || position() ||
                                                           ' of function ' || $functionName || '()' ||
                                                           ' must come from a query but instead is a literal value.')
                                     " />
            </xsl:when>
            <xsl:otherwise > <!-- ($argumentType is $LOGICAL_TYPE) and not($isBooleanLiteral) -->
                <xsl:sequence select="ajp:error('FCT', 7, 'argument '        || position() ||
                                                          ' of function '    || $functionName ||
                                                          ' must be type '   || $LOGICAL_TYPE || '.')" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- RFC9535 Section 2.4.3 Well-Typedness of Function Expressions -->
    <xsl:template match="function-argument[filter-query]" as="function(item(), item()?, item()?) as item()*" >
        <xsl:param name="functionName" as="xs:string" />

        <xsl:variable name="argumentType" as="element()" select="ajp:argumentAtPosition($functionName, position())" />

        <xsl:variable name="query" as="function(item(), item()?, item()?) as map(xs:string, item()?)*" >
            <xsl:apply-templates select="filter-query"/>
        </xsl:variable>

        <xsl:sequence select="if      ( $argumentType is $LOGICAL_TYPE )
                              then ajp:nodesToLogical(?, ?, ?, $query)
                              else if ( $argumentType is $VALUE_TYPE and ajp:isSingularQuery(filter-query) )
                              then ajp:singularQuery (?, ?, ?, $query)
                              else if ( $argumentType is $VALUE_TYPE )
                              then ajp:error('FCT', 8, 'argument ' || position() ||
                                                       ' of function ' || $functionName || '()' ||
                                                       ' must be a singular query.')
                              else    (: argumentType is $NODES_TYPE :)
                                                             $query
                             " />
    </xsl:template>

    <xsl:template match="function-argument[logical-expr]" as="function(item(), item()?, item()?) as xs:boolean" >
        <xsl:param name="functionName" as="xs:string"         />

        <xsl:variable name="argumentType" as="element()" select="ajp:argumentAtPosition($functionName, position())" />

        <xsl:variable name="logicalExpr" as="function(item(), item()?, item()?) as xs:boolean" >
            <xsl:apply-templates select="logical-expr"/>
        </xsl:variable>

        <xsl:sequence select="if      ( $argumentType is $LOGICAL_TYPE )
                              then                             $logicalExpr
                              else if ( $argumentType is NODES_TYPE)
                              then ajp:nodesToLogical(?, ?, ?, $logicalExpr)
                              else if ( $argumentType is $VALUE_TYPE )
                              then ajp:error('FCT', 9, 'argument '     || position() ||
                                                       ' of function ' || $functionName || '()' ||
                                                       ' requires a singular query argument')
                              else ajp:error('INT', 3, 'argument '         || position() ||
                                                       ' of function '     || $functionName || '()' ||
                                                       ' is unknown type ' || $argumentType)
                             " />
    </xsl:template>

    <xsl:template match="function-argument[function-expr]" as="function(item(), item()?, item()?) as item()*" >
        <xsl:param name="functionName" as="xs:string"         />

        <xsl:variable name="argumentType" as="element()" select="ajp:argumentAtPosition($functionName, position())" />
        <xsl:variable name="calledFunc"   as="xs:string" select="function-expr/function-name" />

        <xsl:variable name="functionExpr" as="function(item(), item()?, item()?) as item()*" >
            <xsl:apply-templates select="function-expr"/>
        </xsl:variable>

        <xsl:sequence select="if      ( $argumentType is ajp:returnType($calledFunc) )
                              then $functionExpr
                              else if ( $argumentType is $LOGICAL_TYPE
                                        and
                                        $NODES_TYPE   is ajp:returnType($calledFunc) )
                              then ajp:nodesToLogical(?, ?, ?, $functionExpr)
                              else ajp:error('FCT', 10,  'argument '             || position()    ||
                                                         ' of function '         || $functionName || '()' ||
                                                         ' requires type '       || $argumentType ||
                                                         ' but called function ' || $calledFunc   || '()' ||
                                                         ' is type '             || ajp:returnType($calledFunc))
                             " />
    </xsl:template>

    <xsl:function name="ajp:integer" as="xs:integer?" >
        <xsl:param name="integerElement" as="element()?" />

        <xsl:sequence select="if (empty($integerElement) or empty($integerElement/text()))
                              then ()
                              else xs:integer($integerElement)
                             " />
    </xsl:function>

    <xsl:function name="ajp:isSingularQuery" as="xs:boolean" >
        <xsl:param name="filterQuery" as="element(filter-query)" />

        <xsl:sequence select="every $segment in $filterQuery//segment/*
                              satisfies name($segment) eq 'child-segment'
                                         and
                                        count($segment/*) eq 1
                                         and
                                        exists($segment[member-name-shorthand
                                                        |
                                                        index-selector
                                                        |
                                                        name-selector])" />
    </xsl:function>

    <!-- min = -2^53 + 1, max = 2^53 - 1  See RFC9535 Section 2.1 -->
    <xsl:variable name="TWO_EXP_53" as="xs:integer" select="9007199254740992" />
    <xsl:variable name="IJSON_MAX"  as="xs:integer" select=" $TWO_EXP_53 - 1"  />
    <xsl:variable name="IJSON_MIN"  as="xs:integer" select="-$TWO_EXP_53 + 1"  />

    <xsl:function name="ajp:isValidIJsonInteger" as="xs:boolean?" >
        <xsl:param name="integer" as="item()?" />

        <xsl:sequence select="($integer instance of xs:integer)
                               and
                              ($integer ge $IJSON_MIN) and ($integer le $IJSON_MAX)" />
    </xsl:function>

</xsl:stylesheet>
