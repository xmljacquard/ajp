<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cs="http://nineml.com/ns/coffeesacks"
                xmlns:ixml="http://invisiblexml.org/NS"
                xmlns:jwL="https://github.com/johnlumley"
                xmlns:math="http://www.w3.org/2005/xpath-functions/math"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                exclude-result-prefixes="xs math cs jwL"
                version="4.0">
         <!--DO NOT EDIT - 
            generated from file:/D:/Saxonica/InvisibleXML/Mine/dist/coffeeSacks.4.xsl at 2025-09-06T13:51:13.2599804+01:00 by EE 12.4-->

   <!--
      A CoffeeSacks interface for the jwiXML processor 
   -->
   
   <!--Defaulting function: cs:load-grammar-->
   <xsl:function name="cs:load-grammar"
                 as="function(xs:string) as item()"
                 visibility="public">
      <xsl:param name="uri" as="xs:string"/>
      <xsl:variable name="options" as="map(*)" select="map {}"/>
      <xsl:sequence select="cs:load-grammar($uri,$options)"/>
   </xsl:function>

   <xsl:function name="cs:load-grammar" as="function(xs:string, map(*)) as item()" visibility="public">
      <xsl:param name="uri" as="xs:string"/>
      <xsl:param name="options" as="map(*)"/>

      <xsl:variable name="grammarSource" select="unparsed-text($uri)"/>
      <xsl:variable name="grammar"
                    as="item()"
                    select="jwL:compileGrammar($grammarSource, $options)"/>
      <xsl:sequence select="function ($input as xs:string) as item()
                            {
                                let    $result := jwL:parse( $grammar, $input, map {'justOne': false()} )
                                return $result?tree
                            }"/>
   </xsl:function>
   <!--Defaulting function: cs:make-parser-->

   <xsl:function xmlns:err="http://www.w3.org/2005/xqt-errors"
                 xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                 name="cs:make-parser"
                 as="function(xs:string) as item()">
      <xsl:param name="input" as="item()"/>
      <xsl:variable name="options" as="map(*)" select="map {}"/>
      <xsl:sequence select="cs:make-parser($input,$options)"/>
   </xsl:function>

   <xsl:function name="cs:make-parser" as="function(xs:string) as item()">
      <xsl:param name="input" as="item()"/>
      <xsl:param name="options" as="map(*)"/>

      <xsl:sequence select="if ($input instance of node() or $input instance of xs:anyAtomicType)
                            then let    $grammar := jwL:compileGrammar(string($input), $options)
                                 return function ($input2 as xs:string) as item()
                                     {
                                         let    $result := jwL:parse($grammar, $input2, map { 'justOne': false() })
                                         return $result?tree
                                     }
                            else if ($input instance of xs:anyURI)
                            then cs:load-grammar($input, $options)
                            else error(xs:QName('ixml:G000'),
                                       'Cannot treat type of $input as a valid IXML grammar')"/>
   </xsl:function>
</xsl:stylesheet>
