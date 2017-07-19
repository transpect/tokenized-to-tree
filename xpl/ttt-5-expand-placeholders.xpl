<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:tr="http://transpect.io"
  type="ttt:merge-results"
  name="merge-results">
  
  <p:input port="source" primary="false">
    <p:documentation>A Hub 1.1 document where every para-like element bears an ID. This ID must be matched by the ttt:para child
      elements in the document on the patched-paras port. Also, the elements that are marked with ttt:role="placeholder" in the
      other document must have a matching ID here. Otherwise they cannot be merged.</p:documentation>
  </p:input>
  <p:input port="patched-paras" primary="true">
    <p:documentation>A ttt:paras document as created by ttt:process-paras (text analysis results patched into the individual Hub
      para-like elements). Below ttt:paras are the payload document elements. They must all be equipped with xml:ids so that we
      are able to merge them back into the source document.</p:documentation>
  </p:input>
  <p:input port="stylesheet">
    <p:inline>
      <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0" exclude-result-prefixes="#all">
        <xsl:template match="node() | @*" mode="#default in-patched">
          <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@*, node()" mode="#current"/>
          </xsl:copy>
        </xsl:template>
        <xsl:key name="by-id" match="*" use="@xml:id"/>
        <!-- collection()[2] is the document with patched para-like elements, where patching
          means: the text analysis results have been patched into the elements -->
        <xsl:template mode="#default" 
          match="*[@xml:id][exists(key('by-id', @xml:id, collection()[2])[not(@ttt:role = 'placeholder')])]">
          <xsl:apply-templates select="key('by-id', @xml:id, collection()[2])" mode="in-patched"/>
        </xsl:template>
        <xsl:template match="@xml:lang[. eq 'NOLANG'] | @xml:id[starts-with(., 'NOID_')]" mode="#default in-patched"/>
        <!-- Placeholders in the analyzed text document will be taken from the original doc: -->
        <xsl:template match="*[@ttt:role = 'placeholder']" mode="in-patched">
          <xsl:apply-templates select="key('by-id', @xml:id, collection()[1])" mode="#default"/>
        </xsl:template>
        <xsl:template match="ttt:pi | ttt:comment | ttt:ignorable-text" mode="#default">
          <xsl:copy-of select="node()"/>
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
    </p:inline>
  </p:input>
  
  <p:output port="result" primary="true"/>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:import href="http://transpect.io/xproc-util/xml-model/xpl/prepend-xml-model.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <p:xslt name="merge">
    <p:input port="source">
      <p:pipe port="source" step="merge-results"/>
      <p:pipe port="patched-paras" step="merge-results"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="merge-results"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="tokenized-to-tree/merge-results/merge-results">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <!--<tr:prepend-xml-model name="prepend-model">
    <p:input port="models"><p:empty/></p:input>
    <p:with-option name="hub-version" select="'1.1'"/>
  </tr:prepend-xml-model>-->
  
  
</p:declare-step>