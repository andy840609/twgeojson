width = window.innerWidth * 0.8
height = window.innerHeight - 10
census = d3.map!

svg = d3.select 'body' .append 'svg' .attr 'width', width .attr 'height', height

tw <- d3.json "tw.json"
<- d3.csv "census2013-03.csv" -> census.set it.ivid, do
  household: +it.household
  male:      +it.male
  female:    +it.female

val = -> it.male + it.female

max = d3.max [val c for _, c of census]
min = d3.min [val c for _, c of census]
scale = d3.scale.log!domain [min+1, max+1] .range [0, 9]
quantize = -> "q#{ ~~scale it }-9"

proj = mtw!

villages = topojson.feature tw, tw.objects['villages']


path = d3.geo.path!projection proj

g = svg.append 'g'
  .attr 'class', 'villages'

part-of = (name) -> -> 0 is it?indexOf name

var wanted, zoomin

set-wanted = ->
    wanted := part-of it

    zoomin := villages.features.filter -> wanted it.properties?ivid

    # draw exterior borders of given subset
    selected = topojson.mesh tw, tw.objects['villages'], (a, b) ->
      f = topojson.feature tw, a
      aa = wanted f.properties.ivid
      return true if a is b and aa

      g = topojson.feature tw, b
      bb = wanted g.properties.ivid
      (a isnt b and aa isnt bb)

    g.selectAll 'path.selected' .remove!
    g.append 'path'
      .datum selected
      .attr 'class', 'selected'
      .attr 'd', path


g.selectAll 'path'
  .data villages.features
  .enter!append 'path'
  .attr 'class', -> 
    return unless it.properties.ivid
    quantize val census.get it.properties.ivid
  .attr 'd', path
  .on \mouseover ->
    console?log it.properties.ivid, val census.get it.properties.ivid

set-wanted 'TPQ-280'

zoom-to = (set) ->
  b = path.bounds set
  s = 0.95 / Math.max((b[1][0] - b[0][0]) / width, (b[1][1] - b[0][1]) / height)
  t = [(width - s * (b.1.0 + b.0.0)) / 2, (height - s * (b.1.1 + b.0.1)) / 2]
  [x, y] = b.0

  g.transition!duration 1000
    .attr "transform" "translate(#{0 / 2},#{0 / 2})scale(#{s})translate(#{-x},#{-y})"
    .style "stroke-width", 5 / s + "px"

zoom-to {type: \FeatureCollection, features: zoomin}

d3.select 'span.zoomout'
  .on \click ->
    zoom-to villages

d3.select 'span.zoomin'
  .on \click ->
    zoom-to {type: \FeatureCollection, features: zoomin}

d3.select 'input.filter'
  ..on \change ->
    z = ..0.0.value
    set-wanted z
