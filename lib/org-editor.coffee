OrgTyping = require './org-typing'

module.exports =
class OrgEditor
  constructor: ->
    @editorsWithOrg = []

    atom.workspace.observeTextEditors (editor) =>
      ed = editor
      @setupEditor editor
      editor.onDidSave (event) =>
        @setupEditor ed

  setupEditor: (editor) =>
    ed = editor
    uri = ed.getBuffer().getUri()
    if (@editorsWithOrg[editor.id]!=1 and uri and uri.endsWith('.org'))
      @editorsWithOrg[editor.id] = 1
      ed.setSoftTabs true
      ed.setTabLength 2
      @typing = new OrgTyping(ed)

  destroy: =>

  serialize: ->
