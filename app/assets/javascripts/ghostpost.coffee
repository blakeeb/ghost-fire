window.GhostPost =
  username: ''
  start: ->
    # Get a reference to the root of the chat data.
    messagesRef = new Firebase("https://ghostpost.firebaseio.com/rooms/" + GhostPost.room)

    adjectives = ['Silly','Fuzzy','Crusty','Fat','Evil']
    nouns = ['Hipster','Soap','Spork','Bunny','Jock','Foot','Elbow']
    GhostPost.username = adjectives[Math.floor(Math.random()*adjectives.length)] + nouns[Math.floor(Math.random()*nouns.length)]

    # When the user presses enter on the message input, write the message to firebase.
    $("#messageInput").keypress (e) ->
      if e.keyCode is 13
        name = $("#nameInput").val()
        text = $("#messageInput").val()
        messagesRef.push
          name: GhostPost.username
          text: text

        $("#messageInput").val ""

    # Add a callback that is triggered for each chat message.
    messagesRef.limit(30).on "child_added", (snapshot) ->
      message = snapshot.val()
      $("<div/>").text(message.text).prepend($("<em/>").text(message.name + ": ")).appendTo $("#messagesDiv")
      $("#messagesDiv")[0].scrollTop = $("#messagesDiv")[0].scrollHeight
