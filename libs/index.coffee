#= require_tree .

FROM_NODE = module?.exports?
if FROM_NODE
  Canvas = require 'canvas'
  _ = require 'underscore'
else
  _ = window._

class Painter
  constructor: (@canvas, options) ->
    options = _.extend {}, options
    if options.container?
      if not(options.container instanceof jQuery)
        options.container = $(options.container)
      options.width ?= options.container.width()
      options.height ?= options.container.height()

    if not @canvas?
      if FROM_NODE
        @canvas = new Canvas options.width, options.height
      else
        $('<canvas>').each (i, canvas) =>
          canvas.width = options.width
          canvas.height = options.height
          if options.container?
            options.container.append canvas
          @canvas = canvas

  clear: ->
    @_ctx().clearRect 0, 0, @canvas.width, @canvas.height

  drawRect: (x, y, width, height, {color, lineWidth}={}) ->
    color ?= 'black'
    lineWidth ?= 1

    ctx = @_ctx()
    ctx.strokeStyle = color
    ctx.lineWidth = lineWidth = \
      Math.min lineWidth, width / 2, height / 2
    ctx.strokeRect(
      x + lineWidth / 2
      y + lineWidth / 2
      width - lineWidth
      height - lineWidth
    )
    @

  drawLine: (x, y, w, z, {color, lineWidth}={}) ->
    color ?= 'black'
    lineWidth ?= 1

    ctx = @_ctx()
    ctx.strokeStyle = color
    ctx.lineWidth = lineWidth
    ctx.moveTo x, y
    ctx.lineTo w, z
    ctx.stroke()
    @

  textBox: (
    x, y, width, height, text, {
      fontWeight, fontSize, fontFace, baseLine, align, fit, wordWrap
    }={}
  ) ->
    # TODO adapt draw text from left top position
    fontWeight ?= 'normal'
    fontSize ?= 20 # px
    fontFace ?= 'serif'
    baseLine ?= 'middle'
    align ?= 'center'
    fit ?= 'shrink'
    wordWrap ?= no

    ctx = @_ctx()
    ctx.textBaseline = baseLine
    ctx.textAlign = align
    if fit is 'shrink'
      fontSize = Math.min height, fontSize
      if not wordWrap
        fontSize = findFontSizeInLine(
          ctx, width, text, fontWeight, fontSize, fontFace
        )
        ctx.setFont fontWeight, fontSize, fontFace
        ctx.fillText text, x + width / 2, y + height / 2
      else
        [fontSize, lines] = findFontSize(
            ctx, width, height, text, fontWeight, fontSize, fontFace
        )
        ctx.setFont fontWeight, fontSize, fontFace
        leading = fontSize * 1.1
        innerHeight = (lines.length - 1) * leading
        firstY = y + (height - innerHeight) / 2
        _.each lines, (line, i) ->
          ctx.fillText line, x + width / 2, firstY + i * leading
    @

  _ctx: ->
    ctx = @canvas.getContext '2d'
    ctx.setFont = (weight, size, face) ->
      @font = "#{weight} #{size}px #{face}"
    ctx.beginPath() #reset previous path
    ctx

findFontSizeInLine = (ctx, width, text, weight, size, face, ratio=10) ->
  #TODO binary search로 변경
   _.find([size*ratio..0], (size) ->
      ctx.setFont weight, size / ratio, face
      ctx.measureText(text).width < width
    ) / ratio

wordWrap = (ctx, width, lineCount, words) ->
  # trivial solution
  if words.length < 1
    return []

  if lineCount is 1
    # if there are no possible solutions
    if ctx.measureText(words).width > width
      return null

  upper = words.length - 1
  lower = 0
  maxinumLine = null
  while lower <= upper
    i = Math.floor (upper + lower) / 2
    if ctx.measureText(line = words[0..i]).width < width
      maxinumLine = line
      lower = i + 1
      continue
    upper = i - 1

  if maxinumLine?
    lines = wordWrap ctx, width, lineCount - 1, words[maxinumLine.length..-1]
    if lines?
      lines.unshift maxinumLine
      return lines
  # cannot find any solution
  return null

findFontSize = (ctx, width, height, text, weight, size, face, ratio=10) ->
  words = text.split(' ')
  upper = size * ratio
  lower = 0
  maximumSize = [0, []]
  while lower <= upper
    bound = Math.floor (upper + lower) / 2
    fontSize = bound / ratio
    maximumLineCount = Math.floor height/(fontSize*1.1)
    ctx.setFont weight, fontSize, face
    lines = wordWrap ctx, width, maximumLineCount, words
    if lines?
      maximumSize = [fontSize, _.map lines, (line) -> line.join ' ']
      lower = bound + 1
    else
      upper = bound - 1

  maximumSize



if FROM_NODE
  module.exports = Painter
else
  for k, v of window.Painter ? {}
    Painter[k] = v
  window.Painter = Painter
