ace.require("ace/ext/language_tools");

var queryEditor = ace.edit('query-editor');
queryEditor.session.setMode('ace/mode/text');
queryEditor.setOptions({
  enableBasicAutocompletion: false,
  enableSnippets: false,
  enableLiveAutocompletion: false
});

var queryArgEditor = ace.edit('query-arg-editor');
queryArgEditor.session.setMode('ace/mode/json');
queryArgEditor.setOptions({
  enableBasicAutocompletion: true,
  enableSnippets: true,
  enableLiveAutocompletion: false
})

queryArgEditor.session.setTabSize(2);
queryArgEditor.session.setUseSoftTabs(true);

var resultEditor = ace.edit('result-editor');
resultEditor.session.setMode('ace/mode/json');

resultEditor.session.setTabSize(2);
resultEditor.session.setUseSoftTabs(true);