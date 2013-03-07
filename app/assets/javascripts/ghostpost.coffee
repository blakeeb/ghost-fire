# Throttle
fnThrottle = (wait, func) ->
  context= args= timeout= result = null
  previous = 0;
  later = () ->
    previous = new Date;
    timeout = null;
    result = func.apply(context, args);
  return () ->
    now = new Date;
    remaining = wait - (now - previous);
    context = this;
    args = arguments;
    if remaining <= 0
      clearTimeout timeout
      timeout = null
      previous = now
      result = func.apply context, args
    else if !timeout
      #timeout = setTimeout(later, remaining);
      alert("You have been throttled.")
    return result


window.GhostPost =
  start: ->

    # Get a reference to the root of the chat data.
    @messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)
    GhostPost.joined_at = Date.now()

  initializeUser: ->

    # onboard user - either create new or reuse old avatar.

    adjectives = ['Silly','Fuzzy','Crusty','Evil','Mad','Worst','Saintly','Wild','Wildest','Crabby','Crabbiest','Simple','Sadistic','Troubled','Ecstatic','Janky','Loopy','Snarky','Healthy','Tasty','Tricky','Sweetest','Fair','Fast','Scrappy','Shallow','Hungry','Moaning','Modern','Icy','Proud','Mr.','Mrs.','Stingy','Tall','Large','Little','Big','Frantic','Petite','Prickly','Jealous','Energetic','Wicked','Wet','Witty','Biggie','Smokey','Interesting','Funky']
    nouns = ['Scoble','Rackspace','Elance','Elias','McClure']

    if (localStorage.username and localStorage.avatar_id) and (!GhostPost.resetName)
      GhostPost.username = localStorage.username
      GhostPost.avatar_id = localStorage.avatar_id
      console.log 'User localStorage acknolwedged - reusing old avatar ', GhostPost.username, GhostPost.avatar_id
    else
      # create new avatar / image
      console.log 'Could not find localStorage - creating new user/avatar'
      GhostPost.username = adjectives[Math.floor(Math.random()*adjectives.length)] + nouns[Math.floor(Math.random()*nouns.length)]
      GhostPost.avatar_id = Math.floor(Math.random()*24) + 1
      localStorage.username = GhostPost.username
      localStorage.avatar_id = GhostPost.avatar_id

      # Display new Avatar Message and image on the screen
      $("#avatarNotificationDiv").html HandlebarsTemplates['messages/avatarNotification']({ GhostPost })

    # Commenting this out as we now append the new Ghostpost
    $('#avatarName').html GhostPost.username
    $('#avatarImage').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'
    $('#avatarNameSmall').html GhostPost.username
    $('#avatarImageSmall').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'
    $('html, body').scrollTop $(document).height()

  postMessage: fnThrottle 750, ->
    name = $("#nameInput").val()
    text = $("#messageInput").val()
    if text
      if text.length > 200
          alert 'Whoa there! Max message length is around 140.9 chars.'
      else
        @messagesRef.push
          name: GhostPost.username
          avatar_id: GhostPost.avatar_id
          text: text
          created_at: Date.now()
    if window.webkitNotifications
      window.webkitNotifications.requestPermission() unless window.webkitNotifications.checkPermission() == 0
    $("#messageInput").val ""
    $("#messageInput").blur

  getMessages: ->
    # Get a reference to the root of the chat data.
    self = @
    @messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)

    @messagesRef.child('name').set(GhostPost.room)
    console.log 'set(GhostPost.room', GhostPost.room

    GhostPost.joined_at = Date.now()

    # When the user presses enter on the message input, write the message to firebase.
    $("#messageInput").keypress (e) ->
      if e.keyCode is 13
        self.postMessage()
    # Add a callback that is triggered for each chat message.
    @messagesRef.limit(30).on "child_added", (snapshot) ->
      message = snapshot.val()
      if (message.created_at > GhostPost.joined_at) && message.name != GhostPost.username && window.webkitNotifications
        GhostPost.desktopNotify message
      if message.text
        message.time = humaneDate(new Date(message.created_at))
        $("#messagesDiv").append HandlebarsTemplates['messages/show']({ message })
        #Check if the user is idle - hasn't scrolled in x seconds
        if $(document).scrollTop()  > $(document).height() - ( 2* $(window).height() )
          console.log "scrolling because scrolltop ", $(document).scrollTop(), "> document.height - 2 * window.height", $(document).height() - ( 2* $(window).height() )
          $('html, body').scrollTop $(document).height()
        else
          console.log "NOT scrolling because scrolltop ", $(document).scrollTop(), "document.height", $(document).height(), "2 * window.height ", ( 2* $(window).height() )
        $('li[data-username="' + GhostPost.username + '"]').addClass('mine')

  desktopNotify: (data) ->
    havePermission = window.webkitNotifications.checkPermission()
    if havePermission is 0
      # 0 is PERMISSION_ALLOWED
      notification = window.webkitNotifications.createNotification("http://simple.ghostpost.io/assets/avatars" + GhostPost.avatar_id + '.png', "Ghost by " + data.name, data.text)
#      notification.onclick = ->
#        #window.open "http://stackoverflow.com/a/13328397/1269037"
#        notification.close()

      notification.show()
    else
      window.webkitNotifications.requestPermission()

  listRooms: ->
    roomsRef = new Firebase "https://ghostpost.firebaseio.com/rooms"
    roomsRef.limit(25).on "child_added", (snapshot) ->
      room = snapshot.val()
      $("#roomsDiv").append HandlebarsTemplates['rooms/show']({ room })

  resetAvatar: ->
      localStorage.removeItem("username")
      localStorage.removeItem("avatar_id")
      GhostPost.resetName = true
      GhostPost.initializeUser()


# Hashtag link processor helper
Handlebars.registerHelper 'messageText', (text) ->
  if typeof text != 'string'
    text = text.string
  text = Handlebars.Utils.escapeExpression text
  text = text.replace(///\s#([\w\d]+)\b///g, "<a target='_blank' href='http://ghostpost.io/$1'>#$1</a>")
  text = text.replace(///^#([\w\d]+)\b///g, "<a target='_blank' href='http://ghostpost.io/$1'>#$1</a>")
  return new Handlebars.SafeString(text);

# Live update times on the page every minute
timeResetInterval = ->
  times = $('.message-time')
  for span in times
    span = $(span)
    time = span.data('time')
    span.text(humaneDate(new Date(time)))
setInterval timeResetInterval, 60*1000

