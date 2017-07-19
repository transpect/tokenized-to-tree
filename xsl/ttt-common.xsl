<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  exclude-result-prefixes="xs ttt"
  version="2.0">

  <xsl:param name="map-higher-unicode-planes" as="xs:string" select="'yes'"/>
  <xsl:variable name="ttt:do-map-higher-unicode-planes" as="xs:boolean" select="$map-higher-unicode-planes = 'yes'"/>

  <!-- This default for DocBook should be overwritten for other XML vocabularies. 
    Maybe all DocBook defaults should move to prepare-input-docbook.xsl -->
  <xsl:variable name="ttt:content-element-names" as="xs:string+"
    select="('para', 'phrase', 'emphasis', 'xref', 'indexterm', 'link', 'simpara', 'tab', 'br', 'title', 'subscript', 'superscript')"/>
  
  <xsl:variable name="ttt:placeholder-element-names" as="xs:string+"
    select="('annotation', 'tabs', 'footnote')"/>
  
  <xsl:key name="css:rule" match="css:rule" use="@name"/>
  
  <xsl:variable name="css:rule-selection-attribute-names" 
    select="if (/*/@css:rule-selection-attribute)
    then tokenize(/*/@css:rule-selection-attribute, '\s+')
    else ()"
    as="xs:string*"/>
    
  <xsl:variable name="ttt:ignore-language-regex" select="'^de'" as="xs:string"/>

  <xsl:variable name="ttt:ignore-href-regex-x" as="xs:string" 
    select="'https?://[^/]*?
             (
                 example\.com
               | acme\.com
             )'" />
  
  <xsl:function name="ttt:is-para-like" as="xs:boolean">
    <xsl:param name="element" as="element(*)"/>
    <xsl:sequence select="name($element) = ('para', 'simpara', 'title', 'caption')"/>
  </xsl:function>
  
  
  
  <xsl:variable name="ttt:map-from-higher-unicode-plane-regex" select="'[&#x1F000;-&#x1F9FF;]'" as="xs:string"/>
  <!-- Move this range to E200–EBFF (somewhat arbitrary) -->
  <xsl:variable name="ttt:map-to-higher-unicode-plane-regex" select="'[&#xE200;-&#xEBFF;]'" as="xs:string"/>
  <xsl:variable name="ttt:map-from-higher-unicode-plane-shift" select="69120" as="xs:integer"/>
  <xsl:variable name="ttt:map-complete-string-to-higher-unicode-plane-regex" 
    select="concat('^', $ttt:map-to-higher-unicode-plane-regex, '+$')" as="xs:string"/>
  <xsl:variable name="ttt:complete-string-non-word-regex" select="'^[\W-[\p{S}]+$'" as="xs:string"/>
  
  <xsl:function name="ttt:map-from-higher-unicode-plane" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:variable name="seq" as="xs:string+">
      <xsl:analyze-string select="$string" regex="{$ttt:map-from-higher-unicode-plane-regex}">
        <xsl:matching-substring>
          <xsl:sequence select="codepoints-to-string(string-to-codepoints(.) - $ttt:map-from-higher-unicode-plane-shift)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($seq, '')"/>
  </xsl:function>
  
  <xsl:function name="ttt:map-to-higher-unicode-plane" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:variable name="seq" as="xs:string+">
      <xsl:analyze-string select="$string" regex="{$ttt:map-to-higher-unicode-plane-regex}">
        <xsl:matching-substring>
          <xsl:sequence select="codepoints-to-string(string-to-codepoints(.) + $ttt:map-from-higher-unicode-plane-shift)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($seq, '')"/>
  </xsl:function>
</xsl:stylesheet>