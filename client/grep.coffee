
expand = (text)->
  text.replace /\*(.+?)\*/, '<i>$1</i>'

emit = ($item, item) ->
  $item.append """
    <p style="background-color:#eee;padding:15px;">
      #{expand item.text}
    </p>
  """

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.grep = {emit, bind} if window?
module.exports = {expand} if module?

