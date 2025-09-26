<xsl:stylesheet
        xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
        xmlns:xs    = "http://www.w3.org/2001/XMLSchema"

        xmlns:ajp   = "http://xmljacquard.org/ajp"

        version="3.0" >

    <!-- Takes the four hex-digit code for a unicode char and produces that char -->
    <xsl:function name="ajp:hexStringToUnicode" as="xs:string" >
        <xsl:param name="hexString" as="xs:string" />

        <xsl:sequence select="$hexString
                              => ajp:hexStringToInteger()
                              => codepoints-to-string()
                             " />
    </xsl:function>

    <!-- Takes the four hex-digit code for a unicode char and produces the corresponding integer -->
    <xsl:function name="ajp:hexStringToInteger" as="xs:integer" >
        <xsl:param name="hexString" as="xs:string" />

        <xsl:sequence select="$hexString
                              => lower-case()
                              => string-to-codepoints()
                              => reverse()
                              => ajp:hexReverseCodepointsToInteger()
                             " />
    </xsl:function>

    <!-- Takes the four hex-digit code for a unicode char, in reverse order, and produces the corresponding integer -->
    <xsl:function name="ajp:hexReverseCodepointsToInteger" as="xs:integer" >
        <xsl:param name="hexCodepoints" as="xs:integer*" />

        <xsl:sequence select="ajp:hexCodepointToInteger(head($hexCodepoints))
                              +
                              ( if (empty(tail($hexCodepoints)))
                                then 0
                                else 16 * ajp:hexReverseCodepointsToInteger(tail($hexCodepoints))
                              )
                             " />
    </xsl:function>

    <!-- Takes the codepoint for a hex digit and produces the value (0 .. 15) that corresponds -->
    <xsl:function name="ajp:hexCodepointToInteger" as="xs:integer" >
        <xsl:param name="hexCodepoint" as="xs:integer" />

        <xsl:sequence select="if ($hexCodepoint gt $NINE_CODEPOINT)
                              then (10 + $hexCodepoint - $A_CODEPOINT)
                              else (     $hexCodepoint - $ZERO_CODEPOINT)
                             " />
    </xsl:function>

    <xsl:variable name="ZERO_CODEPOINT" as="xs:integer" select="string-to-codepoints('0')" />
    <xsl:variable name="NINE_CODEPOINT" as="xs:integer" select="string-to-codepoints('9')" />
    <xsl:variable name="A_CODEPOINT"    as="xs:integer" select="string-to-codepoints('a')" />

    <!-- https://en.wikipedia.org/wiki/UTF-16#U+D800_to_U+DFFF_(surrogates) -->
    <xsl:function name="ajp:surrogatePairsToUnicode" as="xs:string" >
        <xsl:param name="hexchar" as="element(hexchar)" />

        <xsl:variable name="highInteger" as="xs:integer"
                      select="$hexchar/high-surrogate => ajp:hexStringToInteger()" />

        <xsl:variable name="lowInteger" as="xs:integer"
                      select="$hexchar/low-surrogate  => ajp:hexStringToInteger()" />

        <xsl:sequence select="( ( ($highInteger - $HIGH_START) * $HIGH_SHIFT )
                                +
                                ( ($lowInteger  -  $LOW_START) )
                                +
                                $SURROGATE_HIGH_BIT
                              )
                              => codepoints-to-string()
                             " />
    </xsl:function>

    <!-- https://en.wikipedia.org/wiki/UTF-16#U+D800_to_U+DFFF_(surrogates) -->
    <xsl:variable name="SURROGATE_HIGH_BIT" as="xs:integer" select="65536" />  <!-- 0x10000 -->
    <xsl:variable name="HIGH_SHIFT"         as="xs:integer" select= "1024" />  <!-- 0x400   -->
    <xsl:variable name="HIGH_START"         as="xs:integer" select="55296" />  <!-- 0xD800  -->
    <xsl:variable name="LOW_START"          as="xs:integer" select="56320" />  <!-- 0xDC00  -->

    <xsl:variable name="CH_0001" as="xs:string" select="codepoints-to-string(1)"     />
    <xsl:variable name="CH_FFFD" as="xs:string" select="codepoints-to-string(65533)" />

    <!-- Match chars that are not in the Basic Multilingual Plan (U+0000 to U+FFFF) minus non-XML chars -->
    <xsl:variable name="HIGH_PLANE_REGEX"        as="xs:string"
                  select="concat('[^', $CH_0001, '-', $CH_FFFD, ']')" />

    <xsl:function name="ajp:replaceHigherPlaneChars" as="xs:string" >
        <xsl:param name="s" as="xs:string" />

        <xsl:variable name="stringParts" as="xs:string*" >

            <xsl:analyze-string select="$s" regex="{$HIGH_PLANE_REGEX}" >
                <xsl:matching-substring>
                    <xsl:sequence select="ajp:toSurrogatePair(.)" />
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:sequence select="." />
                </xsl:non-matching-substring>
            </xsl:analyze-string>

        </xsl:variable>

        <xsl:sequence select="string-join($stringParts)" />
    </xsl:function>

    <!-- https://en.wikipedia.org/wiki/UTF-16#U+D800_to_U+DFFF_(surrogates) -->
    <xsl:function name="ajp:toSurrogatePair" as="xs:string" >
        <xsl:param name="s" as="xs:string" />

        <xsl:variable name="adjustedCodePoints" as="xs:integer"
                      select="string-to-codepoints($s) - $SURROGATE_HIGH_BIT" />

        <xsl:variable name="highInteger" as="xs:integer"
                      select="($adjustedCodePoints idiv $HIGH_SHIFT) + $HIGH_START" />

        <xsl:variable name="lowInteger"  as="xs:integer"
                      select="($adjustedCodePoints mod  $HIGH_SHIFT) + $LOW_START"  />

        <xsl:sequence select="concat('\u', ajp:intToHexString($highInteger),
                                     '\u', ajp:intToHexString($lowInteger ))" />
    </xsl:function>

    <xsl:function name="ajp:intToHexString" as="xs:string" >
        <xsl:param name="int" as="xs:integer" />

        <xsl:sequence select="concat(ajp:intToHexChar( $int                 idiv (16*16*16)),
                                     ajp:intToHexChar(($int mod (16*16*16)) idiv (16*16)   ),
                                     ajp:intToHexChar(($int mod (16*16)   ) idiv 16        ),
                                     ajp:intToHexChar( $int mod  16)
                                     )
                             " />
    </xsl:function>

    <xsl:function name="ajp:intToHexChar" as="xs:string" >
        <xsl:param name="int" as="xs:integer" />

        <xsl:if test="($int lt 0) or ($int gt 15)" >
            <xsl:sequence select="ajp:error('INT', 6, 'ajp:intToHexChar() with bad int value ' || $int || '.')" />
        </xsl:if>

        <xsl:sequence select="if ($int lt 10)
                              then codepoints-to-string($int + $ZERO_CODEPOINT)
                              else codepoints-to-string($int + $A_CODEPOINT - 10)" />
    </xsl:function>

    <xsl:variable name="CH_001F" as="xs:string" select="codepoints-to-string(31)"  />
    <xsl:variable name="CH_007F" as="xs:string" select="codepoints-to-string(127)" />
    <xsl:variable name="CH_009F" as="xs:string" select="codepoints-to-string(159)" />

    <xsl:variable name="NON_PRINTING_REGEX"        as="xs:string"
                  select="concat( '[', $CH_0001, '-', $CH_001F, ']' )" />

    <!-- https://en.wikipedia.org/wiki/List_of_Unicode_characters#Control_codes -->
    <xsl:function name="ajp:replaceNonPrintingChars" as="xs:string" >
        <xsl:param name="s" as="xs:string" />

        <xsl:variable name="stringParts" as="xs:string*" >

            <xsl:analyze-string select="$s" regex="{$NON_PRINTING_REGEX}" >
                <xsl:matching-substring>
                    <xsl:sequence select="ajp:charToHexEscape(.)" />
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <xsl:sequence select="." />
                </xsl:non-matching-substring>
            </xsl:analyze-string>

        </xsl:variable>

        <xsl:sequence select="string-join($stringParts)" />
    </xsl:function>

    <xsl:function name="ajp:charToHexEscape" as="xs:string?" >
        <xsl:param name="char" as="xs:string?" />

        <xsl:if test="string-length($char) ne 1" >
            <xsl:sequence select="ajp:error('INT', 9, 'ajp:charToHexEscape(): '        ||
                                                      'must be a single char but was ' || $char || '.')" />
        </xsl:if>

        <xsl:sequence select="concat('\', 'u', ajp:intToHexString(string-to-codepoints($char)))" />
    </xsl:function>

</xsl:stylesheet>