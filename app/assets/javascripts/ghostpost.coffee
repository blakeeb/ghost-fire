window.GhostPost =
  username: ''
  avatar_id: 1
  start: ->
    # Get a reference to the root of the chat data.
    messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)

    adjectives = ['Silly','Fuzzy','Crusty','Fat','Evil','Mad','Madest','Fat','Fatest','Dumb','Dumest','Worst','Saintly','Perverse','Wild','Wildest','Smelly','Smelliest','Crabby','Crabbiest','Annoying','Simple','Sadistic','Troubled','Ecstatic','Janky','Loopy','Snarky','Healthy','Tasty','Tricky','Ugly','Dirty','Terrible','Fugly','Crappy','Sweetest','Rude','Fair','Stoopid','Fast','Gay','Not-gay','Scrappy','Shallow','Average','Arrogant','Ashamed','Dizzy','Dull','Sarcastic','Hungry','Moaning','Modern','Icy','Proud','Mr.','Mrs.','Stingy','Smal','Tall','Large','Little','Big','Frantic','Petite','Prickly','Jealous','Ordinary','Obnoxious','Energetic','Wicked','Wet','Witty','Biggie','Smokey','Interesting','Funky']
    nouns = ['Hipster','Soap','Spork','Bunny','Jock','Foot','Elbow','Cat','Hippopotamus','Sloth','Mormon','Child','Atheist','Pope','Whore','Platypus','Iguana','Walrus','Dolphin','Blunderbuss','Fritatta','Flapjack','Dumbo','Meanie','Crab','Dungeon','Temple','Ninja','Wombat','Pirate','Motel','Buccaneer','Didgeridoo','Girdle','Manscape','Weasel','Chimpanzee','Poltergeist','Boar','Pilot','Taco','Burrito','Flauta','Hamburger','Cheeseburger','Pancake','Kangaroo','Dog','Feline','Troll','Hacker','Taint','Manchild','Elephant','Asshat','Ass','Donkey','Horse','Cow','Duck','Pig','Giraffe','Lion','Book','Phone','Desk','Dentist','Doctor','Comedian','CEO','Startup','Bus','Car','Spork','T-Rex','Dino','President','Lop','Mop','Flipflop','Booger','Name','Dingo','Toe Jam','Wafer','Sasquatch','Lampshade','Monster','Wolfboy','Raccoon','Oatmeal','Muffin','Hoarder','Hipster','Melon','Goat','Sweatervest','Horsemeat','Centaur','Meatloaf','Lasagna','Magician','Samurai','Lemur','Empanada','Goatboy','Cat Lady','Armpit','Delivery','Pill','Handbag','Mitten','Pimp Cup','Redneck','Engrish','Cabbie','Sushi','Celebutante','Love Letter','Nymph']

    # onboard user - either create new or reuse old avatar.
    console.log 'About to start the onboarding process'

    username = getCookie("username")
    avatar_id = getCookie("avatar_id")

    if username? and username isnt "" and avatar_id? and avatar_id isnt ""
      GhostPost.username = username
      GhostPost.avatar_id = avatar_id
      console.log 'User cookie acknolwedged - reusing old avatar ', username, avatar_id

    else
      # create new avatar / image
      GhostPost.username = adjectives[Math.floor(Math.random()*adjectives.length)] + nouns[Math.floor(Math.random()*nouns.length)]
      GhostPost.avatar_id = Math.floor(Math.random()*25)
      setCookie "username", GhostPost.username, 1  if username? and username isnt ""
      setCookie "avatar_id", GhostPost.avatar_id, 1  if username? and username isnt ""

    # Display avatarname and image on the screen
    $('#avatarName').html GhostPost.username
    $('#avatarImage').attr 'src', '/assets/avatars/av' + GhostPost.avatar_id + '.png'

    # When the user presses enter on the message input, write the message to firebase.
    $("#messageInput").keypress (e) ->
      if e.keyCode is 13
        name = $("#nameInput").val()
        text = $("#messageInput").val()
        if text
          messagesRef.push
            name: GhostPost.username
            avatar_id: GhostPost.avatar_id
            text: text

        $("#messageInput").val ""

    # Add a callback that is triggered for each chat message.
    messagesRef.limit(30).on "child_added", (snapshot) ->
      message = snapshot.val()
      $("<div/>").text(message.text).prepend($("<em/>").text(message.name + ": ")).appendTo $("#messagesDiv")
      $(".posts")[0].scrollTop = $(".posts")[0].scrollHeight + 50


# Support functions for cookie processing

getCookie = (c_name) ->
  i = undefined
  x = undefined
  y = undefined
  ARRcookies = document.cookie.split(";")
  i = 0
  while i < ARRcookies.length
    x = ARRcookies[i].substr(0, ARRcookies[i].indexOf("="))
    y = ARRcookies[i].substr(ARRcookies[i].indexOf("=") + 1)
    x = x.replace(/^\s+|\s+$/g, "")
    return unescape(y)  if x is c_name
    i++

setCookie = (c_name, value, exdays) ->
  exdate = new Date()
  exdate.setDate exdate.getDate() + exdays
  c_value = escape(value) + ((if (not (exdays?)) then "" else "; expires=" + exdate.toUTCString()))
  document.cookie = c_name + "=" + c_value
