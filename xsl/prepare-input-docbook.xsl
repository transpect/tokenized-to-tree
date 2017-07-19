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
  
  <xsl:import href="prepare-input.xsl"/>
  
  <!-- This is not merely for DocBook input but for peculiar input that contains certain links
    and document variables (from Klett’s Voktool). At some point the DocBook-specific parts and the 
    Voktool-related stuff need to be further separated. --> 

  <!-- Words (anchors before tokens, to be precise) should be marked immutable with respect to
    analysis if there is a pending action (ignore, register) or if a register action has been
    successfully carried out. If registering was successful, the action will be set to 'keep'. 
    People have to manually check the 'none' action to re-enable analysis for a word that 
    has been registered. 
  -->
  <xsl:function name="ttt:immutable-token-action-for-anchor" as="xs:string?">
    <xsl:param name="a" as="element(dbk:anchor)"/>
    <!-- remove an extra _2 etc at the id (created by docx2hub)
      so that there is only token_GENERATED-ID_TIMESTAMP -->
    <xsl:variable name="id" as="xs:string" select="ttt:normalize-anchor-id($a/@xml:id)"/>
    <xsl:variable name="kwd" as="element(dbk:keyword)*" 
                    select="root($a)/*/dbk:info/dbk:keywordset
                              [@role eq 'docVars']
                              /dbk:keyword
                                (: matches(@role, $id) covers both 'new_token_…' and 'token_…' IDs :)
                                [matches(@role, $id) and matches(., 'action=(ignore|register|keep)')]
                                [not(
                                  starts-with(@role, concat('new_', $id)) 
                                  and 
                                  matches(., 'action=none')
                                )]"/>
    <xsl:if test="exists($kwd)">
      <xsl:variable name="single-kwd" as="element(dbk:keyword)"
        select="(
                  $kwd[starts-with(@role, 'new_')][matches(., 'action=')],
                  $kwd[starts-with(@role, 'token_')][matches(., 'action=')]
                )[1]"/>
      <xsl:sequence select="replace($single-kwd, '^.*action=(ignore|register|keep).*$', '$1')"/>
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="ttt:normalize-anchor-id" as="xs:string">
    <xsl:param name="id" as="xs:string"/>
    <!-- remove an extra _2 etc at the id (created by docx2hub)
      so that there is only token_GENERATED-ID_TIMESTAMP -->
    <xsl:sequence select="replace($id, '^(token_(.+?)_\d{4}-\d\d-\d\dT\d\d_\d\d_\d\d).*?(_end)?$', '$1$2')"/>
  </xsl:function>

  <!-- discard the results of the previous pass (will have to refine it later: the 'ignore' information should stay there) -->
  <xsl:template match="dbk:anchor[starts-with(@xml:id, 'token_')]" mode="ttt:add-ids" priority="3"/>

  <xsl:template match="dbk:link[preceding-sibling::*[1]/self::dbk:anchor[starts-with(@xml:id, 'token_')]]" mode="ttt:add-ids_" priority="3">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  <!-- instead of the template above, we allow some wild manual editing where remaining anchors of deleted text may 
    get between a link’s proper anchors -->
  <xsl:template match="dbk:link[exists(ttt:surrounding-anchors(.))]" mode="ttt:add-ids" priority="3">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:function name="ttt:surrounding-anchors" as="element(dbk:anchor)*">
    <xsl:param name="link" as="element(dbk:link)"/>
    <xsl:sequence select="$link/preceding-sibling::dbk:anchor[@role = 'start']
                                                             [concat(@xml:id, '_end') = $link/following-sibling::dbk:anchor[@role= 'end']/@xml:id]"/>
  </xsl:function>
  
  <!-- ignorable means: the associated word should be ignored --> 
  <xsl:template match="dbk:anchor[ttt:immutable-token-action-for-anchor(.)]" mode="ttt:add-ids" priority="4">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <!-- remove additional sequence number that was added by docx2hub -->
      <xsl:attribute name="xml:id" select="ttt:normalize-anchor-id(@xml:id)"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="dbk:link[preceding-sibling::*[1]/self::dbk:anchor[ttt:immutable-token-action-for-anchor(.)]]" mode="ttt:add-ids" priority="4">
    <xsl:copy>
      <!-- register or ignore -->
      <xsl:attribute name="ttt:action" select="ttt:immutable-token-action-for-anchor(preceding-sibling::*[1])"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- this should be moved to an adaptation -->
  <xsl:template match="dbk:link[exists(ttt:surrounding-anchors(.))]
                               [every $a in (ttt:surrounding-anchors(.)) 
                                satisfies (not(ttt:immutable-token-action-for-anchor($a) = 'register'))
                               ]
                         //dbk:phrase/@*[starts-with(name(), 'css:text-decoration-')]" mode="ttt:add-ids" priority="3"/>

  <!-- discard the statistics table – should be moved to adaptations, too -->
  <xsl:template match="dbk:informaltable[(.//dbk:entry)[1] = 'Wort im Text']" mode="ttt:add-ids" />
  <xsl:template match="dbk:para[not(normalize-space(.))][preceding-sibling::*[1]/self::dbk:informaltable[(.//dbk:entry)[1] = 'Wort im Text']]" 
    mode="ttt:add-ids" priority="3"/>

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
                       | dbk:superscript[matches(., '^\s*\d+\s*$')]
                       | dbk:subscript[matches(., '^\s*\d+\s*$')]
                       | *[matches(@xml:lang, $ttt:ignore-language-regex)]
                       | *[matches(key('ttt:style-by-role', @role)/@native-name, '~ignore|bildbeschr', 'i')]
                       | *[matches(., '^\s*\(\(.+?\)\)\s*$')]" mode="ttt:discard">
    <xsl:call-template name="ttt:mark-as-placeholder"/>
  </xsl:template>
  

</xsl:stylesheet>