<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ppp="http://transpect.io/postprocess-poppler"
  exclude-result-prefixes="xs ppp"
  version="2.0">

  <xsl:import href="reusable-functions.xsl"/>

  <xsl:param name="first-page" as="xs:string?"/>
  <xsl:param name="last-page" as="xs:string?"/>
  <xsl:param name="odd-page-left" as="xs:string?"/>
  <xsl:param name="odd-page-width" as="xs:string?"/>
  <xsl:param name="odd-page-top" as="xs:string?"/>
  <xsl:param name="odd-page-height" as="xs:string?"/>
  <xsl:param name="even-page-left" as="xs:string?"/>
  <xsl:param name="even-page-width" as="xs:string?"/>
  <xsl:param name="even-page-top" as="xs:string?"/>
  <xsl:param name="even-page-height" as="xs:string?"/>
  <xsl:param name="space-threshold-upright" as="xs:string"/>
  <xsl:param name="space-threshold-italic" as="xs:string"/>
  <xsl:param name="fixed-grid-line-height" as="xs:string?"/>
  <xsl:param name="exclude-fonts" as="xs:string?"/>

  <xsl:variable name="ef" as="xs:integer*" select="for $t in tokenize($exclude-fonts, '\s+') return xs:integer($t)"/>
  <xsl:variable name="fp" as="xs:double?" select="ppp:pt-double($first-page, ())"/>
  <xsl:variable name="lp" as="xs:double?" select="ppp:pt-double($last-page, ())"/>
  <xsl:variable name="opl" as="xs:double?" select="ppp:pt-double($odd-page-left, ())"/>
  <xsl:variable name="opw" as="xs:double?" select="ppp:pt-double($odd-page-width, ())"/>
  <xsl:variable name="opt" as="xs:double?" select="ppp:pt-double($odd-page-top, ())"/>
  <xsl:variable name="oph" as="xs:double?" select="ppp:pt-double($odd-page-height, ())"/>
  <xsl:variable name="epl" as="xs:double?" select="ppp:pt-double($even-page-left, $opl)"/>
  <xsl:variable name="epw" as="xs:double?" select="ppp:pt-double($even-page-width, $opw)"/>
  <xsl:variable name="ept" as="xs:double?" select="ppp:pt-double($even-page-top, $opt)"/>
  <xsl:variable name="eph" as="xs:double?" select="ppp:pt-double($even-page-height, $oph)"/>
  <xsl:variable name="space-threshold-upright_double" as="xs:double" select="xs:double($space-threshold-upright)"/>
  <xsl:variable name="space-threshold-italic_double" as="xs:double" select="xs:double($space-threshold-italic)"/>
  <xsl:variable name="glh" as="xs:double?" select="for $f in $fixed-grid-line-height[normalize-space()]
                                                   return number($f)"/>
  
  <xsl:output indent="yes"/>

  <xsl:function name="ppp:pt-int" as="xs:integer?">
    <xsl:param name="string-val" as="xs:string?"/>
    <xsl:param name="default" as="xs:integer?"/>
    <xsl:sequence select="(for $n in $string-val[normalize-space()] return xs:integer($n), $default)[1]"/>
  </xsl:function>

  <xsl:function name="ppp:pt-double" as="xs:double?">
    <xsl:param name="string-val" as="xs:string?"/>
    <xsl:param name="default" as="xs:double?"/>
    <xsl:sequence select="(for $n in $string-val[normalize-space()] return xs:double($n), $default)[1]"/>
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
  
  <xsl:template match="text[@width &lt; '0.01']" mode="remove-uninteresting" priority="2"/>

  <xsl:template match="text[@font = $ef]" mode="remove-uninteresting" priority="2.1"/>
  
  <xsl:template mode="remove-uninteresting" priority="2"
    match="page[exists($fp)][number(@number) &lt; $fp]">
  </xsl:template>
  
  <xsl:template mode="remove-uninteresting" priority="2"
    match="page[exists($lp)][number(@number) > $lp]"/>
  
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
          <xsl:if test="exists($glh[. gt 0])">
            <!-- Measuring against the previous line: -->
            <!--<xsl:variable name="skip" as="xs:double" 
              select="(
                        number(@top) 
                        - 
                        (
                          (for $p in preceding-sibling::text[1] return (number($p/@top))),
                          $opt (: we don’t consider even/odd here, but we should :)
                        )[1]
                        + 1 (: heuristical correction :)
                      ) 
                      idiv $glh
                      - 1"/>-->
            <!-- Measuring against the absolute grid: -->
            <xsl:variable name="skip" as="xs:double"
              select="ppp:gridpos-double(@top, $glh, $opt) - ppp:gridpos-double(preceding-sibling::text[1]/@top, $glh, $opt) - 1"/>
            <!--<xsl:attribute name="debugskipA" select="ppp:gridpos-double(@top, $glh, $opt)"/>
            <xsl:attribute name="debugskipB" select="ppp:gridpos-double(preceding-sibling::text[1]/@top, $glh, $opt)"/>
            <xsl:attribute name="debugskipC" select="$skip"/>
            <xsl:attribute name="debugskipD" select="$glh"/>
            <xsl:attribute name="debugskipE" select="$opt"/>-->
            <xsl:if test="$skip &gt; 0">
              <xsl:attribute name="skip" select="xs:integer($skip)"/>
            </xsl:if>
          </xsl:if>
          <xsl:apply-templates select="current-group()" mode="#current"/>
        </line>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

  <xsl:function name="ppp:gridpos-int" as="xs:integer">
    <xsl:param name="top" as="xs:integer?"/>
    <xsl:param name="line-height" as="xs:double"/>
    <xsl:param name="page-top" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="empty($top)">
        <xsl:sequence select="0"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="($top - $page-top) idiv $line-height + 1"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="ppp:gridpos-double" as="xs:double">
    <xsl:param name="top" as="xs:double?"/>
    <xsl:param name="line-height" as="xs:double"/>
    <xsl:param name="page-top" as="xs:double"/>
    <xsl:choose>
      <xsl:when test="empty($top)">
        <xsl:sequence select="0"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="floor(($top - $page-top) div $line-height + 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="text[not(i)][starts-with(., '\')]" 
                mode="spaces" priority="2.5">
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="0"/>
      <xsl:with-param name="maybe" select="true()"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>

  <!--<xsl:template match="text[not(i)][. = ' ']" mode="spaces" priority="5">
    <xsl:copy>
<!-\-      <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>-\->
<!-\-      <xsl:value-of select="'[', string(number(@left) - (number($p/@left) + number($p/@width))), ']'"/>-\->
      <xsl:value-of select="'TEST'"/>
    </xsl:copy>
  </xsl:template>-->

  <xsl:template match="text[not(i)][for $p in preceding-sibling::text[1] 
                                    return number(@left) gt (number($p/@left) + number($p/@width) + $space-threshold-upright_double)]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width) + 1)"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="text[not(i)][for $p in preceding-sibling::text[1] 
                                    return number(@left) - (number($p/@left) + number($p/@width)) = $space-threshold-upright_double]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width))"/>
      <xsl:with-param name="maybe" select="true()"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="text[i][for $p in preceding-sibling::text[1] 
                               return number(@left) gt (number($p/@left) + number($p/@width) + $space-threshold-italic_double)]" 
                mode="spaces" priority="2">
    <xsl:variable name="p" select="preceding-sibling::text[1]" as="element(text)"/>
    <xsl:call-template name="ppp:space">
      <xsl:with-param name="width" select="number(@left) - (number($p/@left) + number($p/@width) + 1)"/>
    </xsl:call-template>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:template match="text[i][for $p in preceding-sibling::text[1] 
                               return number(@left) - (number($p/@left) + number($p/@width) ) = $space-threshold-italic_double]" 
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
  
  <xsl:function name="ppp:replace-for-regex" as="xs:string">
    <xsl:param name="_string" as="xs:string"/>
    <xsl:sequence select="replace(
                            replace(
                              replace(
                                replace(
                                  replace(
                                    replace(
                                      replace(
                                        replace(
                                          $_string, 
                                          '\\\.\\\.\\\.', 
                                          '(\\.\\.\\.|…)'
                                        ),
                                        '¯I',
                                        'Ī'
                                      ),
                                      '¯e',
                                      'ē'
                                    ),
                                    '¯o',
                                    'ō'
                                  ),
                                  '¯u',
                                  'ū'
                                ),
                                '¯a',
                                'ā'
                              ),
                              '([duz]\\\.)([aBhRT]\\\.)',
                              '$1[\\s\\p{Zs}​]*$2'
                            ),
                            '([Iiz]\\\.|AK)([dB]\\\.|8)',
                            '$1[\\s\\p{Zs}​]*$2'
                          )"/>
  </xsl:function>
  
  <xsl:template match="line[text]" mode="regex">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:variable name="proto-regex" as="node()+">
        <xsl:text>(</xsl:text>
        <xsl:apply-templates select="*" mode="#current"/>
      </xsl:variable>
      <xsl:attribute name="regex" select="ppp:replace-for-regex(string-join($proto-regex, ''))"/>
      <xsl:copy-of select="node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!--
    Sometimes the poppler output has separate text elements for space and non space text fragments, like:
    
    <text top="205.011100" left="343.361680" width="12.827826" height="9.857100" font="5"><i>der</i></text>
    <text top="211.508000" left="356.189506" width="0.001020" height="1.300000" font="2"> </text>
    <text top="205.011100" left="358.915660" width="33.219972" height="9.857100" font="5"><i>Fremde.</i></text>
    <text top="211.508000" left="392.135632" width="0.001020" height="1.300000" font="2"> </text>
    
    in that case mode spaces helps us by generating the needed space regex part.
    
    Sometimes the poppler output has mixed text elements for text fragments that include whitespace, like:
    
    <text top="266.769600" left="53.858000" width="289.253664" height="10.135200" font="0">seiner Entfernung von sechshundert Kilometern geduldig bereit war</text>
    
    in that case we have to escape the whitespace in order to match the ttt:text later on.
  -->
  <xsl:template match="text" mode="regex" priority="1">
    <xsl:variable name="_next_match">
      <xsl:next-match/>
    </xsl:variable>
    <xsl:value-of select="replace($_next_match, '\s+', '[\\s\\p{Zs}&#x200B;]+')"/>
  </xsl:template>
  
  <!-- sometimes latex adds spaces, remove -->
  <xsl:template match="text" mode="regex" priority="0.9">
    <xsl:variable name="_next_match">
      <xsl:next-match/>
    </xsl:variable>
    <xsl:value-of select="replace($_next_match, '\[\s+', '[[\\s\\p{Zs}&#x200B;]*')"/>
  </xsl:template>
  
  <xsl:template match="text" mode="regex" priority="0.8">
    <xsl:variable name="_next_match">
      <xsl:next-match/>
    </xsl:variable>
    <xsl:value-of select="replace($_next_match, '\s+\]', '[\\s\\p{Zs}&#x200B;]*]')"/>
  </xsl:template>
  
  <xsl:template match="text" mode="regex">
    <xsl:if test="matches(., '^…') and not(preceding-sibling::*[1]/self::space)">
    <!-- hack (U+2008 in source XML is too narrow and won’t be turned into a space).
      Question: does it appear in front of other chars, too? 
      Maybe move this hack to adaptations and create a named template hook here. -->
      <xsl:text>&#x2008;*</xsl:text>
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
    <xsl:text>[-&#x2010;]?)</xsl:text>
  </xsl:template>


</xsl:stylesheet>