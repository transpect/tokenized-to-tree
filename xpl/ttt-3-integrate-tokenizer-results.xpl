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
    <p:documentation>A ttt:paras document, as created by ttt:prepare-input. The first ttt:para child
      is a para-like element from the original source document, potentially with placeholder
      elements and completely covered with IDs. The second child is a ttt:tokens element, with
      tokenizer results as ttt:t elements and interstitial space as ttt:s elements (the latter is
      purely declarative and optional). There are two mandatory attributes, @start and @end, in
      order to facilitat merging of the original and the tokeizing/analysis results. In the
      normalized input, these attributes are called @ttt:start and @ttt:end in order to avoid name
      clashes. For a given processing unit, all start and end attributes refer to the same string,
      which is the string value of the input, which in turn must be identical to the string value of
      the tokenization/analysis.</p:documentation>
  </p:input>
  <p:input port="patch-token-stylesheet">
    <p:document href="../xsl/patch-token-results.xsl"/>
    <p:documentation>This will typically be used unaltered (unimported). There are cases though where collateral
    actions will be performed while merging the tokens with the normalized input.</p:documentation>
  </p:input>
  <p:input port="rng-schema">
    <p:document href="http://transpect.io/tokenized-to-tree/schema/tokenized-to-tree.rng"/>
  </p:input>
  
  <p:output port="result" primary="true"/>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>

  <p:option name="milestones-only" select="'no'"/>
  <p:option name="map-higher-unicode-planes" select="'no'"/>
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <p:validate-with-relax-ng name="rng" assert-valid="true">
    <p:input port="schema">
      <p:pipe port="rng-schema" step="process-paras"/>
    </p:input>
  </p:validate-with-relax-ng>

  <p:sink name="sink1"/>
  
  <p:xslt name="extract-sch">
    <p:input port="source">
      <p:pipe port="rng-schema" step="process-paras"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet">
      <p:document href="http://transpect.io/tokenized-to-tree/schema/sch-from-rng.xsl"/>
    </p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="tokenized-to-tree/process-paras/extract-schmatron" extension="sch">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:sink name="sink2"/>

  <p:validate-with-schematron assert-valid="true" name="sch">
    <p:input port="source">
      <p:pipe port="source" step="process-paras"/>
    </p:input>
    <p:input port="schema">
      <p:pipe port="result" step="extract-sch"/>
    </p:input>
    <p:input port="parameters">
      <p:empty/>
    </p:input>
  </p:validate-with-schematron>
  <!--
  <p:sink/>
  
  <tr:store-debug pipeline-step="tokenized-to-tree/process-paras/schmatron-report">
    <p:input port="source">
      <p:pipe port="report" step="sch"></p:pipe>
    </p:input>
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:sink></p:sink>
  
  <p:identity>
    <p:input port="source">
      <p:pipe port="result" step="sch"/>
    </p:input>
  </p:identity>-->
  
  <tr:xslt-mode prefix="tokenized-to-tree/patch-results/2" mode="ttt:patch-token-results" msg="yes" name="patch-token-results">
    <p:documentation>Transfers the tokenization/analysis information (each ttt:para’s 2nd child) to the normalized
    input processing units (each ttt:para’s first step) by creating milestone elements for the start and the end of each 
    token. These milestone elements also hold the analysis results as attributes.</p:documentation>
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
  
  <tr:xslt-mode prefix="tokenized-to-tree/patch-results/4" mode="ttt:move-start-end-elts-from-ttt-generated" msg="yes" name="move-start-end-elts-from-ttt-generated">
    <p:documentation>When a ttt:start or ttt:end is in a ttt:generated, it will be removed later on. Example: a generated ` - ` for a list item. Lets move it out of the ttt:generated.</p:documentation>
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
      <tr:xslt-mode prefix="tokenized-to-tree/patch-results/5" mode="ttt:pull-up-delims" msg="yes" name="pull-up-delims">
        <p:with-option name="debug" select="$debug"/>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
        <p:input port="models"><p:empty/></p:input>
        <p:input port="parameters"><p:empty/></p:input>
        <p:input port="stylesheet"><p:pipe port="patch-token-stylesheet" step="process-paras"/></p:input>
      </tr:xslt-mode>
    </p:otherwise>
  </p:choose>
  
</p:declare-step>