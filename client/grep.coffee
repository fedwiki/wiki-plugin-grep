
escape = (line) ->
  line
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

parse = (text) ->
  escape(text).replace /\n/, '<br>'

want = (page) ->
  for item in page.story
    if item.type is 'paragraph'
      return true if item.text.match /<\/?[A-Za-z].*?>/
  false

run = ($item) ->

  status = (text) ->
    $item.find('.caption').text text

  status "waiting for sitemap"
  $.getJSON "http://#{location.host}/system/sitemap.json", (sitemap) ->
    checked = 0
    found = 0
    for place in sitemap
      $.getJSON "http://#{location.host}/#{place.slug}.json", (page) ->
        text = "[[#{page.title}]] (#{page.story.length})"
        if want page
          found++
          $item.append "#{wiki.resolveLinks text}<br>"
        checked++
        report = "found #{found} pages of #{checked} checked"
        report += ", #{sitemap.length - checked} remain" if checked < sitemap.length
        status report

emit = ($item, item) ->
  $item.append """
    <div style="background-color:#eee;padding:15px;">
      #{wiki.resolveLinks item.text, parse}
      <p class="caption">status here</p>
    </div>
  """
  run $item

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.grep = {emit, bind} if window?
module.exports = {parse} if module?

