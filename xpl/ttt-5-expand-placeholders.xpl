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
    <p:document href="../xsl/re-insert-placeholders.xsl"/>
  </p:input>
  <p:input port="params" kind="parameter"/>
  
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
    <p:input port="parameters">
      <p:pipe port="params" step="merge-results"/>
    </p:input>
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