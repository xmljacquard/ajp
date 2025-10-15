<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"
        xmlns:map   = "http://www.w3.org/2005/xpath-functions/map"
        xmlns:array = "http://www.w3.org/2005/xpath-functions/array"

        xmlns:ajp   = "http://xmljacquard.org/ajp"

        version="3.0" >

    <xsl:include href="unicode.xslt" />

    <!-- RFC9535 Section 2.1.2 -->
    <xsl:function name="ajp:applySegments" as="map(xs:string, item()?)*"               >
        <xsl:param name="nodelist"         as="map(xs:string, item()?)*"              />
        <xsl:param name="segments"         as="map(xs:string, array(function(*))+ )*" />
        <xsl:param name="root"             as="item()?"                               />

        <xsl:sequence select="if (empty($segments))
                              then $nodelist
                              else let $resultNodelist := if (ajp:key(head($segments)) eq 'child')
                                                          then ajp:children   ($nodelist, head($segments)?*, $root)
                                                          else ajp:descendants($nodelist, head($segments)?*, $root)
                                   return ajp:applySegments($resultNodelist, tail($segments), $root)
                             " />
    </xsl:function>

    <!-- RFC9535 Section 2.5.2.2.  Descendant Segments / Semantics -->
    <xsl:function name="ajp:descendants" as="map(xs:string, item()?)*"  >
        <xsl:param name="nodelist"       as="map(xs:string, item()?)*" />
        <xsl:param name="selectors"      as="array(function(*))+"      />
        <xsl:param name="root"           as="item()?"                  />

        <xsl:sequence select="ajp:children($nodelist, $selectors, $root)" />

        <xsl:for-each select="$nodelist[ajp:isMapOrArray(.?*)]" >

            <!-- recurse through children -->
            <xsl:sequence select="for $parentPath in ajp:key(.),
                                      $key        in ajp:simpleKeys(.?*),
                                      $childPath  in ajp:path($parentPath, $key),
                                      $childValue in .?*($key)
                                  return ajp:descendants( map { $childPath : $childValue } , $selectors, $root )
                                 " />
        </xsl:for-each>
    </xsl:function>

    <!-- RFC9535 Section 2.5.1.2.  Child Segments / Semantics -->
    <xsl:function name="ajp:children" as="map(xs:string, item()?)*"  >
        <xsl:param name="nodelist"    as="map(xs:string, item()?)*" />
        <xsl:param name="selectors"   as="array( function(*) )+"    />
        <xsl:param name="root"        as="item()?"                  />

        <xsl:sequence select="for $node        in $nodelist [ ajp:isMapOrArray(.?*) ],
                                  $parentPath  in ajp:key($node),
                                  $parentValue in $node?*,
                                  $selector    in $selectors,
                                  $key         in $selector(1)($parentValue),
                                  $childPath   in ajp:path($parentPath, $key)
                              return let $childValue := $parentValue($key)
                                     return map {
                                                $childPath : ( $childValue, $NULL )[1]
                                            } [ $selector(2)($childPath, $childValue, $root) ]
                             " />
    </xsl:function>

    <xsl:variable name="APOS" as="xs:string" select="''''" />

    <xsl:function name="ajp:path" as="xs:string" >
        <xsl:param name="path"    as="xs:string" />
        <xsl:param name="key"     as="item()"    />

        <xsl:sequence select="if ($key instance of xs:string)
                              then concat($path, '[', $APOS, ajp:escape($key), $APOS, ']')
                              else if ($key instance of xs:integer)
                              then concat($path, '[', $key - 1, ']')
                              else ()
                             " />
    </xsl:function>

    <xsl:variable name="BS" as="xs:string" select="codepoints-to-string(8)"  />
    <xsl:variable name="FF" as="xs:string" select="codepoints-to-string(12)" />

    <xsl:function name="ajp:escape" as="xs:string" >
        <xsl:param name="s" as="xs:string" />

        <xsl:sequence select="$s => replace('[\\]',  '\\\\'             )
                                 => replace('&#xA;', concat('\\', 'n'  ))
                                 => replace('&#xD;', concat('\\', 'r'  ))
                                 => replace('&#x9;', concat('\\', 't'  ))
                                 => replace($BS,     concat('\\', 'b'  ))
                                 => replace($FF,     concat('\\', 'f'  ))
                                 => replace($APOS,   concat('\\', $APOS))
                                 => ajp:replaceNonPrintingChars()
                             " />
    </xsl:function>

    <xsl:function name="ajp:expand" as="xs:string?" >
        <xsl:param name="stringLiteral" as="element(string-literal)" />

        <xsl:sequence select="string-join(
                                  for $item in $stringLiteral/node()
                                  return if ($item instance of text())
                                         then $item
                                         else if ($item instance of element(BS))
                                         then $BS
                                         else if ($item instance of element(FF))
                                         then $FF
                                         else if ($item instance of element(hexchar)
                                                  and
                                                  not(exists($item/high-surrogate)))
                                         then ajp:hexStringToUnicode($item)
                                         else if ($item instance of element(hexchar)
                                                  and
                                                  exists($item/high-surrogate))
                                         then ajp:surrogatePairsToUnicode($item)
                                         else ajp:error('INT', 1, 'l:expand() encountered unknown value ' || $item)
                              )
                             " />
    </xsl:function>

    <xsl:function name="ajp:isMapOrArray" as="xs:boolean" >
        <xsl:param name="i" as="item()?" />

        <xsl:sequence select="$i instance of array(*)
                              or
                              $i instance of map(*)
                             " />
    </xsl:function>

    <xsl:function name="ajp:simpleKeys" as="item()*" >
        <xsl:param name="item" as="item()?" />

        <xsl:sequence select="if ($item instance of map(*))
                              then map:keys($item)
                              else if ($item instance of array(*))
                              then (1 to array:size($item))
                              else ()
                             "/>
    </xsl:function>

    <xsl:function name="ajp:key" as="item()?" >
        <xsl:param name="item" as="map(*)?" />

        <xsl:if test="count(map:keys($item)) gt 1" >
            <xsl:sequence select="ajp:error('INT', 7, 'ajp:key(): retrieved more than one key.')" />
        </xsl:if>

        <xsl:sequence select="map:keys($item)"/>
    </xsl:function>

</xsl:stylesheet>
