class Shape

if module?
  module.exports = Shape
else
  (window.Painter ?= {}).Shape = Shape
