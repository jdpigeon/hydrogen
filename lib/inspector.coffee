{MessagePanelView, PlainMessageView} = require 'atom-message-panel'
transformime = require 'transformime'

module.exports =
class Inspector
    constructor: (@kernelManager) ->
        @editor = atom.workspace.getActiveTextEditor()

    inspect: ->
        @editor = atom.workspace.getActiveTextEditor()
        grammar = @editor.getGrammar()
        language = @kernelManager.getLanguageFor grammar
        kernel = @kernelManager.getRunningKernelFor language
        unless kernel?
            atom.notifications.addInfo 'No kernel running!'
            @inspector?.close()
            return

        [code, cursor_pos] = @getCodeToInspect()

        kernel.inspect code, cursor_pos, (result) =>
            console.log 'Inspector: Result:', result
            found = result.found
            if found is true
                onInspectResult = ({mimetype, el}) =>
                    lines = el.innerHTML.split('\n')
                    firstline = lines[0]
                    lines.splice(0, 1)
                    message = lines.join('\n')
                    @getInspector()
                    @addInspectResult(firstline, message)

                onError = (error) ->
                    console.error 'Inspector: Rendering error:', error

                transform(result.data).then onInspectResult, onError

            else
                atom.notifications.addInfo 'No introspection available!'
                @inspector?.close()

    getCodeToInspect: ->
        if @editor.getSelectedText()
            code = @editor.getSelectedText()
            cursor_pos = code.length
        else
            cursor = @editor.getLastCursor()
            row = cursor.getBufferRow()
            code = @editor.lineTextForBufferRow(row)
            cursor_pos = cursor.getBufferColumn()
        return [code, cursor_pos]

    getInspector: ->
        if not @inspector?
            console.log 'Opening Inspector'
            @inspector = new MessagePanelView
                title: 'Hydrogen Inspector'
        else
            @inspector.clear()

    addInspectResult: (firstline, message) ->
        @inspector.attach()
        @inspector.add new PlainMessageView
            message: firstline
            className: 'inspect-message'
            raw: true
        @inspector.add new PlainMessageView
            message: message
            className: 'inspect-message'
            raw: true

    toggleInspectorSize: ->
        if @inspector?
            @inspector.toggle()

    closeInspector: ->
        if @inspector?
            @inspector.close()

transform = transformime.createTransform()