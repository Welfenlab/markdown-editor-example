
_ = require 'lodash'

moreMarkdown = require 'more-markdown'
mathjaxProcessor = require '@more-markdown/mathjax-processor'
codeControls     = require '@more-markdown/code-controls'

markdownEditor = require '@tutor/markdown-editor'
javascriptEditorErrors = require '@tutor/javascript-editor-errors'

proc = moreMarkdown.create 'output', processors: [
  mathjaxProcessor,
  codeControls("js",{
    run: eval,
    debug: eval}, _.template """
      <div data-element-id=\"<%= id %>\">
        <button class='play'>Run</button>
        <button class='debug'>Debug</button>
      </div>
      <%= html %>
      """)
]

markdownPreview = (editor) ->
  proc.render editor.getValue()

initialValue = """# Test

$$ a = \\frac{1}{b}$$

```js
console.log("eval this!");
```
"""

editor = markdownEditor.create 'input', initialValue, plugins: [
  markdownPreview,
  ((editor) ->
    editor.clearResults()),
  javascriptEditorErrors proc
]

proc.render editor.getValue()
