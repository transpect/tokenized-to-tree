<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  exclude-result-prefixes="xs" version="2.0">
  
  <xsl:template match="node() | @*" mode="find-matching-lines try-coverage side-by-side">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <!-- Mode: find-matching-lines -->
  
  <xsl:template match="/*" mode="find-matching-lines">
    <xsl:next-match>
      <xsl:with-param name="lines" tunnel="yes" as="element(line)*">
        <!-- collection()[2] is the prostprocessed pdftoxml document with line/@regex -->
        <xsl:apply-templates select="collection()[2]//line[@regex]" mode="#current"/>
      </xsl:with-param>
    </xsl:next-match>
  </xsl:template>
  
  <xsl:template match="ttt:para" mode="find-matching-lines">
    <xsl:param name="lines" as="element(line)*" tunnel="yes"/>
    <xsl:variable name="matching-lines" as="document-node()">
      <xsl:document>
        <xsl:sequence select="$lines[matches(current()/*/@ttt:text, @regex)]"/>
      </xsl:document>
    </xsl:variable>
    <!-- To do: It there are footnotes on the pages, the poppler output needs to be preprocessed:
      The footnote areas have to be merged and the lines have to be renumbered so that
      they start at 1 on each page. -->
    <xsl:variable name="contiguous-lines" as="element(line-group)*">
      <xsl:for-each-group select="$matching-lines/line" group-adjacent="ttt:probably-adjacent-line(.)">
        <line-group c="{count(current-group())}" cont="{current-grouping-key()}">
          <xsl:sequence select="current-group()"/>
        </line-group>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="single-lines-only" as="xs:boolean" 
      select="every $g in $contiguous-lines satisfies ($g/@c = '1')"/>
    <xsl:variable name="implausible-line-groups" as="element(line-group)*"
      select="$contiguous-lines[@cont = 'false'][not($single-lines-only)]"/>
    <xsl:copy>
      <xsl:copy-of select="@*, *"/>
      <xsl:sequence select="$contiguous-lines[@cont = 'true']/line 
                            union 
                            $contiguous-lines[$single-lines-only][@cont = 'false']/line"/>
      <xsl:if test="exists($implausible-line-groups)">
        <implausible-lines>
          <xsl:sequence select="$implausible-line-groups/line"/>
        </implausible-lines>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="ttt:probably-adjacent-line" as="xs:boolean">
    <xsl:param name="line" as="element(line)"/>
    <xsl:variable name="fs" as="element(line)?" select="$line/following-sibling::line[1]"/>
    <xsl:variable name="ps" as="element(line)?" select="$line/preceding-sibling::line[1]"/>
    <xsl:choose>
      <xsl:when test="$ps/@p = $line/@p">
        <xsl:sequence select="number($ps/@n) = number($line/@n) - 1"/>
      </xsl:when>
      <xsl:when test="$fs/@p = $line/@p">
        <xsl:sequence select="number($fs/@n) = number($line/@n) + 1"/>
      </xsl:when>
      <xsl:when test="number($ps/@p) = number($line/@p) - 1">
        <xsl:sequence select="number($line/@n) = 1"/>
      </xsl:when>
      <xsl:when test="number($fs/@p) = number($line/@p) + 1">
        <xsl:sequence select="number($fs/@n) = 1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="line" mode="find-matching-lines">
    <xsl:copy>
      <xsl:attribute name="xml:id" select="generate-id()"/>
      <xsl:attribute name="p" select="../@number"/>
      <xsl:attribute name="n"
        select="index-of(for $l in ../line
                         return generate-id($l), 
                         generate-id())"/>
      <xsl:copy-of select="@*"/>
      <xsl:if test="*[last()]/self::hyphen">
        <xsl:attribute name="hyphenated" select="'true'"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  
  <!-- Mode: try-coverage -->
  
  <xsl:template match="ttt:para" mode="try-coverage">
    <xsl:copy>
      <xsl:copy-of select="@*, node()"/>
      <xsl:variable name="ordered-results" as="document-node()">
        <xsl:document>
          <xsl:sequence select="ttt:try-coverage(*[1]/@ttt:text, line)"/>
        </xsl:document>
      </xsl:variable>
      <coverage>
        <xsl:if test="count($ordered-results/match) ne count(line[@regex])">
          <xsl:attribute name="diff" select="count(line[@regex]) - count($ordered-results/match)"/>
        </xsl:if>
        <xsl:apply-templates select="$ordered-results" mode="#current"/>
      </coverage>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="match | non-match | space" mode="try-coverage">
    <xsl:copy>
      <xsl:variable name="up-to-here" select="sum(for $p in preceding-sibling::* return string-length($p))"/>
      <xsl:attribute name="start" select="$up-to-here"/>
      <xsl:attribute name="end" select="$up-to-here + string-length(.)"/>
      <xsl:copy-of select="@p | @n | @skip | @hyphenated"/>
      <xsl:value-of select="."/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:function name="ttt:try-coverage" as="element(*)*"><!-- match, space or non-match -->
    <xsl:param name="uncovered-string" as="xs:string"/>
    <xsl:param name="line-candidates" as="element(line)*"/>
    <xsl:choose>
      <xsl:when test="string-length($uncovered-string) = 0"/>
      <xsl:when test="matches($uncovered-string, '^[\s\p{Zs}]+$', 's')">
        <space>
          <xsl:attribute name="xml:space" select="'preserve'"/>
          <xsl:value-of select="$uncovered-string"/>
        </space>
      </xsl:when>
      <xsl:when test="empty($line-candidates)">
        <non-match>
          <xsl:attribute name="xml:space" select="'preserve'"/>
          <xsl:value-of select="$uncovered-string"/>
        </non-match>
      </xsl:when>
      <xsl:when test="matches($uncovered-string, concat('^\s*', $line-candidates[1]/@regex), 's')">
        <xsl:if test="matches($uncovered-string, '^\s+', 's')">
          <space>
            <xsl:attribute name="xml:space" select="'preserve'"/>
            <xsl:value-of select="replace($uncovered-string, '^(\s+).*$', '$1', 's')"/>
          </space>
        </xsl:if>
        <match>
          <xsl:attribute name="xml:space" select="'preserve'"/>
          <xsl:copy-of select="$line-candidates[1]/(@p, @n, @skip, @hyphenated)"/>
          <xsl:value-of select="replace($uncovered-string, concat('^\s*', $line-candidates[1]/@regex, '.*$'), '$1', 's')"/>
        </match>
        <xsl:variable name="space" as="xs:string" 
          select="replace($uncovered-string, concat('^\s*', $line-candidates[1]/@regex, '.*$'), '$2', 's')"/>
        <xsl:if test="string-length($space) gt 0">
          <space>
            <xsl:attribute name="xml:space" select="'preserve'"/>
            <xsl:value-of select="$space"/>
          </space>
        </xsl:if>
        <xsl:variable name="non-match" as="xs:string"
          select="replace($uncovered-string, concat('^\s*', $line-candidates[1]/@regex), '', 's')"/>
        <xsl:sequence select="ttt:try-coverage($non-match, $line-candidates[position() gt 1])"/>        
      </xsl:when>
      <xsl:otherwise>
        <xsl:analyze-string select="$uncovered-string" regex="{$line-candidates[1]/@regex}">
          <xsl:matching-substring>
            <match>
              <xsl:copy-of select="$line-candidates[1]/(@p, @n, @skip, @hyphenated)"/>
              <xsl:attribute name="xml:space" select="'preserve'"/>
              <xsl:value-of select="."/>
            </match>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:sequence select="ttt:try-coverage(., $line-candidates[position() gt 1])"/>
            <!--<non-match>
              <xsl:attribute name="xml:space" select="'preserve'"/>
            </non-match>-->
          </xsl:non-matching-substring>
        </xsl:analyze-string>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>


  <!-- Mode: side-by-side -->

  <xsl:template match="ttt:para/line | ttt:para/implausible-lines" mode="side-by-side"/>
  
  <xsl:template match="ttt:para/coverage/match" mode="side-by-side">
    <ttt:t>
      <xsl:copy-of select="@*, node()"/>
    </ttt:t>
  </xsl:template>

  <xsl:template match="ttt:para/coverage/non-match" mode="side-by-side">
    <ttt:t problem="non-match">
      <xsl:copy-of select="@*, node()"/>
    </ttt:t>
  </xsl:template>
  
  <xsl:template match="ttt:para/coverage/space" mode="side-by-side"/>
  
  <xsl:template match="ttt:para/coverage" mode="side-by-side">
    <ttt:tokens>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </ttt:tokens>
  </xsl:template>


</xsl:stylesheet>