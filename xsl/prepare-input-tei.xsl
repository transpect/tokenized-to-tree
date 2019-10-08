<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:tei="http://www.tei-c.org/ns/1.0"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:dbk="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs dbk ttt"
  version="2.0">
  
  <xsl:import href="prepare-input.xsl"/>
  
  <xsl:variable name="ttt:original-document" as="document-node(element(tei:TEI))?" select="collection()[2]">
    <!-- only for ttt:discard -->
  </xsl:variable>
  
  <xsl:variable name="ttt:content-element-names" as="xs:string+"
    select="('p', 's', 'w', 'hi', 'seg', 'index', 'link', 'ab', 'head', 'app', 'lem', 'subst', 'add', 'rs', 'wrapper')"/>

  <xsl:variable name="ttt:whitespace-ignoring-element-names" as="xs:string*"
    select="('app', 'subst')"/>

  <xsl:variable name="ttt:placeholder-element-names" as="xs:string+"
    select="('app', 'note', 'ttt:pi', 'ttt:comment', 'rdg', 'lb', 'pb', 'del', 'lem')"/>
  
  <xsl:function name="ttt:is-placeholder-element" as="xs:boolean">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:choose>
      <xsl:when test="$elt/self::tei:lem[every $n in node()[normalize-space() or self::*]
                                         satisfies ttt:is-para-like($n)]">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="local-name($elt) = $ttt:placeholder-element-names"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!--<xsl:template match="tei:lb[not(node())]" mode="ttt:discard">
    <xsl:next-match/>
    <xsl:call-template name="ttt:linebreak-element-to-nl"/>
  </xsl:template>-->
    
  <xsl:function name="ttt:is-para-like" as="xs:boolean">
    <xsl:param name="element" as="node()"/>
    <xsl:choose>
      <xsl:when test="$element[self::*]/parent::tei:wrapper">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="name($element) = ('p', 'head', 'wrapper')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
    <xsl:template match="app/text()[not(normalize-space())]" mode="ttt:add-ids">
    <ttt:ignorable-text>
      <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
      <xsl:copy/>
    </ttt:ignorable-text>
  </xsl:template>
  
  <xsl:variable name="ttt:zero-width-joiner-or-soft-hyphen-regex" as="xs:string" select="'[&#xad;&#x200c;]+'"/>
  
  <xsl:template match="*[ttt:is-para-like(.)]//text()[matches(., $ttt:zero-width-joiner-or-soft-hyphen-regex)]" mode="ttt:add-ids">
    <xsl:analyze-string select="." regex="{$ttt:zero-width-joiner-or-soft-hyphen-regex}">
      <xsl:matching-substring>
        <xsl:variable name="prelim" as="element(ttt:ignorable-text)">
          <ttt:ignorable-text>
            <xsl:value-of select="."/>
          </ttt:ignorable-text>  
        </xsl:variable>
        <xsl:for-each select="$prelim">
          <xsl:copy>
            <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
            <xsl:copy-of select="node()"/>
          </xsl:copy>
        </xsl:for-each>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  

  
</xsl:stylesheet>