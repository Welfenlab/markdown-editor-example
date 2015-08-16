
_ = require 'lodash'

moreMarkdown = require 'more-markdown'
mathjaxProcessor = require '@more-markdown/mathjax-processor'
codeControls     = require '@more-markdown/code-controls'
dotProcessor     = require '@more-markdown/dot-processor'
testProcessor    = require '@more-markdown/test-processor'

markdownEditor = require '@tutor/markdown-editor'
javascriptEditorErrors = require '@tutor/javascript-editor-errors'
testSuite      = require '@tutor/test-suite'
jsSandbox      = require '@tutor/javascript-sandbox'

proc = moreMarkdown.create 'output', processors: [
  # The mathjax processor finds all LaTeX formulas and typesets them
  mathjaxProcessor,

  # The code controls add buttons to "js" code environments that allow
  # the user to run or debug the code
  codeControls("js",
      jsSandbox.createRunner()
      , _.template """
      <div data-element-id=\"<%= id %>\">
        <button class='play'>Run</button>
        <button class='debug'>Debug</button>
      </div>
      <%= html %>
      """),

  # The dot processor processes "dot" environments and creates SVG graphs
  # for these
  dotProcessor("dot", (_.template "<svg data-element-id=\"<%= id %>\"><g/></svg>"),
    _.template "<p style='background-color:red'><%= error %></p>")

  # The test processor creates the "test" code environment in which one can
  # define tests in yasmine syntax
  testProcessor(["test","tests"],
    {
      tests: [
        (testSuite.extractTestNames (->)),
        (testSuite.itTests (->), ((error, passed, failed) -> console.log "passed #{passed}, failed #{failed} (error: #{error})"))
        testSuite.debugLog
      ],
      runner: jsSandbox,
      templates:{
        tests: _.template("<h1>Tests</h1><ul data-element-id=\"<%= id %></ul>"),
        item: _.template("<li><%= name %> <%= status %>")
      }
    })
]

markdownPreview = (editor) ->
  proc.render editor.getValue()

initialValue = """# Test

$$ a = \\frac{1}{b}$$

```js
console.log("eval this!");
```

# Graphs via dot and dagreD3

```dot
digraph {
abc -> b;
c -> b;
}
```


```test
it("should work", function(){});
```
"""

editor = markdownEditor.create 'input', initialValue, plugins: [
  markdownPreview,
  markdownEditor.clearResults,
  javascriptEditorErrors "js", proc
]

proc.render editor.getValue()
