<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"

        xmlns:ajp   = "http://xmljacquard.org/ajp"

        version="3.0" >

    <xsl:include href="slice-provider.xslt" />

    <xsl:function name="ajp:wildcardSelectorKeys" as="item()*" >
        <xsl:param name="item"   as="item()?"  />

        <xsl:sequence select="ajp:simpleKeys($item)" />
    </xsl:function>

    <xsl:function name="ajp:wildcardSelectorTest" as="xs:boolean" >
        <xsl:param name="key"    as="item()"   />
        <xsl:param name="item"   as="item()?"  />
        <xsl:param name="root"   as="item()?"  />

        <xsl:sequence select="true()" />
    </xsl:function>

    <xsl:function name="ajp:nameSelectorKeys" as="item()*" >
        <xsl:param name="item"  as="item()?"   />

        <xsl:param name="match" as="xs:string" />

        <xsl:sequence select="if (($item instance of map(*))
                                    and
                                  ($match instance of xs:string))
                              then $match[ map:contains($item, $match) ]
                              else ()" />
    </xsl:function>

    <xsl:function name="ajp:indexSelectorKeys" as="item()*" >
        <xsl:param name="item"  as="item()?"    />

        <xsl:param name="match" as="xs:integer" />

        <xsl:sequence select="if ($item instance of array(*) and $match instance of xs:integer)
                              then let $length := array:size($item),
                                       $index := ( if ($match ge 0)
                                                   then ($match + 1)
                                                   else ($match + 1 + $length)
                                                 )
                                   return $index[(. gt 0) and (. le $length)]
                              else ()
                             " />
    </xsl:function>

    <xsl:function name="ajp:sliceSelectorKeys" as="item()*" >
        <xsl:param name="item"  as="item()?"     />

        <xsl:param name="start" as="xs:integer?" />
        <xsl:param name="end"   as="xs:integer?" />
        <xsl:param name="step"  as="xs:integer?" />

        <xsl:sequence select="if ($item instance of array(*))
                              then ajp:sliceProvider($item, $start, $end, $step) => ajp:keysFromProvider()
                              else ()
                             " />
    </xsl:function>

    <xsl:function name="ajp:keysFromProvider" as="item()*" >
        <xsl:param name="provider" as="map(*)" />

        <xsl:sequence select="if ($provider?end-reached)
                              then ()
                              else (
                                  $provider?get-current($provider),
                                  ajp:keysFromProvider($provider?move-next($provider))
                              )
                              " />
    </xsl:function>

    <!-- Process the segments contained by a sub-query within a filter selector -->
    <xsl:function name="ajp:applySubSegments" as="map(xs:string, item()?)*" >
        <xsl:param name="key"      as="item()"                                 />
        <xsl:param name="item"     as="item()?"                                />
        <xsl:param name="root"     as="item()?"                                />

        <xsl:param name="segments" as="map( xs:string, array(function(*))+ )*" />
        <xsl:param name="relative" as="xs:boolean"                             />

        <xsl:variable name="startNodelist" as="map(xs:string, item()?)*"
                      select="if ($relative)
                              then map { ajp:path('@', $key) : $item($key) }
                              else map { '$'                 : $root       }
                             "/>

        <xsl:sequence select="ajp:applySegments($startNodelist, $segments, $root)" />
    </xsl:function>

    <xsl:function name="ajp:logicalOrExpr" as="xs:boolean" >
        <xsl:param name="key"      as="item()"                                              />
        <xsl:param name="item"     as="item()?"                                             />
        <xsl:param name="root"     as="item()?"                                             />

        <xsl:param name="operands" as="(function(item(), item()?, item()?) as xs:boolean)*" />

        <xsl:sequence select="some $operand in $operands
                              satisfies $operand($key, $item, $root)" />
    </xsl:function>

    <xsl:function name="ajp:logicalAndExpr" as="xs:boolean" >
        <xsl:param name="key"      as="item()"                                              />
        <xsl:param name="item"     as="item()?"                                             />
        <xsl:param name="root"     as="item()?"                                             />

        <xsl:param name="operands" as="(function(item(), item()?, item()?) as xs:boolean)*" />

        <xsl:sequence select="every $operand in $operands
                              satisfies $operand($key, $item, $root)" />
    </xsl:function>

    <xsl:function name="ajp:logicalNotExpr" as="xs:boolean" >
        <xsl:param name="key"      as="item()"                                           />
        <xsl:param name="item"     as="item()?"                                          />
        <xsl:param name="root"     as="item()?"                                          />

        <xsl:param name="operand"  as="function(item(), item()?, item()?) as xs:boolean" />

        <xsl:sequence select="not($operand($key, $item, $root))" />
    </xsl:function>

    <xsl:function name="ajp:nodesToLogical" as="xs:boolean" >
        <xsl:param name="key"      as="item()"                                                         />
        <xsl:param name="item"     as="item()?"                                                        />
        <xsl:param name="root"     as="item()?"                                                        />

        <xsl:param name="operand"  as="function(item(), item()?, item()?) as map(xs:string, item()?)*" />

        <xsl:sequence select="count($operand($key, $item, $root)) gt 0" />
    </xsl:function>

    <!-- RFC9535 Section 2.3.5.2.2.  Comparisons -->
    <xsl:function name="ajp:comparisonExpr" as="xs:boolean" >
        <xsl:param name="key"       as="item()"                                        />
        <xsl:param name="item"      as="item()?"                                       />
        <xsl:param name="root"      as="item()?"                                       />

        <xsl:param name="operand1F" as="function(item(), item()?, item()?) as item()?" />
        <xsl:param name="operator"  as="xs:string"                                     />
        <xsl:param name="operand2F" as="function(item(), item()?, item()?) as item()?" />

        <xsl:variable name="operandA" as="item()?" select="$operand1F($key, $item, $root)" />
        <xsl:variable name="operandB" as="item()?" select="$operand2F($key, $item, $root)" />

        <xsl:variable name="equal"      as="xs:boolean" select="ajp:comparisonEqual   ($operandA, $operandB)" />
        <xsl:variable name="aLessThanB" as="xs:boolean" select="ajp:comparisonLessThan($operandA, $operandB)" />
        <xsl:variable name="bLessThanA" as="xs:boolean" select="ajp:comparisonLessThan($operandB, $operandA)" />

        <xsl:choose>
            <xsl:when test="$operator eq '=='" >
                <xsl:sequence select="$equal" />
            </xsl:when>
            <xsl:when test="$operator eq '&lt;'"  >
                <xsl:sequence select="$aLessThanB" />
            </xsl:when>
            <xsl:when test="$operator eq '!='"  >
                <xsl:sequence select="not($equal)" />
            </xsl:when>
            <xsl:when test="$operator eq '&lt;='"  >
                <xsl:sequence select="$aLessThanB or $equal" />
            </xsl:when>
            <xsl:when test="$operator eq '&gt;'"   >
                <xsl:sequence select="$bLessThanA" />
            </xsl:when>
            <xsl:when test="$operator eq '&gt;='"   >
                <xsl:sequence select="$bLessThanA or $equal" />
            </xsl:when>
        </xsl:choose>

    </xsl:function>

    <!-- RFC9535 Section 2.3.5.2.2.  Comparisons Equal -->
    <xsl:function name="ajp:comparisonEqual" as="xs:boolean" >
        <xsl:param name="operand1" as="item()?" />
        <xsl:param name="operand2" as="item()?" />

        <xsl:sequence select="( ajp:emptyOrNothing($operand1) and ajp:emptyOrNothing($operand2) )
                               or
                              deep-equal($operand1, $operand2)
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.3.5.2.2.  Comparisons -->
    <xsl:function name="ajp:comparisonLessThan" as="xs:boolean" >
        <xsl:param name="operand1" as="item()?" />
        <xsl:param name="operand2" as="item()?" />

        <xsl:sequence select="not(ajp:emptyOrNothing($operand1))
                               and
                              not(ajp:emptyOrNothing($operand2))
                               and
                              ( ($operand1 lt $operand2)
                                and
                                ( ajp:bothNumeric($operand1, $operand2)
                                   or
                                  ajp:bothString ($operand1, $operand2)
                                )
                              )
                             " />
    </xsl:function>

    <xsl:function name="ajp:emptyOrNothing" as="xs:boolean" >
        <xsl:param name="operand" as="item()?" />

        <xsl:sequence select="($operand instance of node() and $operand is $NOTHING)
                               or
                               empty($operand)
                             " />
    </xsl:function>

    <xsl:function name="ajp:bothNumeric" as="xs:boolean" >
        <xsl:param name="operand1" as="item()?" />
        <xsl:param name="operand2" as="item()?" />

        <xsl:sequence select="$operand1 instance of xs:numeric
                               and
                              $operand2 instance of xs:numeric
                             " />
    </xsl:function>

    <xsl:function name="ajp:bothString" as="xs:boolean" >
        <xsl:param name="operand1" as="item()?" />
        <xsl:param name="operand2" as="item()?" />

        <xsl:sequence select="$operand1 instance of xs:string
                               and
                              $operand2 instance of xs:string
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.4.3.  Well-Typedness of Function Expressions  Point 2 (singular query) -->
    <xsl:function name="ajp:singularQuery" as="item()" >
        <xsl:param name="key"   as="item()"                                                         />
        <xsl:param name="item"  as="item()?"                                                        />
        <xsl:param name="root"  as="item()?"                                                        />

        <xsl:param name="query" as="function(item(), item()?, item()?) as map(xs:string, item()?)*" />

        <xsl:variable name="nodelist" as="map(xs:string, item()?)*"
                      select="$query($key, $item, $root)" />

        <xsl:sequence select="if (count($nodelist) eq 0)
                              then $NOTHING
                              else if (count($nodelist) eq 1)
                              then ($nodelist?*, $NULL)[1]
                              else ajp:error('INT', 4, 'singular query returned more than one item: ' ||
                                                       count($nodelist))
                             " />

    </xsl:function>

    <xsl:function name="ajp:functionExpr" as="item()*">
        <xsl:param name="key"             as="item()"                                           />
        <xsl:param name="item"            as="item()?"                                          />
        <xsl:param name="root"            as="item()?"                                          />

        <xsl:param name="functionName"    as="xs:string"                                        />
        <xsl:param name="arguments"       as="(function(item(), item()?, item()?) as item()*)*" />

        <xsl:variable name="function"     as="map(*)"     select="ajp:getExtFunc($functionName)"    />
        <xsl:variable name="numberOfArgs" as="xs:integer" select="array:size($function?paramTypes)" />

        <xsl:choose>
            <xsl:when test="$numberOfArgs eq 0" >
                <!-- Currently no 0-arg functions but RFC9535 says that there can be -->
                <xsl:sequence select="$function?function()" />
            </xsl:when>
            <xsl:when test="$numberOfArgs eq 1" >
                <xsl:sequence select="$function?function($arguments[1]($key, $item, $root))" />
            </xsl:when>
            <xsl:when test="$numberOfArgs eq 2" >
                <xsl:sequence select="$function?function($arguments[1]($key, $item, $root),
                                                         $arguments[2]($key, $item, $root))" />
            </xsl:when>
            <xsl:when test="$numberOfArgs eq 3" >
                <xsl:sequence select="$function?function($arguments[1]($key, $item, $root),
                                                         $arguments[2]($key, $item, $root),
                                                         $arguments[3]($key, $item, $root))" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="ajp:error('INT', 5, 'bad number of arguments for function ' ||
                                                          $functionName || '()' ||
                                                          ' : '         || $numberOfArgs ||
                                                          '; error should have been detected by function-expr.')" />
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

</xsl:stylesheet>