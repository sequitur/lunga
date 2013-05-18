
$( document ).ready () ->

  $( "div.post" ).on "click", "button.remove-icon", ( event ) ->
    post = event.delegateTarget
    $(post).fadeOut 200

  $( "div.post" ).on "click", "button.minify-icon", ( event ) ->
    post = event.delegateTarget
    $(post).find(".post_content").slideToggle 200
