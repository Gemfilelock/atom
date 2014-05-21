React = require 'react'
{div} = require 'reactionary'
{isEqual, isEqualForProperties, multiplyString, toArray} = require 'underscore-plus'
SubscriberMixin = require './subscriber-mixin'

WrapperDiv = document.createElement('div')

module.exports =
GutterComponent = React.createClass
  displayName: 'GutterComponent'
  mixins: [SubscriberMixin]

  lastMeasuredWidth: null
  dummyLineNumberNode: null

  render: ->
    {scrollHeight, scrollTop} = @props

    style =
      height: scrollHeight
      WebkitTransform: "translate3d(0px, #{-scrollTop}px, 0px)"

    div className: 'gutter',
      div className: 'line-numbers', ref: 'lineNumbers', style: style,
        @renderDummyLineNode()
        @renderLineNumbers() if @isMounted()

  renderDummyLineNode: ->
    {editor, renderedRowRange, maxLineNumberDigits} = @props
    bufferRow = editor.getLineCount()
    key = 'dummy'

    LineNumberComponent({key, bufferRow, maxLineNumberDigits})

  renderLineNumbers: ->
    {editor, renderedRowRange, maxLineNumberDigits, lineHeight} = @props
    [startRow, endRow] = renderedRowRange

    lastBufferRow = null
    wrapCount = 0

    for bufferRow, i in editor.bufferRowsForScreenRows(startRow, endRow - 1)
      if bufferRow is lastBufferRow
        softWrapped = true
        key = "#{bufferRow}-#{++wrapCount}"
      else
        softWrapped = false
        key = bufferRow.toString()

      screenRow = startRow + i
      LineNumberComponent({key, bufferRow, screenRow, softWrapped, maxLineNumberDigits, lineHeight})

  # Only update the gutter if the visible row range has changed or if a
  # non-zero-delta change to the screen lines has occurred within the current
  # visible row range.
  shouldComponentUpdate: (newProps) ->
    return true unless isEqualForProperties(newProps, @props, 'renderedRowRange', 'scrollTop', 'lineHeight', 'fontSize')

    {renderedRowRange, pendingChanges} = newProps
    for change in pendingChanges when Math.abs(change.screenDelta) > 0 or Math.abs(change.bufferDelta) > 0
      return true unless change.end <= renderedRowRange.start or renderedRowRange.end <= change.start

    false

  componentDidUpdate: (oldProps) ->
    @measureWidth() unless @lastMeasuredWidth? and isEqualForProperties(oldProps, @props, 'maxLineNumberDigits', 'fontSize', 'fontFamily')

  measureWidth: ->
    lineNumberNode = @refs.lineNumbers.getDOMNode().firstChild
    # return unless lineNumberNode?

    width = lineNumberNode.offsetWidth
    if width isnt @lastMeasuredWidth
      @props.onWidthChanged(@lastMeasuredWidth = width)

LineNumberComponent = React.createClass
  displayName: 'LineNumberComponent'

  render: ->
    {screenRow, lineHeight} = @props

    if screenRow?
      style = {position: 'absolute', top: screenRow * lineHeight}
    else
      style = {visibility: 'hidden'}

    @innerHTML ?= @buildInnerHTML()

    div {
      className: 'line-number'
      'data-screen-row': screenRow
      style
      dangerouslySetInnerHTML: {__html: @innerHTML}
    }

  buildInnerHTML: ->
    {bufferRow, softWrapped, maxLineNumberDigits} = @props

    if softWrapped
      lineNumber = "•"
    else
      lineNumber = (bufferRow + 1).toString()

    padding = multiplyString('&nbsp;', maxLineNumberDigits - lineNumber.length)
    iconHTML = '<div class="icon-right"></div>'
    padding + lineNumber + iconHTML

    if softWrapped
      lineNumber = "•"
    else
      lineNumber = (bufferRow + 1).toString()

    padding = multiplyString('&nbsp;', maxLineNumberDigits - lineNumber.length)
    iconHTML = '<div class="icon-right"></div>'
    padding + lineNumber + iconHTML


  shouldComponentUpdate: (newProps) ->
    not isEqualForProperties(newProps, @props, 'screenRow', 'maxLineNumberDigits')
