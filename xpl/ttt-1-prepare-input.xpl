<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:tr="http://transpect.io"
  type="ttt:prepare-input"
  name="prepare-input">
  
  <p:input port="source" primary="true"/>
  <p:input port="stylesheet" xml:id="stylesheet-input">
    <p:documentation>You can customize it by importing this default stylesheet and providing
    your customized stylesheet on this port.</p:documentation>
    <p:document href="../xsl/prepare-input.xsl"/>
  </p:input>
  <p:output port="result" primary="true"/>
  <p:output port="with-ids">
    <p:pipe port="result" step="add-ids"/>
  </p:output>
  <p:option name="map-higher-unicode-planes" select="'no'"/>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'debug'"/>
  
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  
  <tr:xslt-mode prefix="tokenized-to-tree/prepare-input/1" mode="ttt:add-ids" msg="yes" name="add-ids">
    <p:documentation xmlns="http://www.w3.org/1999/xhtml">
      <p>Will add IDs to all elements (list of element names configurable in
        $ttt:content-element-names) that don’t have IDs yet.</p>
      <p>In addition, it will remove information (links, anchors,
        highlighting, underlining, overview table, …) that was added when rendering the analysis results of the preceding
        analysis run, if there was any.</p>
      <p>Because this information is specific to the analysis results renderer of your workflow, the removal of this information 
        should also be done by a specific stylesheet, i.e., one that imports <a href="../xsl/prepare-input.xsl">../xsl/prepare-input.xsl</a> and
        is supplied to the <a href="#stylesheet-input">stylesheet port</a>.</p>
      <p>As a side effect, it may map characters beyond the Unicode Basic Multilingual Plane into the BMP’s private use area,
      specifically the characters from U+1F000 thru U+1F9FF to U+E200 thru U+EBFF</p>
    </p:documentation>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="prepare-input"/></p:input>
    <p:with-param name="map-higher-unicode-planes" select="$map-higher-unicode-planes"/>
  </tr:xslt-mode>
  
  <tr:xslt-mode prefix="tokenized-to-tree/prepare-input/2" mode="ttt:discard" msg="yes" name="discard">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="prepare-input"/></p:input>
  </tr:xslt-mode>
  
  <tr:xslt-mode prefix="tokenized-to-tree/prepare-input/3" mode="ttt:count-text" msg="yes" name="count-text">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="prepare-input"/></p:input>
  </tr:xslt-mode>
  
</p:declare-step>