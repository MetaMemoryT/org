{Point} = require 'atom'

OrgEditorHelpers = require './org-editor-helpers'

module.exports =
class OrgStructureEdit extends OrgEditorHelpers
  constructor: ->
    atom.workspace.observeTextEditors (editor) =>
      @setupCommands editor

  commands: (ed) => [
    ["org:insert-headline-empty-respect-content", (e) =>
      @inOrgFile ed, e, @insertEmptyHeadline],
    ["org:insert-headline-todo-respect-content", (e) =>
      @inOrgFile ed, e, @insertTodo],
    ["org:demote-headline", (e) =>
      @inOrgFile ed, e, @demoteHeadline],
    ["org:promote-headline", (e) =>
      @inOrgFile ed, e, @promoteHeadline],
    ["org:cycle-todo-forward", (e) =>
      @inOrgFile ed, e, @cycleTodoForward],
    ["org:cycle-todo-backward", (e) =>
      @inOrgFile ed, e, @cycleTodoBackward],
    ["org:demote-tree", (e) =>
      @inOrgFile ed, e, @demoteTree],
    ["org:promote-tree", (e) =>
      @inOrgFile ed, e, @promoteTree],
    ["org:move-tree-up", (e) =>
      @inOrgFile ed, e, @moveTreeUp],
    ["org:move-tree-down", (e) =>
      @inOrgFile ed, e, @moveTreeDown]
  ]

  setupCommands: (ed) =>
    for c in @commands(ed)
      atom.commands.add "atom-text-editor", c[0], c[1]

  insertEmptyHeadline: (ed) =>
    @insertHeadlineWith '* ', ed, true

  insertTodo: (ed) =>
    @insertHeadlineWith '* TODO ', ed, true

  promoteHeadline: (ed) =>
    @indentCurrentLine ed, -1

  demoteHeadline: (ed) =>
    @indentCurrentLine ed, 1

  cycleTodoForward: (ed) =>
    @cycleTodo ed, 1

  cycleTodoBackward: (ed) =>
    @cycleTodo ed, -1

  demoteTree: (ed) =>
    @indentCurrentTree ed, 1

  promoteTree: (ed) =>
    @indentCurrentTree ed, -1

  moveTreeDown: (ed) =>
    lines = new Array()
    row = @getCurrentRow ed
    startRow = row
    @setCursorPosition ed, row, 0
    indent = ed.indentationForBufferRow row
    ed.selectLine
    lastRow = ed.getBuffer().getLastRow()
    while (row==startRow or (row <lastRow and ed.indentationForBufferRow(row) > indent))
      lines.push @getLineAtRow ed, row
      row++;
      ed.selectDown 1
    ed.cutSelectedText()

    row = startRow
    insertionRow = - 1
    while (row < lastRow)
      if ed.indentationForBufferRow(row) < indent
        break
      if insertionRow!=-1 and ed.indentationForBufferRow(row) == indent
        break
      if insertionRow==-1 and ed.indentationForBufferRow(row) == indent
        insertionRow = row + 1
      if insertionRow!=-1 and ed.indentationForBufferRow(row) > indent
        insertionRow = row + 1
      row++

    if (insertionRow == -1)
      insertionRow = startRow

    @setCurrentRow ed, insertionRow
    if (insertionRow == lastRow)
      ed.insertNewline()


    finalRow = @getCurrentRow ed
    for line in lines
      ed.insertText line + '\n'

    @setCurrentRow ed, finalRow

  moveTreeUp: (ed) =>
    lines = new Array()
    row = @getCurrentRow ed
    startRow = row
    @setCursorPosition ed, row, 0
    indent = ed.indentationForBufferRow row
    ed.selectLine
    lastRow = ed.getBuffer().getLastRow()
    while (row==startRow or (row <lastRow and ed.indentationForBufferRow(row) > indent))
      lines.push @getLineAtRow ed, row
      row++;
      ed.selectDown 1

    ed.cutSelectedText()

    row = startRow - 1
    insertionRow = - 1
    while (row >= 0)
      if ed.indentationForBufferRow(row) < indent
        break
      if insertionRow!=-1 and ed.indentationForBufferRow(row) == indent
        break
      if insertionRow==-1 and ed.indentationForBufferRow(row) == indent
        insertionRow = row
      if insertionRow!=-1 and ed.indentationForBufferRow(row) > indent
        insertionRow = row
      row--

    if (insertionRow == -1)
      insertionRow = startRow

    @setCurrentRow ed, insertionRow

    finalRow = @getCurrentRow ed
    for line in lines
      ed.insertText line + '\n'

    @setCurrentRow ed, finalRow

  insertHeadlineWith: (prefix, ed, respectContent) =>
    if (respectContent==true)
      ed.moveCursorToEndOfLine()
    row = @getCurrentRow(ed)
    indent = ed.indentationForBufferRow(row)
    ed.insertNewline()
    ed.insertText(prefix)
    ed.setIndentationForBufferRow(row+1, indent)

  indentCurrentLine: (ed, value) =>
    row = @getCurrentRow(ed)
    @indentLine ed, row, value

  indentCurrentTree: (ed, value) =>
    row = @getCurrentRow
    buffer = ed.getBuffer()
    indent = ed.indentationForBufferRow(row)
    for i in [row+1 .. buffer.getLastRow()] by 1
      if (indent > 0 || value > 0) and ed.indentationForBufferRow(i) > indent
        @indentLine(ed, i, value)
      else
        break
    @indentCurrentLine(ed, value)

  indentLine: (ed, row, value) =>
    newIndent = ed.indentationForBufferRow(row) + value
    if newIndent>=0
      ed.setIndentationForBufferRow row, newIndent

  cycleTodo: (ed, direction) =>
    keywords = ['TODO', 'NEXT', 'DONE']
    line = @getCurrentLine ed
    for i in [0..keywords.length] by 1
      kw = keywords[i]
      if (line.indexOf(kw) != -1)
        nextIndex = (i+direction)%keywords.length
        if (nextIndex<0)
          nextIndex = keywords.length-1
        nextKW = keywords[nextIndex]
        @replaceCurrentLine ed, line.replace "* " + kw, '* ' + nextKW

  destroy: =>

  serialize: ->
