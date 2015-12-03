
_ = require 'lodash'

moreMarkdown = require 'more-markdown'
mathjaxProcessor = require '@more-markdown/mathjax-processor'
codeControls     = require '@more-markdown/code-controls'
dotProcessor     = require '@more-markdown/dot-processor'
svgProcessor     = require '@more-markdown/svg-processor'
treeProcessor     = require '@more-markdown/tree-processor'
testProcessor    = require '@more-markdown/test-processor'
chartProcessor    = require '@more-markdown/graph-chart-processor'

markdownEditor = require '@tutor/markdown-editor'
javascriptEditorErrors = require '@tutor/javascript-editor-errors'
testSuite      = require '@tutor/test-suite'
graphTestSuite = require '@tutor/graph-test-suite'
jsSandbox      = require '@tutor/javascript-sandbox'
jailedSandbox  = require '@tutor/jailed-sandbox'
browserDebug   = require '@tutor/browser-debug-js'

proc = moreMarkdown.create 'output', processors: [
  # The mathjax processor finds all LaTeX formulas and typesets them
  mathjaxProcessor,

  # The code controls add buttons to "js" code environments that allow
  # the user to run or debug the code
  codeControls("js",
      {
        run: jailedSandbox.run
        debug: _.partial jailedSandbox.debug, _, {}, timeout: 1*60*1000 # 1 minute
        # debug: browserDebug.debug # supports debugger but hangs on infinite loops
      }
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

  svgProcessor("svg", (_.template "<svg data-element-id=\"<%= id %>\"></svg>"),
    _.template "<p style='background-color:red'><%= error %></p>")  

  treeProcessor("tree", (_.template "<svg data-element-id=\"<%= id %>\"></svg>"),
    _.template "<p style='background-color:red'><%= error %></p>")

  chartProcessor("chart", (_.template "<div data-element-id=\"<%= id %>\"><svg></svg></div>"),
    _.template "<p style='background-color:red'><%= error %></p>")

  # The test processor creates the "test" code environment in which one can
  # define tests in yasmine syntax
  testProcessor(["test","tests"],
    {
      tests: [
        (testSuite.itTests 
          registerTest: ((name, elem)-> elem.innerHTML += "<li>#{name}</li>")
          testResult: ((status, index, elem)->
              if status == null
                elem.children[index].innerHTML += " <span style='color:green'>Success</span>";
              else
                elem.children[index].innerHTML += " <span style='color:red'>Failed (#{status.exception})</span>";
            )
          allResults: ((error, passed, failed) -> 
            console.log "passed #{passed}, failed #{failed} (error: #{error})")
          ),
        testSuite.jsTests,
        graphTestSuite.collectGraphs,
        graphTestSuite.graphApi,
        testSuite.debugLog
      ],
      runner: jailedSandbox,
      templates:{
        tests: _.template("<h1>Tests</h1><ul data-element-id=\"<%= id %>\"></ul>")
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

```chart
plot(
  [[0,1],[1,2],[2,5],[3,3],[4,6],[5,1],[6,0]],
  function() {
    var data = [];
    for(var i=0; i < 10; i++)
      data.push([i, i*i]);
    return data;
  },function() {
    var data = [];
    for(var i=0; i < 10; i++)
      data.push([i-2, (i-10)*Math.pow(i,4-i)]);
    return data;
  }
);
```

```tree
A(B(D(()()) E(F (()())())) C(()()) )
```

```svg
<rect x="10" y="10" width="100" height="100"
    fill="yellow" stroke="navy" stroke-width="10"  />

<circle cx="50" cy="50" r="25" 
    fill="orange" />

<line x1="50" y1="50" x2="100" y2="100"
    stroke="blue" stroke-width="4" />

<polyline points="150,100 150,50 200,100 150,100 200,50 175,10 150,50 200,50 200,100"
    stroke="red" stroke-width="4" fill="none" />
```

```test
anyGraph("should have b", function(g){
    if(!g._nodes["b"]){
        throw "NO B";
    }
});
it("should work", function(){});
it("should work 2", function(){});
it("should work 3", function(){throw "abc"});
```
"""

editor = markdownEditor.create 'input', initialValue, plugins: [
  markdownPreview,
  markdownEditor.clearResults,
  javascriptEditorErrors "js", proc
]

proc.render editor.getValue()
