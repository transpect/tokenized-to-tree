<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ppp="http://transpect.io/postprocess-poppler"
  exclude-result-prefixes="xs ppp"
  version="2.0">
  
  <xsl:function name="ppp:regexify">
    <xsl:param name="input" as="xs:string"/>
    <xsl:value-of select="ppp:normalize-unicode(
                            replace(
                              replace(
                                replace(
                                  replace(
                                    $input, 
                                    '([|\\.?*+\{\}\[\]\(\)])', 
                                    '\\$1'
                                  ),
                                  '-',
                                  '[-&#xad;&#x2010;&#x2011;]'
                                ),
                                '(\\\\|[/&#x2012;-&#x2015;])',
                                '&#x2008;?$1&#x2008;?&#x200b;?'
                              ),
                              '&#x2019;',
                              '[&#x2019;&#x02BC;'']'
                            )
                          )"/>
  </xsl:function>
  
  <xsl:function name="ppp:normalize-unicode" as="xs:string">
    <xsl:param name="regex" as="xs:string"/>
    <!-- will normalize U+B9 to 1, etc. -->
    <xsl:variable name="prelim" as="xs:string*">
      <xsl:analyze-string select="$regex" regex="[&#xb9;&#xb2;]">
        <xsl:matching-substring>
          <xsl:sequence select="concat('[', ., normalize-unicode(., 'NFKD'), ']')"/>
        </xsl:matching-substring>
        <xsl:non-matching-substring>
          <xsl:sequence select="."/>
        </xsl:non-matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string-join($prelim, '')"/>
  </xsl:function>

</xsl:stylesheet>