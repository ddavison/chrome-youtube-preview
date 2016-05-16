###
  constant.js
###

class API
  @key = 'AIzaSyBvDau9lWMDridxIO3wZ4nAs-cGAtIAdQs'
  @ajax = new XMLHttpRequest();
  @video = null

  constructor: ->

  get_video: (video_id, callback) ->
    @get "https://www.googleapis.com/youtube/v3/videos?part=snippet%2CcontentDetails%2Cstatistics&id=#{video_id}&maxResults=1&key=#{API.key}", ->
      callback(JSON.parse(this.responseText))

  get: (url, callback) ->
    API.ajax.addEventListener 'load', callback
    API.ajax.open 'GET', url
    API.ajax.send()


class Previewer
  handles =
    on_hover: undefined
    parent_leave: undefined

  ids =
    previewer:
      container: 'ytp-main-container'
      parent: 'youtube-previewer'
      header: 'ytp-header'
      content_container: 'ytp-content-container'
      content: 'ytp-content'
      loading: 'ytp-loading'

  previewer =
    width: 600
    height: 200

  parent = document.createElement('div')
  youtube_links_selector = "[href*='watch?v='],.yt-lockup-thumbnail"

  # pseudo-constructor
  constructor: ->
    @api = new API()
    parent.addEventListener 'mouseenter', @parent_hover, true
    #    parent.addEventListener 'mouseout', parent_leave, false
    parent.addEventListener 'mousemove', @parent_mousemove, true

    for youtube_link in document.querySelectorAll youtube_links_selector
      youtube_link.addEventListener 'mouseenter', @on_hover, false
      youtube_link.addEventListener 'mouseout', @on_leave, false
      youtube_link.addEventListener 'mousemove', @on_mousemove, false

    parent.setAttribute('id', ids.previewer.parent)
    parent.style.position = 'absolute'
    parent.style.visibility = 'visible'

    document.body.appendChild parent
    document.body.addEventListener "click", ->
      parent.style.visibility = 'hidden'

    parent.innerHTML = "
      <div id='#{ids.previewer.container}'>
        <div id='#{ids.previewer.header}'>
          <img class='logo' src='#{chrome.runtime.getURL("/assets/images/previewer-logo-512.png")}' alt='' />
          <a id='ytp-logo-link' href=''>
            <span id='ytp-logo-text'></span>
          </a>
        </div>
        <div id='#{ids.previewer.content_container}'>
          <div id='#{ids.previewer.content}'>
          </div>
          <div id='#{ids.previewer.loading}'></div>
        </div>
      </div>
    "

# when the mouse enters the previewer links
  on_hover: (event) =>
    clearTimeout handles.on_hover
    handles.on_hover = setTimeout =>
      parent.setAttribute 'data-video-id', @extract_video_id(event.target.href)

      posx = event.clientX
      posy = event.clientY
      parent.style.width = "#{previewer.width}px"
      parent.style.height = "#{previewer.height}px"
      parent.style.top = "#{(posy - 5)}px"
      parent.style.left = "#{(posx - 5)}px"

      if parseInt(parent.style.left) + previewer.width > document.body.clientWidth
        (parent.style.left = "#{document.body.clientWidth - previewer.width}px")
      if parseInt(parent.style.top) + previewer.height > document.body.clientHeight
        (parent.style.top = "#{document.body.clientHeight - previewer.height}px")

      parent.style.visibility = 'visible'
      @load_video_information()
    , 500

# when the mouse leaves the previewer links
  on_leave: (event) ->
    clearTimeout handles.on_hover
# only applies when the previewer is up
  on_mousemove: (event) ->

  extract_video_id: (src) ->
# this will extract the video id's from links
    src.split('v=')[1].split('&')[0]

  ###
    Parent Behaviors
  ###
  parent_hover: (event) ->
    clearTimeout handles.parent_leave # prevent from closing
  parent_leave: (event) ->
    clearTimeout handles.parent_leave
    handles.parent_leave = setTimeout ->
      parent.style.visibility = 'hidden'
    , 500
  parent_mousemove: (event) ->

    ### Content Methods ###
  set_content: (inner_html) ->
    document.getElementById(ids.previewer.content).innerHTML = inner_html

  show_loading: ->
    loader = document.getElementById(ids.previewer.loading)
    loader.style.backgroundImage = chrome.runtime.getURL("/assets/images/spiral.gif")
    setTimeout ->
      loader.style.visibility = 'visible'
    , 100

  hide_loading: ->
    loader = document.getElementById(ids.previewer.loading)
    loader.style.backgroundImage = chrome.runtime.getURL("/assets/images/spiral.gif")
    setTimeout ->
      loader.style.visibility = 'hidden'
    , 100

  load_video_information: ->
# main method that loads all the data into the container
    @show_loading()
    @api.get_video(parent.getAttribute('data-video-id'), (obj) =>
      console.log JSON.stringify(obj)
      video = obj.items[0]

      document.getElementById('ytp-logo-text').innerText = video.snippet.title
      document.getElementById('ytp-logo-link').href = "https://youtube.com/watch?v=#{video.id}"

      likes = parseInt(video.statistics.likeCount)
      dislikes = parseInt(video.statistics.dislikeCount)
      total_disposition = likes + dislikes

      like_percent = "#{(likes / total_disposition) * 100}%"
      dislike_percent = "#{(dislikes / total_disposition) * 100}%"

      @set_content("
          <img id='ytp-video-thumbnail' src='#{video.snippet.thumbnails.default.url}' width='#{video.snippet.thumbnails.default.width}' height='#{video.snippet.thumbnails.default.height}' />
          <p id='ytp-video-description'>#{video.snippet.description}</p>

          <div id='watch7-views-info'>
            <div class='watch-view-count'>#{video.statistics.viewCount} views</div>
            <div class='video-extras-sparkbars'>
              <div class='video-extras-sparkbar-likes' style='width: #{like_percent}'></div>
              <div class='video-extras-sparkbar-dislikes' style='width: #{dislike_percent}'></div>
            </div>
          </div>
      ")
    )
    @hide_loading()


do ->
  window.ytp = new Previewer()
