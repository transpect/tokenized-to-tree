<?xml version="1.0" encoding="UTF-8"?>
<p:declare-step version="1.0"
  xmlns:p="http://www.w3.org/ns/xproc"
  xmlns:c="http://www.w3.org/ns/xproc-step"
  xmlns:ttt="http://transpect.io/tokenized-to-tree"
  xmlns:tr="http://transpect.io"
  type="ttt:prepare-input"
  name="prepare-input">
  
  <p:documentation xmlns="http://www.w3.org/1999/xhtml">
    <h3>Ignorable, Normalized and Generated Content</h3>
    <p>Content that should be ignored for string counting purposes will receive a <code>role="ttt:placeholder"</code>
    attribute.</p>
    <p>If the content is not an element, it will be wrapped in one of the following special elements:</p>
    <dl>
      <dt>ttt:comment</dt>
      <dd>Contains a comment that will be invisible to the string-length counting process but will be re-inserted after 
        token tagging has been inserted.</dd>
      <dt>ttt:ignorable-text</dt>
      <dd>Contains text that will be invisible to the string-length counting process but will be re-inserted after 
        token tagging has been inserted.</dd>
      <dt>ttt:pi</dt>
      <dd>Contains a processing instruction that will be invisible to the string-length counting process but will be 
        re-inserted after token tagging has been inserted.</dd>
    </dl>
    <p>These placeholder elements will then be emptied for the document that is output on the <code>result</code> port.
      The full elements will be retained in the document that is output on the <code>with-ids</code> port.</p>
    <p>After the result document has been processed (tokenization, analysis, creating token markup and attaching 
      the analysis results to the marked-up tokens), the empty placeholder elements will be replaced with their 
    original content.</p>
    <p>For this to work, all placeholder elements need to have IDs. A generated <code>xml:id</code> attribute starting 
      with 'NOID_' will be added if the future placeholder element does not have an ID yet. The 'NOID_' IDs will 
    be removed during the merging step, <code>ttt:merge-results</code> (file <code>ttt-5-expand-placeholders.xpl</code>).</p>
    <p>There is an additional type of <code>ttt:placeholder</code> element:</p>
    <dl>
      <dt>ttt:normalized-space</dt>
      <dd>An element that contains exactly one space character, plus an <code>@original</code> attribute. For counting 
        and analysis purposes, it will look like an ordinary single space character. The original space-like content will 
        be restored from the <code>@original</code> attribute during the merging phase.</dd>
    </dl>
    <p>Finally, there is the opposite case of ignored content, which is generated content. Scenario: In a TEI critical
      apparatus, the text-critical notes are rendered in a distinct section. Each note is preceded by the page and
      line(s) that it applies to, plus some words of context. The context will be rendered via the note’s
        <code>@target</code> attribute. If the task is to retrofit PDF line breaks into the source, the PDF lines must
      be matched against the notes. This can be done either by inserting a regex that would match any page/line numbers,
      followed by any context phrase, or by at least including the context phrase in the note element so that it will
    match the PDF line (modulo page/line numbers). Then we need to temporarily augment the note with the context phrase,
    but we need to make sure that it will be removed after the line breaks have been marked up.</p>
    <p>For this purpose, an element</p>
    <dl>
      <dt>ttt:generated</dt>
      <dd>Mostly useful for line number retrofitting applications. Contains text that is not present at this location in
        the source XML. It can be a placeholder for a page number or for text from another place in the text, for example
      from a lemma that is repeated at the beginning of a note.</dd>
    </dl>
    <h3>Side-by-Side Format</h3>
    <h3>Tokenization Markup</h3>
    <p>The tokens will be marked up with <code>ttt:token</code> and <code>ttt:space</code> elements. These elements
    cover the whole unexpanded paragraph.</p>
  </p:documentation>
  
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
  
  <p:sink name="sink1"/>
  
  <tr:xslt-mode prefix="tokenized-to-tree/prepare-input/2" mode="ttt:discard" msg="yes" name="discard">
    <p:input port="source">
      <p:pipe port="result" step="add-ids"/>
      <p:pipe port="source" step="prepare-input">
        <p:documentation>Sometimes a para needs to be augmented with referenced text from discarded elements 
          in order to match the rendered para’s text (taken from a popplerized PDF or an HTML doc).</p:documentation>
      </p:pipe>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="prepare-input"/></p:input>
  </tr:xslt-mode>
  
  <!--<p:xslt name="count-text" initial-mode="ttt:count-text">
    
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="prepare-input"/></p:input>
  </p:xslt>-->
  
  <tr:xslt-mode prefix="tokenized-to-tree/prepare-input/3" mode="ttt:count-text" msg="yes" name="count-text">
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="parameters"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="prepare-input"/></p:input>
  </tr:xslt-mode>
  
</p:declare-step>