<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="xs ttt"
  version="2.0">
  
  <xsl:variable name="with-ids" as="document-node(element(*))" select="collection()[1]"/>
  <xsl:variable name="ttt-paras" as="document-node(element(ttt:paras))" select="collection()[2]"/>
  
  <xsl:template match="node() | @*" mode="#default in-patched">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  <xsl:key name="by-id" match="*" use="@xml:id"/>
  <!-- $ttt-paras is the document with patched para-like elements, where patching
          means: the text analysis results have been patched into the elements -->
  <xsl:template mode="#default"
    match="*[@xml:id][exists(key('by-id', @xml:id, $ttt-paras)[not(@ttt:role = 'placeholder')])]">
    <xsl:apply-templates select="key('by-id', @xml:id, $ttt-paras)" mode="in-patched"/>
  </xsl:template>
  <xsl:template match="@xml:lang[. eq 'NOLANG'] | @xml:id[starts-with(., 'NOID_')]"
    mode="#default in-patched"/>
  <!-- Placeholders in the analyzed text document will be taken from the original doc: -->
  <xsl:template match="*[@ttt:role = 'placeholder']" mode="in-patched">
    <xsl:apply-templates select="key('by-id', @xml:id, $with-ids)" mode="#default"/>
  </xsl:template>
  <xsl:template match="ttt:pi | ttt:comment | ttt:ignorable-text" mode="#default">
    <xsl:copy-of select="node()"/>
  </xsl:template>
  <xsl:template match="ttt:normalized-space" mode="#default in-patched" priority="5">
    <xsl:value-of select="@original"/>
  </xsl:template>
  <xsl:template match="ttt:generated" mode="in-patched" priority="5">
    <xsl:apply-templates select=".//ttt:*" mode="#current"/>
  </xsl:template>
  <xsl:template match="ttt:space" mode="in-patched">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  <xsl:template match="ttt:token" mode="in-patched">
    <phrase xmlns="http://docbook.org/ns/docbook" role="{name()}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </phrase>
  </xsl:template>
  <xsl:template match="@ttt:*" mode="in-patched"/>
</xsl:stylesheet>
