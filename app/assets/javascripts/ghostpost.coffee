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

  hideWelcomeScreen: ->
    localStorage.hasVisited = 'true'
    $('.welcome').hide()
    $('.postbar').show()

  initializeUser: ->
    if GhostPost.isNewUser()
      $('.welcome').show()
      $('.postbar').hide()
      $('.welcome button').bind 'click', @hideWelcomeScreen
      $('.welcome button').bind 'ontouchstart', @hideWelcomeScreen

    # onboard user - either create new or reuse old avatar.

    adjectives = ['Silly','Fuzzy','Crusty','Fat','Evil','Mad','Madest','Fat','Fatest','Dumb','Dumest','Worst','Saintly','Perverse','Wild','Wildest','Smelly','Smelliest','Crabby','Crabbiest','Annoying','Simple','Sadistic','Troubled','Ecstatic','Janky','Loopy','Snarky','Healthy','Tasty','Tricky','Ugly','Dirty','Terrible','Fugly','Crappy','Sweetest','Rude','Fair','Stoopid','Fast','Scrappy','Shallow','Average','Arrogant','Ashamed','Dizzy','Dull','Sarcastic','Hungry','Moaning','Modern','Icy','Proud','Mr.','Mrs.','Stingy','Smal','Tall','Large','Little','Big','Frantic','Petite','Prickly','Jealous','Ordinary','Obnoxious','Energetic','Wicked','Wet','Witty','Biggie','Smokey','Interesting','Funky']
    nouns = ['Hipster','Soap','Spork','Bunny','Jock','Foot','Elbow','Cat','Hippopotamus','Sloth','Mormon','Child','Atheist','Pope','Whore','Platypus','Iguana','Walrus','Dolphin','Blunderbuss','Fritatta','Flapjack','Dumbo','Meanie','Crab','Dungeon','Temple','Ninja','Wombat','Pirate','Motel','Buccaneer','Didgeridoo','Girdle','Manscape','Weasel','Chimpanzee','Poltergeist','Boar','Pilot','Taco','Burrito','Flauta','Hamburger','Cheeseburger','Pancake','Kangaroo','Dog','Feline','Troll','Hacker','Taint','Manchild','Elephant','Asshat','Ass','Donkey','Horse','Cow','Duck','Pig','Giraffe','Lion','Book','Phone','Desk','Dentist','Doctor','Comedian','CEO','Startup','Bus','Car','Spork','T-Rex','Dino','President','Lop','Mop','Flipflop','Booger','Name','Dingo','Toe Jam','Wafer','Sasquatch','Lampshade','Monster','Wolfboy','Raccoon','Oatmeal','Muffin','Hoarder','Hipster','Melon','Goat','Sweatervest','Horsemeat','Centaur','Meatloaf','Lasagna','Magician','Samurai','Lemur','Empanada','Goatboy','Cat Lady','Armpit','Delivery','Pill','Handbag','Mitten','Pimp Cup','Redneck','Engrish','Cabbie','Sushi','Celebutante','LoveLetter','Nymph', 'Scoble','McClure','Zuckerberg']

    if (localStorage.username and localStorage.avatar_id) and (!GhostPost.resetName)
      GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you = localStorage.username
      GhostPost.avatar_id = localStorage.avatar_id
    else
      # create new avatar / image
      GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you = adjectives[Math.floor(Math.random()*adjectives.length)] + nouns[Math.floor(Math.random()*nouns.length)]
      GhostPost.avatar_id = Math.floor(Math.random()*24) + 1
      localStorage.username = GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you
      localStorage.avatar_id = GhostPost.avatar_id

      # Display new Avatar Message and image on the screen
      $("#avatarNotificationDiv").html HandlebarsTemplates['messages/avatarNotification']({ GhostPost })

    # Commenting this out as we now append the new Ghostpost
    $('#avatarName').html GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you
    $('#avatarImage').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'
    $('#avatarNameSmall').html GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you
    $('#avatarImageSmall').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'
    $('html, body').scrollTop $(document).height()

  postMessage: fnThrottle 750, ->
    name = $("#nameInput").val()
    text = $("#messageInput").val()
    if text
      if text.length > 300
          alert 'Whoa there! Max message length is around 140.9 chars.'
      else
        @messagesRef.push
          name: GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you
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

    GhostPost.joined_at = Date.now()

    # When the user presses enter on the message input, write the message to firebase.
    $("#messageInput").keypress (e) ->
      if e.keyCode is 13
        self.postMessage()
    # Add a callback that is triggered for each chat message.
    @messagesRef.limit(30).on "child_added", (snapshot) ->
      message = snapshot.val()
      if (message.created_at > GhostPost.joined_at) && message.name != GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you && window.webkitNotifications
        GhostPost.desktopNotify message
      if message.text
        message.time = humaneDate(new Date(message.created_at))
        $("#messagesDiv").append HandlebarsTemplates['messages/show']({ message })
        #Check if the user is idle - hasn't scrolled in x seconds
        if $(document).scrollTop()  > $(document).height() - ( 2* $(window).height() )
          $('html, body').scrollTop $(document).height()
        $('li[data-username="' + GhostPost.please_have_some_respect_dont_hack_us_weve_only_been_around_five_days_thx_we_love_you + '"]').addClass('mine')

  desktopNotify: (data) ->
    havePermission = window.webkitNotifications.checkPermission()
    if havePermission is 0
      # 0 is PERMISSION_ALLOWED
      notification = window.webkitNotifications.createNotification("http://ghostpost.io/assets/avatars/av" + GhostPost.avatar_id + '.png', "Ghost by " + data.name, data.text)

      notification.show()
    else
      window.webkitNotifications.requestPermission()

  listRooms: ->
    roomsRef = new Firebase "https://ghostpost.firebaseio.com/rooms"
    roomsRef.limit(25).on "child_added", (snapshot) ->
      room = snapshot.val()
      $("#roomsDiv").append HandlebarsTemplates['rooms/show']({ room })

  isNewUser: ->
    localStorage.hasVisited != 'true'

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
  text = text.replace(///\s#([\w\d]+)\b///g, "<a target='_blank' href='http://ghostpost.io/$1' class='messageLink'>#$1</a>")
  text = text.replace(///^#([\w\d]+)\b///g, "<a target='_blank' href='http://ghostpost.io/$1' class='messageLink'>#$1</a>")
  return new Handlebars.SafeString(text);

# Live update times on the page every minute
timeResetInterval = ->
  times = $('.message-time')
  for span in times
    span = $(span)
    time = span.data('time')
    span.text(humaneDate(new Date(time)))
setInterval timeResetInterval, 60*1000


chatRef = new Firebase('https://ghostpost.firebaseio.com');
authClient = new FirebaseAuthClient chatRef, (error, user) ->
  if error
    # an error occurred while attempting login
    console.log error
  else if user
    # user authenticated with Firebase
    $('body').data 'user-id', user.id
    $('#facebook-login').hide();
    $('#facebook-share').show();
  else
    # user is logged out

# Facebook
$(document).ready ->
  $('#facebook-login').click ->
    authClient.login 'facebook', 
      rememberMe: true
      scope: 'email'
    
