
escape = (line) ->
  line
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')

parse = (text) ->
  escape(text).replace /\n/, '<br>'

run = ($item) ->

  status = (text) ->
    $item.find('.caption').text text

  status "waiting for sitemap"
  $.getJSON "http://#{location.host}/system/sitemap.json", (sitemap) ->
    status "#{sitemap.length} pages to process"
    text = ("[[#{each.title}]]" for each in sitemap).join "<br>\n"
    $item.append wiki.resolveLinks text, (text) -> text

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

