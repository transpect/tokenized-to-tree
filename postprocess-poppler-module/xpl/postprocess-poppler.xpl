<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:ppp="http://transpect.io/postprocess-poppler"
  xmlns:ttt="http://transpect.io/tokenized-to-tree" xmlns:c="http://www.w3.org/ns/xproc-step"
  version="1.0" xmlns:cx="http://xmlcalabash.com/ns/extensions" xmlns:tr="http://transpect.io"
  name="postprocess-poppler" type="ppp:postprocess-poppler">

  <p:input port="source" primary="true">
    <p:documentation>Poppler’s pdf2xml output with page, fontspec, and text elements, but no lines yet. 
      The text elements must have coordinates like &lt;text top="1261" left="0" width="0" height="2" font="0"> &lt;/text>.</p:documentation>
  </p:input>
  <p:input port="stylesheet">
    <p:document href="http://transpect.io/tokenized-to-tree/postprocess-poppler-module/xsl/postprocess-poppler.xsl"/>
  </p:input>
  <p:input port="param-doc" kind="parameter">
    <p:document href="../default-params.xml"/>
  </p:input>

  <p:output port="result" primary="true"/>
  <p:serialization port="result" omit-xml-declaration="false" indent="false"/>

  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>

  <p:import href="http://transpect.io/tokenized-to-tree/xpl/ttt-1-prepare-input.xpl"/>
  <p:import href="http://transpect.io/tokenized-to-tree/line-finder-module/xpl/line-finder.xpl"/>
  <p:import href="http://transpect.io/tokenized-to-tree/xpl/ttt-3-integrate-tokenizer-results.xpl"/>
  <p:import href="http://transpect.io/tokenized-to-tree/xpl/ttt-5-expand-placeholders.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/xproc-util/re-attach-out-of-doc-PIs/xpl/re-attach-out-of-doc-PIs.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

  <p:parameters name="params">
    <p:input port="parameters">
      <p:pipe port="param-doc" step="postprocess-poppler"/>
    </p:input>
  </p:parameters>
  
  <p:xslt name="remove-uninteresting" initial-mode="remove-uninteresting">
    <p:input port="source">
      <p:pipe port="source" step="postprocess-poppler"/>
    </p:input>
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/01_remove-uninteresting">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt name="lines" initial-mode="lines">
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/02_lines">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt name="preprocess-text" initial-mode="preprocess-text">
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/03_preprocess-text">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt name="spaces" initial-mode="spaces">
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/04_spaces">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>
  
  <p:xslt name="regex" initial-mode="regex">
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/05_regex">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

</p:declare-step>
