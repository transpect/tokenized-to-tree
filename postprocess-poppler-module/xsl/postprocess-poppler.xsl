<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ppp="http://transpect.io/postprocess-poppler"
  exclude-result-prefixes="xs ppp"
  version="2.0">

  <xsl:import href="reusable-functions.xsl"/>

  <xsl:param name="odd-page-left" as="xs:string?"/>
  <xsl:param name="odd-page-width" as="xs:string?"/>
  <xsl:param name="odd-page-top" as="xs:string?"/>
  <xsl:param name="odd-page-height" as="xs:string?"/>
  <xsl:param name="even-page-left" as="xs:string?"/>
  <xsl:param name="even-page-width" as="xs:string?"/>
  <xsl:param name="even-page-top" as="xs:string?"/>
  <xsl:param name="even-page-height" as="xs:string?"/>
  <xsl:param name="space-threshold-upright" select="'2'" as="xs:string"/>
  <xsl:param name="space-threshold-italic" select="'2'" as="xs:string"/>

  <xsl:variable name="opl" as="xs:integer?" select="ppp:pt-int($odd-page-left, ())"/>
  <xsl:variable name="opw" as="xs:integer?" select="ppp:pt-int($odd-page-width, ())"/>
  <xsl:variable name="opt" as="xs:integer?" select="ppp:pt-int($odd-page-top, ())"/>
  <xsl:variable name="oph" as="xs:integer?" select="ppp:pt-int($odd-page-height, ())"/>
  <xsl:variable name="epl" as="xs:integer?" select="ppp:pt-int($even-page-left, $opl)"/>
  <xsl:variable name="epw" as="xs:integer?" select="ppp:pt-int($even-page-width, $opw)"/>
  <xsl:variable name="ept" as="xs:integer?" select="ppp:pt-int($even-page-top, $opt)"/>
  <xsl:variable name="eph" as="xs:integer?" select="ppp:pt-int($even-page-height, $oph)"/>
  <xsl:variable name="space-threshold-upright_int" as="xs:integer" select="xs:integer($space-threshold-upright)"/>
  <xsl:variable name="space-threshold-italic_int" as="xs:integer" select="xs:integer($space-threshold-italic)"/>
  
  <xsl:output indent="yes"/>
  
  <xsl:function name="ppp:pt-int" as="xs:integer?">
    <xsl:param name="string-val" as="xs:string?"/>
    <xsl:param name="default" as="xs:integer?"/>
    <xsl:sequence select="(for $n in $string-val return xs:integer($n), $default)[1]"/>
  </xsl:function>
  
  <xsl:template match="/" mode="#default">
    <xsl:variable name="remove-uninteresting" as="document-node(element(pdf2xml))">
      <xsl:document><xsl:apply-templates select="/" mode="remove-uninteresting"/></xsl:document>
    </xsl:variable>
    <xsl:variable name="lines" as="document-node(element(pdf2xml))">
      <xsl:document><xsl:apply-templates select="$remove-uninteresting" mode="lines"/></xsl:document>
    </xsl:variable>
    <xsl:variable name="spaces" as="document-node(element(pdf2xml))">
      <xsl:document><xsl:apply-templates select="$lines" mode="spaces"/></xsl:document>
    </xsl:variable>
    <xsl:apply-templates select="$spaces" mode="regex"/>
  </xsl:template>
  
  <xsl:template match="@* | node()" mode="lines regex remove-uninteresting spaces">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="text[@width = '0']" mode="remove-uninteresting" priority="2"/>
  
  <xsl:template mode="remove-uninteresting" priority="1"
    match="page[number(@number) mod 2 = 1]/text[number(@width) + number(@left) lt $opl]" />
  
  <xsl:template mode="remove-uninteresting" priority="1.1"
    match="page[number(@number) mod 2 = 1]/text[number(@left) gt ($opl + $opw)]"/>
  
  <xsl:template mode="remove-uninteresting" priority="1.2"
    match="page[number(@number) mod 2 = 0]/text[number(@left) gt ($epl + $epw)]"/>
  
  <xsl:template mode="remove-uninteresting" priority="1.3"
    match="page[number(@number) mod 2 = 0]/text[number(@width) + number(@left) lt $epl]" />
  
  <xsl:template mode="remove-uninteresting" priority="1.4"
    match="page[number(@number) mod 2 = 1]/text[number(@top) + number(@height) lt $opt]" />

  <xsl:template mode="remove-uninteresting" priority="1.5"
    match="page[number(@number) mod 2 = 1]/text[number(@top) gt ($opt + $oph)]" />
  
  <xsl:template mode="remove-uninteresting" priority="1.6"
    match="page[number(@number) mod 2 = 0]/text[number(@top) + number(@height) lt $ept]" />

  <xsl:template mode="remove-uninteresting" priority="1.7"
    match="page[number(@number) mod 2 = 0]/text[number(@top) gt ($ept + $eph)]" />
  
  <xsl:template match="page" mode="lines">
    <xsl:copy>
      <xsl:apply-templates select="@*, fontspec" mode="#current"/>
      <xsl:for-each-group select="text" 
        group-starting-with="*[for $p in preceding-sibling::text[1] 
                               return number(@top) gt (number($p/@top) + number($p/@height))]">
        <line>
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </line>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="text[not(i)][for $p in preceding-sibling::text[1] 
                                    return number(@left) gt (number($p/@left) + number($p/@width) + $space-threshold-upright_int)]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width) + 1)"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="text[not(i)][for $p in preceding-sibling::text[1] 
                                    return number(@left) - (number($p/@left) + number($p/@width)) = $space-threshold-upright_int]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width))"/>
      <xsl:with-param name="maybe" select="true()"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="text[i][for $p in preceding-sibling::text[1] 
                               return number(@left) gt (number($p/@left) + number($p/@width) + $space-threshold-italic_int)]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width) + 1)"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="text[i][for $p in preceding-sibling::text[1] 
                               return number(@left) - (number($p/@left) + number($p/@width) ) = $space-threshold-italic_int]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width))"/>
      <xsl:with-param name="maybe" select="true()"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>

  <xsl:template name="ppp:space">
    <xsl:param name="width" as="xs:double"/>
    <xsl:param name="maybe" as="xs:boolean" select="false()"/>
    <space width="{$width}">
      <xsl:attribute name="xml:space" select="'preserve'"/>
      <xsl:if test="matches(., '^\p{Po}')">
        <xsl:attribute name="before-punctuation" select="'true'"/>
      </xsl:if>
      <xsl:if test="$maybe">
        <xsl:attribute name="maybe" select="'true'"/>
      </xsl:if>
      <xsl:text xml:space="preserve"> </xsl:text>
    </space>
  </xsl:template>

  <xsl:template match="text[last()]
                           [matches(string-join((preceding::text[1], .), ''), '\w-$')]
                           [matches(string-join(following::text[position() = (1,2)], ''), '^\p{Ll}{2}')
                            or 
                            matches(string-join(following::text[position() = (1,2)], ''), '^\p{Lu}{2}')]
                         //text()[. is (ancestor::text[1]//text())[last()]]" mode="spaces">
    <xsl:value-of select="replace(., '-$', '')"/>
  </xsl:template>

  <!-- Using this function in both surrounding templates slowed down conversion significantly with Saxon PE 9.6.0.7 -->
  <xsl:function name="ppp:may-contain-hyphenation" as="xs:boolean">
    <xsl:param name="text" as="element(text)"/>
    <xsl:sequence select="exists(
                            $text[. is ($text/../text)[last()]]
                                 [matches(string-join(($text/preceding::text[1], .), ''), '\w-$')]
                                 [matches(string-join($text/following::text[position() = (1,2)], ''), '^\p{Ll}{2}')
                                  or 
                                  matches(string-join(following::text[position() = (1,2)], ''), '^\p{Lu}{2}')
                                 ]
                          )"/>
  </xsl:function>

  <xsl:template match="text[last()]
                           [matches(string-join((preceding::text[1], .), ''), '\w-$')]
                           [matches(string-join(following::text[position() = (1,2)], ''), '^\p{Ll}{2}')
                            or 
                            matches(string-join(following::text[position() = (1,2)], ''), '^\p{Lu}{2}')
                           ]" mode="spaces">
    <xsl:next-match/>
    <hyphen>-</hyphen>
  </xsl:template>
  
  <xsl:template match="line[text]" mode="regex">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="regex" separator="">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="*" mode="#current"/>
      </xsl:attribute>
      <xsl:copy-of select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="text" mode="regex">
    <xsl:if test="matches(., '^…') and not(preceding-sibling::*[1]/self::space)">
    <!-- hack (U+2008 in source XML is too narrow and won’t be turned into a space).
      Question: does it appear in front of other chars, too? 
      Maybe move this hack to adaptations and create a named template hook here. -->
      <xsl:text>&#x2008;+</xsl:text>
    </xsl:if>
    <xsl:value-of select="ppp:regexify(.)"/>
    <xsl:if test=". is ../*[last()]">
      <xsl:choose>
        <xsl:when test="matches(., '\p{Pd}$')">
          <xsl:value-of select="')([\s\p{Zs}&#x200B;]*|$)'"/>    
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="')([\s\p{Zs}&#x200B;]+|$)'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="space" mode="regex">
    <xsl:text>[\s\p{Zs}&#x200B;]</xsl:text>
    <xsl:choose>
      <xsl:when test="@before-punctuation | @maybe">
        <xsl:text>*</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>+</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="hyphen" mode="regex">
    <xsl:text>-?)</xsl:text>
  </xsl:template>


</xsl:stylesheet>