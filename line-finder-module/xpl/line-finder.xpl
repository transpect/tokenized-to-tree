<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:tr="http://transpect.io"
  type="ttt:line-finder"
  name="line-finder">
  
  <p:input port="lines" primary="true">
    <p:documentation>A postprocessed poppler pdftoxml document with line[@regex] elements. The lines, together with optional
      whitespace in between, are expected to cover the paragraph-like elements that are children of /ttt:paras/ttt:para on the
      ttt-paras port.</p:documentation>
  </p:input>
  <p:input port="ttt-paras">
    <p:documentation>A ttt:paras document as created by an input preprocessor, that is, without any analysis or matching results
      patched into the children of ttt:para). The regexes of the line elements in the lines document should match
      ttt:para/*/@ttt:text</p:documentation>
  </p:input>
  <p:input port="stylesheet">
    <p:document href="../xsl/line-finder.xsl"/>
  </p:input>
  
  <p:output port="result" primary="true"/>

  <p:option name="ignore-matched-lines" required="false" select="'false'">
    <p:documentation>Sometimes several ttt:para are nearly identical.
      If multiple ttt:para/*/@ttt:text have an identical beginning, that match multiple nearly or completely identical line/@regex,
      the first matching line/@regex always "wins".
      Consequently some line/@regex are tagged multiple times, others are omitted.
      This option triggers two things:
      1) in mode try-coverage, lines that have already been matched in a ttt:para, will not be used as potential lines for following ttt:para and
      2) if a line-candidate matches, a following, longer match will not be used instead.
    </p:documentation>
  </p:option>
  
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:import href="http://transpect.io/xproc-util/xml-model/xpl/prepend-xml-model.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>

  <p:xslt name="find-matching-lines" initial-mode="find-matching-lines">
    <p:input port="source">
      <p:pipe port="ttt-paras" step="line-finder"/>
      <p:pipe port="lines" step="line-finder"/>
    </p:input>
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="line-finder"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
  <tr:store-debug pipeline-step="tokenized-to-tree/line-finder/candidates">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:xslt name="try-coverage" initial-mode="try-coverage">
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="line-finder"/>
    </p:input>
    <p:with-param name="ignore-matched-lines" select="$ignore-matched-lines"/>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/line-finder/covfefe">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>
  
  <p:xslt name="side-by-side" initial-mode="side-by-side">
    <p:input port="stylesheet">
      <p:pipe port="stylesheet" step="line-finder"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>

  <tr:store-debug pipeline-step="tokenized-to-tree/line-finder/side-by-side">
    <p:with-option name="active" select="$debug" />
    <p:with-option name="base-uri" select="$debug-dir-uri" />
  </tr:store-debug>

</p:declare-step>