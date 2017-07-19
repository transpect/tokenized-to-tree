<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:cx="http://xmlcalabash.com/ns/extensions"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:klett="http://klett.de/namespace"
  xmlns:tr="http://transpect.io"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  type="ttt:process-paras"
  name="process-paras">
  
  <p:input port="source" primary="true">
    <p:documentation>A ttt:paras document, as created by ttt-prepare-hub. The first ttt:para child is a para-like element
    from the original source document, potentially with placeholder elements and completely covered with IDs.
    The second child is a c:p element, with tokenizer results as c:t elements and interstitial space as c:s elements.
    There are some mandatory attributes 
    </p:documentation>
  </p:input>
  <p:input port="patch-token-stylesheet">
    <p:document href="../xsl/patch-token-results.xsl"/>
  </p:input>
  <p:output port="result" primary="true"/>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>

  <p:option name="milestones-only" select="'no'"/>
  <p:option name="map-higher-unicode-planes" select="'no'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  
  <tr:xslt-mode prefix="tokenized-to-tree/patch-results/2" mode="ttt:patch-token-results" msg="yes" name="patch-token-results">
    <p:documentation></p:documentation>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="patch-token-stylesheet" step="process-paras"/></p:input>
  </tr:xslt-mode>
  
  <tr:xslt-mode prefix="tokenized-to-tree/patch-results/3" mode="ttt:eliminate-duplicate-start-end-elts" msg="yes" name="eliminate-duplicate-start-end-elts">
    <p:documentation>Fringe case: there was a ttt:end with the same ID in a subsequent tab element. I didn’t see how to suppress it in first place, so 
    I’m gonna eliminate all but the first ttt:end elements with the same ID and all but the last ttt:start elements with the same ID.</p:documentation>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="patch-token-stylesheet" step="process-paras"/></p:input>
    <p:with-param name="map-higher-unicode-planes" select="$map-higher-unicode-planes"/>
  </tr:xslt-mode>
  
  <p:choose name="milestones-only">
    <p:when test="$milestones-only = 'yes'">
      <p:identity/>
    </p:when>
    <p:otherwise>
      <tr:xslt-mode prefix="tokenized-to-tree/patch-results/4" mode="ttt:pull-up-delims" msg="yes" name="pull-up-delims">
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        <p:input port="models"><p:empty/></p:input>
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet"><p:pipe port="patch-token-stylesheet" step="process-paras"/></p:input>
      </tr:xslt-mode>
    </p:otherwise>
  </p:choose>
  
</p:declare-step>