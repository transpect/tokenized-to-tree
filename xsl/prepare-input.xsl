<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:dbk="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs dbk ttt"
  version="2.0">
  
  <xsl:import href="ttt-common.xsl"/>

  <xsl:variable name="content-to-be-processed" as="item()*" select="/"/>

  <!-- identity template -->
  
  <xsl:template match="@* | node()" mode="ttt:add-ids ttt:identity ttt:discard">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:key name="ttt:style-by-role" match="css:rule" use="@name"/>

  <xsl:template name="ttt:linebreak-element-to-nl">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:text>&#xa;</xsl:text>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template name="ttt:tab-element-to-tab">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:text>&#9;</xsl:text>
    </xsl:copy>
  </xsl:template>

  <xsl:template name="ttt:mark-as-placeholder">
    <xsl:copy>
      <xsl:copy-of select="@xml:id | @ttt:length"/>
      <xsl:attribute name="ttt:role" select="'placeholder'"/>
    </xsl:copy>
  </xsl:template>


  <!-- Collateral: Optionally map popular non-BMP characters (mostly emojis) into the PUA --> 
  
  <xsl:template match="text()[$ttt:do-map-higher-unicode-planes]
                             [matches(., $ttt:map-from-higher-unicode-plane-regex)]" mode="ttt:add-ids">
    <xsl:value-of select="ttt:map-from-higher-unicode-plane(.)"/>
  </xsl:template>
  
  
  <!-- This is the essential add-ids template: --> 
  <xsl:template match="*[name() = $ttt:content-element-names]" mode="ttt:add-ids" priority="2">
    <xsl:copy>
      <xsl:attribute name="xml:lang" 
        select="(
                  'NOLANG', 
                  ancestor-or-self::*/(
                                        key('css:rule', @*[name() = $css:rule-selection-attribute-names]),
                                        .
                                      )/@xml:lang
                )[last()]"/>
      <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
      <!-- Both newly created attributes will be overwritten with already existing 
           xml:id and xml:lang attributes if present.
      
          We also have to consider the case that a paragraph has an ignorable language and all phrases
          within have a non-ignorable language. What happens then is that the whole paragraph will be
          ignored. In order to make it subject to analysis nonetheless, will use the phrases’ language
          here instead. This only works if all text within the paragraph has a different, non-ignorable language.
      --> 
      <xsl:variable name="processed" as="item()*">
        <xsl:apply-templates select="@*, node()" mode="#current"/>
      </xsl:variable>
      <xsl:variable name="common-language" select="if (every $node in $processed[not(self::attribute())][normalize-space()] satisfies (exists($node/@xml:lang)))
                                                   then distinct-values($processed[not(self::attribute())][normalize-space()]/@xml:lang)
                                                   else @xml:lang"
                                           as="xs:string*"/>
      <xsl:if test="count($common-language) = 1">
        <xsl:attribute name="xml:lang" select="$common-language"/>
      </xsl:if>
      <xsl:sequence select="$processed"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[name() = $ttt:placeholder-element-names]" mode="ttt:add-ids" priority="2">
    <xsl:copy>
      <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="processing-instruction()[ancestor::*]" mode="ttt:add-ids" priority="1">
    <ttt:pi>
      <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
      <xsl:copy/>
    </ttt:pi>
  </xsl:template>

  <xsl:template match="comment()" mode="ttt:add-ids">
    <ttt:comment>
      <xsl:attribute name="xml:id" select="concat('NOID_', generate-id())"/>
      <xsl:copy/>
    </ttt:comment>
  </xsl:template>


  <xsl:template match="*[name() = ('annotation', 'tabs', 'footnote')][not(@xml:id)]" mode="ttt:add-ids">
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
  

  <xsl:template match="/*" mode="ttt:discard" priority="2">
    <ttt:paras>
      <xsl:apply-templates select="$content-to-be-processed//*[ttt:is-para-like(.)]" mode="#current"/>
    </ttt:paras>
  </xsl:template>
  
  <xsl:template match="*[ttt:is-para-like(.)]" mode="ttt:count-text" priority="2">
    <xsl:text>&#xa;  </xsl:text>
    <ttt:para>
      <xsl:copy>
        <xsl:attribute name="ttt:text" separator="">
          <xsl:apply-templates mode="#current"/>
        </xsl:attribute>
        <xsl:call-template name="ttt:start-end">
          <xsl:with-param name="para-context" select="." tunnel="yes"/>
        </xsl:call-template>
        <xsl:apply-templates select="@*, node()" mode="#current">
          <xsl:with-param name="para-context" select="." tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:copy>
    </ttt:para>
  </xsl:template>
  
  <xsl:template match="text()[matches(., '^\s+$')][name(..) = $ttt:whitespace-ignoring-element-names]" mode="ttt:discard"/>

  <xsl:template match="*[parent::*][not(name() = $ttt:content-element-names)]" mode="ttt:discard">
    <xsl:call-template name="ttt:mark-as-placeholder"/>
  </xsl:template>

  <xsl:template match="ttt:ignorable-text" mode="ttt:discard">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:variable name="ttt:whitespace-ignoring-element-names" as="xs:string*" select="()"/>
  
  <xsl:template match="*[ttt:is-para-like(.)][matches(., '^\s*$')]" mode="ttt:count-text" priority="3"/>
    
  <xsl:template name="ttt:start-end">
    <xsl:param name="para-context" as="element(*)?" tunnel="yes"/>
    <!-- should call a counting template recursively, but the performance impact of adding 
      text node lengths over and over again will be minimal for typical documents. -->
    <xsl:variable name="offset" as="xs:integer"
      select="string-length(
                string-join(
                  $para-context//text()[. &lt;&lt; current()],
                  ''
                )
              )"/>
    <!-- zero-based indexes! -->
    <xsl:attribute name="ttt:start" select="$offset"/>
    <xsl:attribute name="ttt:end" select="$offset + string-length(.)"/>
  </xsl:template>
  
  <xsl:template match="@* | node()" mode="ttt:count-text">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="*" mode="ttt:count-text">
    <xsl:copy>
      <xsl:call-template name="ttt:start-end"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>