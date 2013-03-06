window.GhostPost =
  start: ->
    # Get a reference to the root of the chat data.
    messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)
    GhostPost.joined_at = Date.now()

  initializeUser: ->
    # onboard user - either create new or reuse old avatar.

    adjectives = ['Silly','Fuzzy','Crusty','Fat','Evil','Mad','Madest','Fat','Fatest','Dumb','Dumest','Worst','Saintly','Perverse','Wild','Wildest','Smelly','Smelliest','Crabby','Crabbiest','Annoying','Simple','Sadistic','Troubled','Ecstatic','Janky','Loopy','Snarky','Healthy','Tasty','Tricky','Ugly','Dirty','Terrible','Fugly','Crappy','Sweetest','Rude','Fair','Stoopid','Fast','Scrappy','Shallow','Average','Arrogant','Ashamed','Dizzy','Dull','Sarcastic','Hungry','Moaning','Modern','Icy','Proud','Mr.','Mrs.','Stingy','Smal','Tall','Large','Little','Big','Frantic','Petite','Prickly','Jealous','Ordinary','Obnoxious','Energetic','Wicked','Wet','Witty','Biggie','Smokey','Interesting','Funky']
    nouns = ['Hipster','Soap','Spork','Bunny','Jock','Foot','Elbow','Cat','Hippopotamus','Sloth','Mormon','Child','Atheist','Pope','Whore','Platypus','Iguana','Walrus','Dolphin','Blunderbuss','Fritatta','Flapjack','Dumbo','Meanie','Crab','Dungeon','Temple','Ninja','Wombat','Pirate','Motel','Buccaneer','Didgeridoo','Girdle','Manscape','Weasel','Chimpanzee','Poltergeist','Boar','Pilot','Taco','Burrito','Flauta','Hamburger','Cheeseburger','Pancake','Kangaroo','Dog','Feline','Troll','Hacker','Taint','Manchild','Elephant','Asshat','Ass','Donkey','Horse','Cow','Duck','Pig','Giraffe','Lion','Book','Phone','Desk','Dentist','Doctor','Comedian','CEO','Startup','Bus','Car','Spork','T-Rex','Dino','President','Lop','Mop','Flipflop','Booger','Name','Dingo','Toe Jam','Wafer','Sasquatch','Lampshade','Monster','Wolfboy','Raccoon','Oatmeal','Muffin','Hoarder','Hipster','Melon','Goat','Sweatervest','Horsemeat','Centaur','Meatloaf','Lasagna','Magician','Samurai','Lemur','Empanada','Goatboy','Cat Lady','Armpit','Delivery','Pill','Handbag','Mitten','Pimp Cup','Redneck','Engrish','Cabbie','Sushi','Celebutante','LoveLetter','Nymph']

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

    # Display avatarname and image on the screen
    $('#avatarName').html GhostPost.username
    $('#avatarImage').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'


  getMessages: ->
    # Get a reference to the root of the chat data.
    messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)

    messagesRef.child('name').set(GhostPost.room)
    console.log 'set(GhostPost.room', GhostPost.room

    GhostPost.joined_at = Date.now()

    $('#avatarNameSmall').html GhostPost.username
    $('#avatarImageSmall').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'


    # When the user presses enter on the message input, write the message to firebase.
    $("#messageInput").keypress (e) ->
      if e.keyCode is 13
        name = $("#nameInput").val()
        text = $("#messageInput").val()
        if text
          if text.length > 200
              alert 'Whoa there! Max message length is around 140.9 chars.'
              $("#messageInput").val ""
              $("#messageInput").blur
          else
            messagesRef.push
              name: GhostPost.username
              avatar_id: GhostPost.avatar_id
              text: text
              created_at: Date.now()
        if window.webkitNotifications
          window.webkitNotifications.requestPermission() unless window.webkitNotifications.checkPermission() == 0
        $("#messageInput").val ""
        $("#messageInput").blur

    # Add a callback that is triggered for each chat message.
    messagesRef.limit(30).on "child_added", (snapshot) ->
      message = snapshot.val()
      if (message.created_at > GhostPost.joined_at) && message.name != GhostPost.username && window.webkitNotifications
        GhostPost.desktopNotify message
      if message.text
        $("#messagesDiv").append HandlebarsTemplates['messages/show']({ message })
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
    roomsRef.limit(25).on "child_added", (snapshot) ->
      room = snapshot.val()
      $("#roomsDiv").append HandlebarsTemplates['rooms/show']({ room })


