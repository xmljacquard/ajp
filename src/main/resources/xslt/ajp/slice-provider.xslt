<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"

        xmlns:ajp   = "http://xmljacquard.org/ajp"

        version="3.0" >

    <xsl:function name="ajp:sliceProvider" as="map(*)" >
        <xsl:param name="item"   as="array(*)"    />
        <xsl:param name="start"  as="xs:integer?" />
        <xsl:param name="end"    as="xs:integer?" />
        <xsl:param name="step"   as="xs:integer?" />

        <xsl:variable name="length"      as="xs:integer" select="array:size($item)" />

        <!-- RFC9535 Section 2.3.4.2.2: "The default value for step is 1." -->
        <xsl:variable name="normedStep"  as="xs:integer" select="($step,  1)[1]"    />

        <xsl:variable name="normedStart" as="xs:integer"
                      select="ajp:normalizeDefaulted($start, $length, $normedStep, ajp:defaultStart#2)" />
        <xsl:variable name="normedEnd"   as="xs:integer"
                      select="ajp:normalizeDefaulted($end,   $length, $normedStep, ajp:defaultEnd#2)"   />

        <xsl:variable name="lowerUpper" as="array(xs:integer)"
                      select="ajp:lowerUpper($normedStart, $normedEnd, $normedStep, $length)"     />

        <xsl:sequence select="ajp:makeSliceProvider($normedStep, $lowerUpper => ajp:toXPathIndices())" />
    </xsl:function>

    <xsl:function name="ajp:makeSliceProvider" as="map(*)" >
        <xsl:param name="normedStep" as="xs:integer"        />
        <xsl:param name="lowerUpper" as="array(xs:integer)" />

        <xsl:sequence select="if ( ($normedStep eq 0) or ($lowerUpper(1) ge $lowerUpper(2)) )
                              then ajp:emptyProvider()
                              else map {
                                     'end-reached'    : false(),
                                     'get-current'    : ajp:getCurrent#1,
                                     'move-next'      : ajp:moveNextStep#1,

                                     'bounds-reached' : ajp:boundsReached#1,
                                     'current'        : if ($normedStep gt 0) then $lowerUpper(1)
                                                                              else $lowerUpper(2),
                                     'step'           : $normedStep,
                                     'lower'          : $lowerUpper(1),
                                     'upper'          : $lowerUpper(2)
                                  }
                             " />
    </xsl:function>

    <xsl:function name="ajp:getCurrent" as="xs:integer" >
        <xsl:param name="this" as="map(*)" />

        <xsl:sequence select="$this?current" />
    </xsl:function>

    <xsl:function name="ajp:moveNextStep" as="map(*)" >
        <xsl:param name="this"          as="map(*)" />

        <xsl:sequence select="if ($this?bounds-reached($this))
                              then ajp:emptyProvider()
                              else map:put($this, 'current', $this?current + $this?step)
                             " />
    </xsl:function>

    <xsl:function name="ajp:boundsReached" as="xs:boolean" >
        <xsl:param name="this"       as="map(*)"     />

        <xsl:sequence select="let $next := $this?current + $this?step
                              return if ($this?step gt 0)
                                     then $next ge $this?upper
                                     else $next le $this?lower" />
    </xsl:function>

    <xsl:function name="ajp:emptyProvider" as="map(*)" >
        <xsl:sequence select="map {
                                 'end-reached'  : true(),
                                 'get-current'  : ajp:emptyError#1,
                                 'move-next'    : ajp:emptyError#1
                              }
                              " />
    </xsl:function>

    <xsl:function name="ajp:emptyError" as="item()" >
        <xsl:param name="this" as="map(*)" />

        <xsl:sequence select="ajp:error('INT', 8, 'ajp:emptyError(): attempt to retrieve from empty provider.')" />
    </xsl:function>

    <xsl:function name="ajp:toXPathIndices" as="array(xs:integer)" >
        <xsl:param name="zeroBasedIndices" as="array(xs:integer)" />

        <xsl:sequence select="array:for-each($zeroBasedIndices, ajp:addOne#1)" />
    </xsl:function>

    <xsl:function name="ajp:addOne" as="xs:integer" >
        <xsl:param name="value" as="xs:integer" />

        <xsl:sequence select="$value + 1" />
    </xsl:function>

    <xsl:function name="ajp:normalizeDefaulted" as="xs:integer" >
        <xsl:param name="startOrEnd" as="xs:integer?" />
        <xsl:param name="length"     as="xs:integer"  />
        <xsl:param name="step"       as="xs:integer"  />
        <xsl:param name="defaultF"   as="function(xs:integer, xs:integer) as xs:integer" />

        <xsl:variable name="defaulted" as="xs:integer"
                      select="( $startOrEnd, $defaultF($length, $step) ) [1]" />

        <xsl:sequence select="ajp:normalize($defaulted, $length)" />
    </xsl:function>

    <!-- RFC9535 Section 2.3.4.2.2 Table 8: Default Array Slice start and end Values: Column start -->
    <xsl:function name="ajp:defaultStart" as="xs:integer" >
        <xsl:param name="length" as="xs:integer"  />
        <xsl:param name="step"   as="xs:integer"  />

        <xsl:sequence select="if ($step ge 0)
                              then 0
                              else $length - 1
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.3.4.2.2 Table 8: Default Array Slice start and end Values: Column end -->
    <xsl:function name="ajp:defaultEnd" as="xs:integer" >
        <xsl:param name="length" as="xs:integer"  />
        <xsl:param name="step"   as="xs:integer"  />

        <xsl:sequence select="if ($step ge 0)
                              then  $length
                              else -$length - 1
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.3.4.2.2 FUNCTION Bounds -->
    <xsl:function name="ajp:lowerUpper" as="array(xs:integer)" >
        <xsl:param name="start"  as="xs:integer?" />
        <xsl:param name="end"    as="xs:integer?" />
        <xsl:param name="step"   as="xs:integer"  />
        <xsl:param name="length" as="xs:integer"  />

        <xsl:sequence select="if ($step ge 0)
                              then [ ajp:bounds($length, $step, $start),
                                     ajp:bounds($length, $step, $end  )  ]
                              else [ ajp:bounds($length, $step, $end  ),
                                     ajp:bounds($length, $step, $start)  ]
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.3.4.2.2 FUNCTION Bounds -->
    <xsl:function name="ajp:bounds" as="xs:integer" >
        <xsl:param name="length"      as="xs:integer"  />
        <xsl:param name="step"        as="xs:integer"  />
        <xsl:param name="startOrEnd"  as="xs:integer?" />

        <xsl:sequence select="if ($step ge 0)
                              then min( ( max(($startOrEnd,  0)), $length     ) )
                              else min( ( max(($startOrEnd, -1)), $length - 1 ) )
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.3.4.2.2 FUNCTION Normalize(i, len) -->
    <xsl:function name="ajp:normalize" as="xs:integer" >
        <xsl:param name="startOrEnd" as="xs:integer" />
        <xsl:param name="length"     as="xs:integer" />

        <xsl:sequence select="if ($startOrEnd ge 0)
                              then  $startOrEnd
                              else ($startOrEnd + $length)
                             " />
    </xsl:function>

</xsl:stylesheet>