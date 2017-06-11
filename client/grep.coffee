###
 * Federated Wiki : Grep Plugin
 *
 * Licensed under the MIT license.
 * https://github.com/fedwiki/wiki-plugin-grep/blob/master/LICENSE.txt
###

escape = (line) ->
  line
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

word = (string) ->
  throw {message:"expecting type for '#{string}'"} unless string.match /^[a-z]*$/
  string

parse = (text) ->
  program = []
  listing = []
  errors = 0
  for line in text.split("\n")
    html = escape line
    try
      [match, op, arg] = line.match(/^\s*(\w*)\s*(.*)$/)
      switch op
        when '' then
        when 'ITEM','ACTION' then program.push {op, type:word(arg)}
        when 'TEXT','TITLE','SITE','ID','ALIAS','JSON' then program.push {op, regex: new RegExp(arg,'mi')}
        else throw {message:"don't know '#{op}' command"}
    catch err
      errors++
      html = """<span style="background-color:#fdd;width:100%;" title="#{err.message}">#{html}</span>"""
    listing.push html
  [program, listing.join('<br>'), errors]

evalPage = (page, steps, count) ->
  return true unless count < steps.length
  step = steps[count]
  switch step.op
    when 'ITEM'
      count++
      for item in page.story || []
        if step.type == ''
          return true if evalPart item, steps, count
        else
          if item.type is step.type
            return true if evalPart item, steps, count
      return false
    when 'ACTION'
      count++
      for action in page.journal || []
        if step.type == ''
          return true if evalPart action, steps, count
        else
          if action.type is step.type
            return true if evalPart action, steps, count
      return false
  evalPart page, steps, count

evalPart = (part, steps, count) ->
  return true unless count < steps.length
  step = steps[count++]
  switch step.op
    when 'TEXT','TITLE','SITE','ID','ALIAS'
      key = step.op.toLowerCase()
      return true if (part[key] || part.item?[key] || '').match step.regex
    when 'JSON'
      json = JSON.stringify part, null, ' '
      return true if json.match step.regex
  false

run = ($item, program) ->

  status = (text) ->
    $item.find('.caption').text text

  want = (page) ->
    evalPage page, program, 0

  status "fetching sitemap"
  $.getJSON "//#{location.host}/system/sitemap.json", (sitemap) ->
    checked = 0
    found = 0
    for place in sitemap
      $.getJSON "//#{location.host}/#{place.slug}.json", (page) ->
        text = "[[#{page.title}]] (#{page.story.length})"
        if want page
          found++
          $item.find('.result').append "#{wiki.resolveLinks text}<br>"
        checked++
        report = "found #{found} pages of #{checked} checked"
        report += ", #{sitemap.length - checked} remain" if checked < sitemap.length
        status report

emit = ($item, item) ->
  [program, listing, errors] = parse item.text
  $item.append """
    <div style="background-color:#eee;padding:15px;">
      <div class=listing>#{listing} <a class=open href='#'>»</a></div>
      <p class="caption">#{errors} errors</p>
      <p class="result"></p>
    </div>
  """
  run $item, program unless errors


open_all = (this_page, titles) ->
  for title in titles
    wiki.doInternalLink title, this_page
    this_page = null

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('a.open').click (e) ->
    e.stopPropagation()
    e.preventDefault()
    this_page = $item.parents('.page') unless e.shiftKey
    open_all this_page, $item.find('a.internal').map -> $(this).text()



window.plugins.grep = {emit, bind} if window?
module.exports = {parse, evalPart, evalPage} if module?
