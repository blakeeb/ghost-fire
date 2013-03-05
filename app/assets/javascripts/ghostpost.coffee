window.GhostPost =


  start: ->

    # Get a reference to the root of the chat data.
    messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)

    adjectives = ['Silly','Fuzzy','Crusty','Fat','Evil']
    nouns = ['Hipster','Soap','Spork','Bunny','Jock','Foot','Elbow']

    # onboard user - either create new or reuse old avatar.

    if localStorage.username and localStorage.avatar_id
      GhostPost.username = localStorage.username
      GhostPost.avatar_id = localStorage.avatar_id
      console.log 'User localStorage acknolwedged - reusing old avatar ', GhostPost.username, GhostPost.avatar_id

    else
      # create new avatar / image
      console.log 'Could not find localStorage - creating new user/avatar'
      GhostPost.username = adjectives[Math.floor(Math.random()*adjectives.length)] + nouns[Math.floor(Math.random()*nouns.length)]
      GhostPost.avatar_id = Math.floor(Math.random()*25)
      localStorage.username = GhostPost.username
      localStorage.avatar_id = GhostPost.avatar_id


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
      $("#messagesDiv")[0].scrollTop = $("#messagesDiv")[0].scrollHeight



    # presence management

    # Presence for the User
    presenceRef = new Firebase 'https://ghostpost.firebaseio.com/' + GhostPost.username + '/online'
    # Make sure if I lose my connection I am marked as offline.
    presenceRef.onDisconnect().set(false);
    # Now, mark myself as online.
    presenceRef.set(true);

    # Create an alert when entering or leaving a room
    connectedRef = new Firebase("https://ghostpost.firebaseio.com/.info/connected")
    connectedRef.on "value", (snap) ->
    if snap.val() is true
      alert "connected to ", GhostPost.room
    else
      alert "disconnected from ", GhostPost.room

