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
    <p:documentation>
      The interesting part of a PDF page will typicially span a rectangle and contain
      the text that can actually be found in the XML that will be tagged.
      The uninteresting part will typically be
      - above the interesing part/page head: e.g. running title, page number
      - below the interesing part/page foot: e.g. page number
      - left or right of the interesting part/page margin: e.g. line numbers
      This step depends on correct coordinates of the text fragments.
    </p:documentation>
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
    <p:documentation>
      Group the text fragments into lines.
      This step depends on correct coordinates of the text fragments.
    </p:documentation>
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
    <p:documentation>
      Sometimes characters will be represented as multiple characters/glyphs in a PDF
      and sometimes they will be attributed to different lines after step 'lines'.
      For example 'ḗ' might be represented by
      &lt;line&gt;
        &lt;text&gt;^&lt;/text&gt;
      &lt;/line&gt;
      &lt;line&gt;
        &lt;text&gt;¯e&lt;/text&gt;
      &lt;/line&gt;
      This step is meant to get these replacements taken care of before steps 'spaces' and especially 'regex'.
      This step does NOT depend on correct coordinates of the text fragments but 'spaces' does.
      The coordinates should be left untouched.
    </p:documentation>
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
    <p:documentation>
      Insert space elements based on the distance between individual text fragments.
      In some PDF spaces are explicitly contained as glyphs, in others they are implicitly contained by gaps between text fragments.
      Sometimes we have both.
      This step depends on correct coordinates of the text fragments.
    </p:documentation>
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
  
  <p:xslt name="split-text" initial-mode="split-text">
    <p:documentation>
      Normalize (mostly) space representation of poppler output.
      Remove spaces from text fragments by splitting text fragments with spaces
      into several text fragments separated by space elements.
      Some templates in step 'regex' might expect distinct text fragments for certain parts of the text.
      For example because they were developed for poppler output with implicit spaces.
      To facilitate resuability of these templates we have to normalize the text/space representation of the poppler output.
      Further splitting might be necessary to generalize certain tasks of step 'regex'.
      For example '15,17 1946]' might be represented five text fragments in one PDF, as four in another and in yet another as one.
      In order to resue templates that expect '15', ',' and '17' to be repesented as three text fragments it might be necessary to
      split at the space and to separate the comma.
      This step does NOT depend on correct coordinates of the text fragments.
      This step introduces text fragments without or with incorrect coordinates.
    </p:documentation>
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/05_split-text">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

  <p:xslt name="regex" initial-mode="regex">
    <p:documentation>
      Generate the actual regex for each line.
      This step does NOT depend on correct coordinates of the text fragments.
    </p:documentation>
    <p:input port="parameters">
      <p:pipe port="result" step="params"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="postprocess-poppler"/>
    </p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/postprocess-poppler/06_regex">
    <p:with-option name="active" select="$debug"/>
    <p:with-option name="base-uri" select="$debug-dir-uri"/>
  </tr:store-debug>

</p:declare-step>
