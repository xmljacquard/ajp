<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"

        xmlns:ajp   = "http://xmljacquard.org/ajp"

        version="3.0" >

    <!-- RFC9535 Section 2.4.4 -->
    <xsl:function name= "ajp:extFuncLength" as="item()" >
        <xsl:param name="value" as="item()?" />

        <xsl:sequence select="if ($value instance of xs:string)
                              then string-length($value)
                              else if ($value instance of array(*))
                              then array:size($value)
                              else if ($value instance of map(*))
                              then map:size($value)
                              else $NOTHING
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.4.5 -->
    <xsl:function name= "ajp:extFuncCount" as="xs:integer" >
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="count($nodelist)" />
    </xsl:function>

    <!-- RFC9535 Section 2.4.6 -->
    <xsl:function name= "ajp:extFuncMatch" as="xs:boolean" >
        <xsl:param name="value"   as="item()?" />
        <xsl:param name="pattern" as="item()?" />

        <xsl:sequence select="$value instance of xs:string
                               and
                              $pattern instance of xs:string
                               and
                              matches($value, '^' || $pattern || '$')
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.4.7 -->
    <xsl:function name= "ajp:extFuncSearch" as="xs:boolean" >
        <xsl:param name="value"   as="item()?" />
        <xsl:param name="pattern" as="item()?" />

        <xsl:sequence select="$value instance of xs:string
                               and
                              $pattern instance of xs:string
                               and
                              matches($value, $pattern)
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.4.8 -->
    <xsl:function name= "ajp:extFuncValue" as="item()">
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="if (count($nodelist) eq 1)
                              then $nodelist?*
                              else $NOTHING
                             " />
    </xsl:function>

    <!-- N.B. This to allow us to test a function returning a nodelist -->
    <xsl:function name= "ajp:extFuncIdentity" as="map(xs:string, item()?)*" >
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="$nodelist" />
    </xsl:function>

    <!-- N.B. This to allow us to test a function returning logical from a nodelist -->
    <xsl:function name= "ajp:extFuncEmpty" as="xs:boolean">
        <xsl:param name="nodelist" as="map(xs:string, item()?)*" />

        <xsl:sequence select="count($nodelist) eq 0" />
    </xsl:function>

    <!-- N.B. This to allow us to test a function with logical argument -->
    <xsl:function name= "ajp:extFuncBoolStr" as="item()">
        <xsl:param name="boolean" as="item()?" />

        <xsl:sequence select="if ($boolean instance of xs:boolean)
                              then string($boolean)
                              else $NOTHING
                             " />
    </xsl:function>

    <!--
    Function Extensions

    length   ( ValueType:   string/map/array          ) => ValueType   : integer or Nothing
    count    ( NodesType:   nodelist                  ) => ValueType   : integer (0 or more)
    match    ( ValueType:   string, ValueType: string ) => LogicalType : LogicalTrue if regex match
    search   ( ValueType:   string, ValueType: string ) => LogicalType : LogicalTrue if substring
    value    ( NodesType:   nodelist                  ) => ValueType   : single node or Nothing

    identity ( NodesType:   nodelist                  ) => NodesType   : returns parameter
    empty    ( NodesType:   nodelist                  ) => LogicalType : true of count(nodelist) == 0
    boolstr  ( LogicalType: boolean                   ) => ValueType   : 'true', 'false' or Nothing
    -->

    <xsl:function name= "ajp:getExtFunc" as="map(*)" >
        <xsl:param name="name" as="xs:string" />

        <xsl:sequence select="if (map:contains($extensionFunctions, $name))
                              then $extensionFunctions($name)
                              else ajp:error('FCT', 1, 'unknown function extension: ' || $name || '().')
                             " />
    </xsl:function>

    <xsl:function name= "ajp:returnType" as="element()" >
        <xsl:param name="name"     as="xs:string"  />

        <xsl:sequence select="ajp:getExtFunc($name)?returnType" />
    </xsl:function>

    <xsl:function name= "ajp:argumentAtPosition" as="element()" >
        <xsl:param name="name"     as="xs:string"  />
        <xsl:param name="position" as="xs:integer" />

        <xsl:sequence select="let $numberArgs := array:size(ajp:getExtFunc($name)?paramTypes)
                              return if ($position le $numberArgs)
                                     then ajp:getExtFunc($name)?paramTypes($position)
                                     else ajp:error('FCT', 2, 'function: ' || $name       || '()'         ||
                                                              ' takes '    || $numberArgs || ' arguments' ||
                                                              ' but here has at least '   || $position    ||
                                                              ' arguments in its invocation.')
                             " />
    </xsl:function>

    <xsl:variable name="extensionFunctions" as="map(xs:string, map(*))"
                  select="map:merge((
                            ajp:extFunc('length',   ajp:extFuncLength#1,   $VALUE_TYPE,   [ $VALUE_TYPE              ]),
                            ajp:extFunc('count',    ajp:extFuncCount#1,    $VALUE_TYPE,   [ $NODES_TYPE              ]),
                            ajp:extFunc('match',    ajp:extFuncMatch#2,    $LOGICAL_TYPE, [ $VALUE_TYPE, $VALUE_TYPE ]),
                            ajp:extFunc('search',   ajp:extFuncSearch#2,   $LOGICAL_TYPE, [ $VALUE_TYPE, $VALUE_TYPE ]),
                            ajp:extFunc('value',    ajp:extFuncValue#1,    $VALUE_TYPE,   [ $NODES_TYPE              ]),

                            ajp:extFunc('identity', ajp:extFuncIdentity#1, $NODES_TYPE,   [ $NODES_TYPE              ]),
                            ajp:extFunc('empty',    ajp:extFuncEmpty#1,    $LOGICAL_TYPE, [ $NODES_TYPE              ]),
                            ajp:extFunc('boolstr',  ajp:extFuncBoolStr#1,  $VALUE_TYPE,   [ $LOGICAL_TYPE            ])
                          ))" />

    <xsl:function name="ajp:extFunc" as="map(xs:string, map(*))" >
        <xsl:param name="name"       as="xs:string"        />
        <xsl:param name="function"   as="function(*)"      />
        <xsl:param name="returnType" as="element()"        />
        <xsl:param name="paramTypes" as="array(element())" />

        <xsl:map-entry key="$name">
            <xsl:map>
                <xsl:map-entry key="'name'"       select="$name"       />
                <xsl:map-entry key="'function'"   select="$function"   />
                <xsl:map-entry key="'returnType'" select="$returnType" />
                <xsl:map-entry key="'paramTypes'" select="$paramTypes" />
            </xsl:map>
        </xsl:map-entry>
    </xsl:function>

    <!-- elements used as singletons for functions and comparisons; use node identity            -->
    <xsl:variable name="VALUE_TYPE"   as="element(ValueType)"   select="ajp:element('ValueType')"   />
    <xsl:variable name="LOGICAL_TYPE" as="element(LogicalType)" select="ajp:element('LogicalType')" />
    <xsl:variable name="NODES_TYPE"   as="element(NodesType)"   select="ajp:element('NodesType')"   />

    <xsl:variable name="NOTHING"      as="element(Nothing)"     select="ajp:element('Nothing')"     />
    <xsl:variable name="NULL"         as="element(Null)"        select="ajp:element('Null')"        />

    <!-- For generating the singleton elements used in function returns and comparisons -->
    <xsl:function name="ajp:element" as="element()" >
        <xsl:param name="name" as="xs:string" />

        <xsl:element name="{$name}">
            <xsl:value-of select="$name" />
        </xsl:element>
    </xsl:function>

</xsl:stylesheet>
