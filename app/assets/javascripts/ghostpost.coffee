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

    adjectives = ['Silly','Fuzzy','Crusty','Fat','Evil','Mad','Madest','Fat','Fatest','Dumb','Dumest','Worst','Saintly','Perverse','Wild','Wildest','Smelly','Smelliest','Crabby','Crabbiest','Annoying','Simple','Sadistic','Troubled','Ecstatic','Janky','Loopy','Snarky','Healthy','Tasty','Tricky','Ugly','Dirty','Terrible','Fugly','Crappy','Sweetest','Rude','Fair','Stoopid','Fast','Scrappy','Shallow','Average','Arrogant','Ashamed','Dizzy','Dull','Sarcastic','Hungry','Moaning','Modern','Icy','Proud','Mr.','Mrs.','Stingy','Smal','Tall','Large','Little','Big','Frantic','Petite','Prickly','Jealous','Ordinary','Obnoxious','Energetic','Wicked','Wet','Witty','Biggie','Smokey','Interesting','Funky']
    nouns = ['Hipster','Soap','Spork','Bunny','Jock','Foot','Elbow','Cat','Hippopotamus','Sloth','Mormon','Child','Atheist','Pope','Whore','Platypus','Iguana','Walrus','Dolphin','Blunderbuss','Fritatta','Flapjack','Dumbo','Meanie','Crab','Dungeon','Temple','Ninja','Wombat','Pirate','Motel','Buccaneer','Didgeridoo','Girdle','Manscape','Weasel','Chimpanzee','Poltergeist','Boar','Pilot','Taco','Burrito','Flauta','Hamburger','Cheeseburger','Pancake','Kangaroo','Dog','Feline','Troll','Hacker','Taint','Manchild','Elephant','Asshat','Ass','Donkey','Horse','Cow','Duck','Pig','Giraffe','Lion','Book','Phone','Desk','Dentist','Doctor','Comedian','CEO','Startup','Bus','Car','Spork','T-Rex','Dino','President','Lop','Mop','Flipflop','Booger','Name','Dingo','Toe Jam','Wafer','Sasquatch','Lampshade','Monster','Wolfboy','Raccoon','Oatmeal','Muffin','Hoarder','Hipster','Melon','Goat','Sweatervest','Horsemeat','Centaur','Meatloaf','Lasagna','Magician','Samurai','Lemur','Empanada','Goatboy','Cat Lady','Armpit','Delivery','Pill','Handbag','Mitten','Pimp Cup','Redneck','Engrish','Cabbie','Sushi','Celebutante','LoveLetter','Nymph']

    if (localStorage.username and localStorage.avatar_id) and (!GhostPost.resetName)
      GhostPost.username = localStorage.username
      GhostPost.avatar_id = localStorage.avatar_id
      GhostPost.avatar_url = localStorage.avatar_url
      console.log 'User localStorage acknolwedged - reusing old avatar ', GhostPost.username, GhostPost.avatar_id
    else
      # create new avatar / image
      console.log 'Could not find localStorage - creating new user/avatar'
      GhostPost.username = adjectives[Math.floor(Math.random()*adjectives.length)] + nouns[Math.floor(Math.random()*nouns.length)]
      GhostPost.avatar_id = Math.floor(Math.random()*24) + 1
      GhostPost.avatar_url = '/assets/avatars/av' + GhostPost.avatar_id + '.png'
      localStorage.username = GhostPost.username
      localStorage.avatar_id = GhostPost.avatar_id
      localStorage.avatar_url = GhostPost.avatar_url

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
    prepSnapshotForRender = (snapshot) ->
      id = snapshot.Yb.path.m[2]
      messageSnapshots[id] = snapshot
      message = snapshot.val()
      message.id = id
      if message.text
        message.time = humaneDate(new Date(message.created_at))
      message

    @messagesRef.on "child_changed", (snapshot) ->
      message = prepSnapshotForRender(snapshot)
      console.log(message)
      elt = $(HandlebarsTemplates['messages/show']({ message }))
      $('#' + message.id).replaceWith(elt)
      attachVotingHandlers elt

    @messagesRef.limit(30).on "child_added", (snapshot) ->
      message = prepSnapshotForRender(snapshot)
      votes[message.id] = false
      if (message.created_at > GhostPost.joined_at) && message.name != GhostPost.username && window.webkitNotifications
        GhostPost.desktopNotify message
      # Render the message and store the snapshot on the dom elt
      elt = $(HandlebarsTemplates['messages/show']({ message }))
      $("#messagesDiv").append elt
      attachVotingHandlers elt
      $('html, body').scrollTop $(document).height()
      $('li[data-username=' + GhostPost.username + ']').addClass('mine')

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
    roomsRef.limit(10).on "child_added", (snapshot) ->
      room = snapshot.val()
      $("#roomsDiv").append HandlebarsTemplates['rooms/show']({ room })

  resetAvatar: ->
      localStorage.removeItem("username")
      localStorage.removeItem("avatar_id")
      GhostPost.resetName = true
      GhostPost.initializeUser()

  welcomeAvatar: ->
    $("#welcomeAvatar").html HandlebarsTemplates['home/avatarLarge']({ GhostPost })

# Vote handling
messageSnapshots = {}
votes = {}
vote = (elt, value) ->
  id = elt.data('id')
  if ! votes[id]
    votes[id] = value
    ref = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room + '/' + id)
    ref.update {score: (messageSnapshots[id].val().score || 0) + value}

attachVotingHandlers = (elt) ->
  up = elt.find('.upvote')
  id = up.data('id')
  up.on 'click', (evt) ->
    elt = $ evt.currentTarget
    vote(elt, 1)

  down = elt.find('.downvote')
  down.on 'click', (evt) ->
    elt = $ evt.currentTarget
    vote(elt, -1)
  if votes[id]
    if votes[id] > 0
      up.css('opacity', 1)
      down.hide()
    else
      down.css('opacity', 1)
      up.hide()

# Hashtag link processor helper
Handlebars.registerHelper 'messageText', (text) ->
  if text
    if typeof text != 'string'
      text = text.string
    text = Handlebars.Utils.escapeExpression text
    text = text.replace(///\s#([\w\d]+)\b///g, "<a target='_blank' href='http://ghostpost.io/$1'>#$1</a>")
    text = text.replace(///^#([\w\d]+)\b///g, "<a target='_blank' href='http://ghostpost.io/$1'>#$1</a>")
    return new Handlebars.SafeString(text);
  text

# Live update times on the page every minute
timeResetInterval = ->
  times = $('.message-time')
  for span in times
    span = $(span)
    time = span.data('time')
    span.text(humaneDate(new Date(time)))
setInterval timeResetInterval, 60*1000

