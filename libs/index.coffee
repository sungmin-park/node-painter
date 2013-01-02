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
      fontWeight, fontSize, fontFace, baseLine, align, fit
    }={}
  ) ->
    # TODO adapt draw text from left top position
    fontWeight ?= 'normal'
    fontSize ?= 20 # px
    fontFace ?= 'serif'
    baseLine ?= 'middle'
    align ?= 'center'
    fit ?= 'shrink'

    ctx = @_ctx()
    ctx.textBaseline = baseLine
    ctx.textAlign = align
    if fit is 'shrink'
      fontSize = Math.min height, fontSize
      #TODO binary search로 변경
      fontSize = _.find([fontSize*10...0], (size) ->
        ctx.font = "#{fontWeight} #{size/10}px #{fontFace}"
        ctx.measureText(text).width < width
      ) / 10 ? 0
    ctx.font = "#{fontWeight} #{fontSize}px #{fontFace}"
    ctx.fillText text, x + width / 2, y + height / 2
    @

  _ctx: ->
    ctx = @canvas.getContext '2d'
    ctx.beginPath() #reset previous path
    ctx


if FROM_NODE
  module.exports = Painter
else
  for k, v of window.Painter ? {}
    Painter[k] = v
  window.Painter = Painter
