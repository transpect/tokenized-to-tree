<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:css="http://www.w3.org/1996/css" 
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  exclude-result-prefixes="xs ttt"
  version="2.0">

  <xsl:import href="ttt-common.xsl"/>

  <xsl:template match="@* | *" mode="ttt:patch-token-results ttt:eliminate-duplicate-start-end-elts ttt:pull-up-delims">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- collateral -->
  <xsl:template match="text()[$ttt:do-map-higher-unicode-planes]
                             [matches(., $ttt:map-to-higher-unicode-plane-regex)]" mode="ttt:eliminate-duplicate-start-end-elts">
    <xsl:value-of select="ttt:map-to-higher-unicode-plane(.)"/>
  </xsl:template>
  
  <xsl:template match="@ttt:text[$ttt:do-map-higher-unicode-planes]
                                [matches(., $ttt:map-to-higher-unicode-plane-regex)]" mode="ttt:eliminate-duplicate-start-end-elts">
    <xsl:attribute name="{name()}" select="ttt:map-to-higher-unicode-plane(.)"/>
  </xsl:template>

  <xsl:template match="ttt:tokens" mode="ttt:patch-token-results"/>

  <xsl:function name="ttt:text-node-for-pos" as="text()?">
    <xsl:param name="para" as="element(*)"/><!-- the para from the text, augmented with ttt:start and ttt:end attributes -->
    <xsl:param name="pos" as="xs:integer"/>
    <!-- parent may only be empty if there are incorrect start/end positions in the input: --> 
    <xsl:variable name="parent" select="($para/descendant-or-self::*[@ttt:end &gt;= $pos]
                                                                    [@ttt:start &lt;= $pos])[last()]" as="element(*)?"/>
    <xsl:variable name="prelim-preceding" select="$para/descendant-or-self::*[@ttt:end &lt;= $pos]" as="element(*)*"/>
    <xsl:variable name="preceding" select="$prelim-preceding[xs:double(@ttt:end) = max($prelim-preceding/@ttt:end)]" as="element(*)*"/>
    <!--<xsl:if test="$para/@ttt:text = 'Dori: Vale, genial. ¡Gracias!' and ($pos = 10)">
      <xsl:message select="'PREC: ',$preceding/following::text()[1][string-length(.) + $preceding[last()]/@ttt:end &gt;= $pos]"/>
    </xsl:if>-->
    <xsl:sequence select="(($parent//text())[1], 
                           ($preceding/following::text()[1][exists(ancestor::* intersect $para)][string-length(.) + $preceding[last()]/@ttt:end &gt;= $pos])
                          )[last()]"/>
  </xsl:function>

  <xsl:template match="ttt:para[ttt:tokens]/*[1]" mode="ttt:patch-token-results">
    <xsl:variable name="start-text-nodes" as="text()*"
      select="for $i in ../ttt:tokens//ttt:t/@start return ttt:text-node-for-pos(., xs:integer($i))"/>
    <xsl:variable name="end-text-nodes" as="text()*"
      select="for $i in ../ttt:tokens//ttt:t/@end return ttt:text-node-for-pos(., xs:integer($i))"/>
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
<!--      <xsl:variable name="context" select="." as="element(*)"/>
      <start-nodes>
        <xsl:for-each select="../ttt:tokens//ttt:t/@start">
          <n i="{.}">
            <xsl:value-of select="ttt:text-node-for-pos($context, xs:integer(.))"/>
          </n>
        </xsl:for-each>
      </start-nodes>
      <end-nodes>
        <xsl:for-each select="../ttt:tokens//ttt:t/@end">
          <n i="{.}">
            <xsl:value-of select="ttt:text-node-for-pos($context, xs:integer(.))"/>
          </n>
        </xsl:for-each>
      </end-nodes>-->
      <xsl:apply-templates mode="#current">
        <xsl:with-param name="start-nodes" select="$start-text-nodes" tunnel="yes"/>
        <xsl:with-param name="end-nodes" select="$end-text-nodes" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="ttt:para/*[1]//text()" mode="ttt:patch-token-results">
    <xsl:param name="start-nodes" as="text()*" tunnel="yes"/>
    <xsl:param name="end-nodes" as="text()*" tunnel="yes"/>
    <xsl:choose>
      <!-- only patch the results if there is no ignore or pending register action --> 
      <xsl:when test="some $s in ($start-nodes, $end-nodes) satisfies (. is $s)
                      and not(ancestor::*[@ttt:action])">
        <xsl:variable name="offset" select="xs:integer((../@ttt:start | preceding-sibling::*[1]/@ttt:end)[last()])" as="xs:integer"/>
        <!-- current() is a ttt:para/*[1] text node. The positional comparisons run against ttt:para/*[2]/ttt:t -->
        <xsl:variable name="token-start-atts" as="attribute(start)*"
          select="ancestor::ttt:para/ttt:tokens//ttt:t[@start &gt;= $offset and @start &lt;= $offset + string-length(current())]/@start"/>
        <xsl:variable name="token-end-atts" as="attribute(end)*"
          select="ancestor::ttt:para/ttt:tokens//ttt:t[@end &gt;= $offset and @end &lt;= $offset + string-length(current())]/@end"/>
        <xsl:variable name="context" as="text()" select="."/>
        <xsl:variable name="atts" as="attribute()*">
          <xsl:perform-sort select="$token-start-atts union $token-end-atts">
            <xsl:sort select="." data-type="number"/>
          </xsl:perform-sort>
        </xsl:variable>
        <xsl:variable name="positions" select="for $a in $atts return xs:integer($a - $offset)" as="xs:integer*"/>
        <xsl:value-of select="substring($context, 1, ($positions[1], string-length($context))[1])"/>
        <xsl:for-each select="$atts"><!-- @start or @end position attributes that are within the current text node’s 
                                          positional range --> 
          <xsl:apply-templates select="." mode="#current"/><!-- the folliwing template transform them  to ttt:start or 
                                                                ttt:end milestone elements --> 
          <xsl:value-of select="for $pos in position() (: the position of the @start/@end attribute that has just created a milestone :)
                                return substring(
                                  $context, 
                                  $positions[$pos] + 1, 
                                  ( $positions[$pos + 1], string-length($context) )[1] - $positions[$pos]
                                )"/>  
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="ttt:t/@start | ttt:t/@end" mode="ttt:patch-token-results">
    <!-- ttt:start and ttt:end elements are created by this stylesheet -->
    <xsl:element name="ttt:{name()}">
      <xsl:attribute name="token-id" select="generate-id(..)"/>
      <xsl:copy-of select="../@*"/>
    </xsl:element>
  </xsl:template>

  <!-- eliminate embarrassing duplicates, see xpl -->
  <xsl:template match="ttt:end[ancestor::ttt:para//ttt:end[@token-id = current()/@token-id][. &lt;&lt; current()]]" 
    mode="ttt:eliminate-duplicate-start-end-elts"/>

  <xsl:template match="ttt:start[ancestor::ttt:para//ttt:start[@token-id = current()/@token-id][. &gt;&gt; current()]]" 
    mode="ttt:eliminate-duplicate-start-end-elts"/>
  


  <xsl:template match="ttt:para/*" mode="ttt:pull-up-delims">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="context" select="." as="element(*)"/>
      <xsl:for-each-group select="descendant::node()[not(node())]" group-starting-with="*[@token-id]">
        <!-- [not(self::*[@token-id])] should avoid empty projections due rather arbitrary
        placement of ttt:end / ttt:start within or after a text-encloding element: -->
        <xsl:variable name="ancestor-or-self" as="node()*"
          select="current-group()[not(self::*[@token-id])]/ancestor-or-self::node()" />
        <xsl:variable name="prelim" as="node()*">
          <xsl:apply-templates select="$context/node()" mode="ttt:pull-up-delims_restrict">
            <xsl:with-param name="restricted-to" select="$ancestor-or-self"/>
          </xsl:apply-templates>    
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="self::ttt:start">
            <ttt:token xmlns="http://www.le-tex.de/namespace/tokenized-to-tree">
              <xsl:apply-templates select="@*" mode="#current"/>
              <xsl:sequence select="$prelim"/>
            </ttt:token>
          </xsl:when>
          <xsl:when test="$prelim">
            <ttt:space xmlns="http://www.le-tex.de/namespace/tokenized-to-tree">
              <xsl:sequence select="$prelim"/>
            </ttt:space>
          </xsl:when>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()" mode="ttt:pull-up-delims_restrict">
    <xsl:param name="restricted-to" as="node()*"/>
    <xsl:if test="some $r in $restricted-to satisfies (. is $r)">
      <xsl:copy>
        <xsl:apply-templates select="@*" mode="ttt:pull-up-delims"/>
        <xsl:apply-templates mode="#current">
          <xsl:with-param name="restricted-to" select="$restricted-to"/>
        </xsl:apply-templates>
      </xsl:copy>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ttt:start | ttt:end | @ttt:text | @token-id" 
    mode="ttt:pull-up-delims_restrict ttt:pull-up-delims">
    <!-- @ttt:start | @ttt:end will be removed in re-insert-placeholders.xsl -->
  </xsl:template>

  <xsl:template match="ttt:para" mode="ttt:pull-up-delims">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  

</xsl:stylesheet>