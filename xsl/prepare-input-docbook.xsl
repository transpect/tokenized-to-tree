<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:dbk="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs dbk ttt css mc xlink"
  version="2.0">
  
  <xsl:import href="prepare-input.xsl"/>
  
  <xsl:template match="*[name() = $ttt:placeholder-element-names][not(@xml:id)]" mode="ttt:add-ids">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="dbk:footnote/dbk:para[1]/dbk:phrase[@role = 'hub:identifier']" mode="ttt:add-ids" priority="3"/>
  
  <xsl:template match="dbk:footnote/dbk:para[1]/text()[preceding::text()[1]/parent::dbk:phrase/@role = 'hub:identifier']" mode="ttt:add-ids">
    <xsl:value-of select="replace(., '^\s+', '')"/>
  </xsl:template>
  

  <!-- collateral: insert whitespace within a br or a tab (otherwise, no space between words) -->
  <xsl:template match="dbk:br[not(node())]" mode="ttt:discard">
    <xsl:call-template name="ttt:linebreak-element-to-nl"/>
  </xsl:template>
  <xsl:template match="dbk:tab[not(node())]" mode="ttt:discard">
    <xsl:call-template name="ttt:tab-element-to-tab"/>
  </xsl:template>
  

  <!-- ttt:role='placeholder' for content that should be pulled from the original document unchanged.
    The link here and its $ttt:ignore-href-regex-x is just an example. 
    The predicate should invoke a default selection function that may be overridden. -->
  <xsl:template match="  dbk:link[matches(@xlink:href, $ttt:ignore-href-regex-x, 'x')]
                       | *[parent::*][not(name() = $ttt:content-element-names)]
                       | *[@role = 'hub:foreign']
                       (:
                       | dbk:superscript[matches(., '^\s*\d+\s*$')]
                       | dbk:subscript[matches(., '^\s*\d+\s*$')]
                       don’t exclude them by default
                       :)
                       | *[matches(@xml:lang, $ttt:ignore-language-regex)]
                       | *[matches(key('ttt:style-by-role', @role)/@native-name, '~ignore|bildbeschr', 'i')]
                       | *[matches(., '^\s*\(\(.+?\)\)\s*$')]" mode="ttt:discard">
    <xsl:call-template name="ttt:mark-as-placeholder"/>
  </xsl:template>
  
  
  <xsl:variable name="ttt:space-like-or-soft-hyphen-regex" as="xs:string" select="'(\s{2,}|\s*[\p{Zs}-[ ]][\p{Zs}\s]*|&#xad;)'"/>
  
  <xsl:template match="*[ttt:is-para-like(.)]//text()[matches(., $ttt:space-like-or-soft-hyphen-regex)]" mode="ttt:add-ids">
    <xsl:analyze-string select="." regex="{$ttt:space-like-or-soft-hyphen-regex}">
      <xsl:matching-substring>
        <xsl:choose>
          <xsl:when test=". = '&#xad;'">
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
          </xsl:when>
          <xsl:otherwise>
            <ttt:normalized-space original="{.}">
              <xsl:text xml:space="preserve"> </xsl:text>
            </ttt:normalized-space>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="."/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:template>
  

</xsl:stylesheet>