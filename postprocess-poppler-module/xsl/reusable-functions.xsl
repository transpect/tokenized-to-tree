<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ppp="http://transpect.io/postprocess-poppler"
  exclude-result-prefixes="xs ppp"
  version="2.0">
  
  <xsl:function name="ppp:regexify">
    <xsl:param name="input" as="xs:string"/>
    <xsl:value-of select="replace(
                            replace(
                              replace(
                                replace(
                                  $input, 
                                  '([.?*+\{\}\[\]\(\)])', 
                                  '\\$1'
                                ),
                                '-',
                                '[-&#xad;&#x2010;&#x2011;]'
                              ),
                              '([&#x2012;-&#x2015;])',
                              '&#x2008;?$1&#x2008;?'
                            ),
                            '&#x2019;',
                            '[&#x2019;'']'
                          )"/>
  </xsl:function>
  

</xsl:stylesheet>