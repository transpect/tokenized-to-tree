<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:dbk="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs dbk ttt"
  version="2.0">
  
  <xsl:variable name="dbk:map-from-higher-unicode-plane-regex" select="'[&#x1F000;-&#x1F9FF;]'" as="xs:string"/>
  <!-- Move this range to E200–EBFF (somewhat arbitrary) -->
  <xsl:variable name="dbk:map-to-higher-unicode-plane-regex" select="'[&#xE200;-&#xEBFF;]'" as="xs:string"/>
  <xsl:variable name="dbk:map-from-higher-unicode-plane-shift" select="69120" as="xs:integer"/>
  
  <xsl:function name="dbk:map-from-higher-unicode-plane" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:variable name="seq" as="xs:string+">
      <xsl:analyze-string select="$string" regex="{$dbk:map-from-higher-unicode-plane-regex}">
        <xsl:matching-substring>
          <xsl:sequence select="codepoints-to-string(string-to-codepoints(.) - $dbk:map-from-higher-unicode-plane-shift)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($seq, '')"/>
  </xsl:function>
  
  <xsl:function name="dbk:map-to-higher-unicode-plane" as="xs:string">
    <xsl:param name="string" as="xs:string"/>
    <xsl:variable name="seq" as="xs:string+">
      <xsl:analyze-string select="$string" regex="{$dbk:map-to-higher-unicode-plane-regex}">
        <xsl:matching-substring>
          <xsl:sequence select="codepoints-to-string(string-to-codepoints(.) + $dbk:map-from-higher-unicode-plane-shift)"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($seq, '')"/>
  </xsl:function>

</xsl:stylesheet>