$(function(){

    $('#input').focus()

    var socket = new Pusher( '<%= Pusher.key %>'); 

    socket.bind('pusher:connection_established', function () {
        $('#connected').text('connected');
    });

    var myPresenceChannel = socket.subscribe('presence-x')

    myPresenceChannel.bind('pusher:subscription_succeeded', function(member_list){
      // iterate through the members and add them into the DOM
    })

    myPresenceChannel.bind('pusher:member_added', function(member){
      // add this member onto my list, or optionally redraw from myPresenceChannel.members()
    })

    myPresenceChannel.bind('pusher:member_removed', function(member){
      // remove this member from my list, or optionally redraw from myPresenceChannel.members()
    })

    socket.bind('pusher:connection_disconnected', function(){
      // clear the member list in the UI for consistency 
    })


});
