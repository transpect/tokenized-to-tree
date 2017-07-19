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
  
  <xsl:variable name="ttt:content-element-names" as="xs:string+"
    select="('p', 's', 'w', 'hi', 'seg', 'index', 'link', 'ab', 'head', 'app', 'lem', 'subst', 'add')"/>

  <xsl:variable name="ttt:whitespace-ignoring-element-names" as="xs:string*"
    select="('app', 'subst')"/>

  <xsl:variable name="ttt:placeholder-element-names" as="xs:string+"
    select="('app', 'note', 'ttt:pi', 'ttt:comment', 'rdg', 'lb', 'pb', 'del')"/>
  
  <!--<xsl:template match="tei:lb[not(node())]" mode="ttt:discard">
    <xsl:next-match/>
    <xsl:call-template name="ttt:linebreak-element-to-nl"/>
  </xsl:template>-->
    
  <xsl:function name="ttt:is-para-like" as="xs:boolean">
    <xsl:param name="element" as="element(*)"/>
    <xsl:sequence select="name($element) = ('p', 'head')"/>
  </xsl:function>
  
</xsl:stylesheet>