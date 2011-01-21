$(function(){

    $('#input').focus()

    var socket = new Pusher( '<%= Pusher.key %>'); 

    socket.bind('pusher:connection_established', function (x) {
          $('#connected').text('connected');
          // alert(x.socket_id); // works
    });

    socket.bind('pusher:connection_disconnected', function(){
          $('#connected').text('diconnected');
    })

    socket.bind('pusher:connection_disconnected', function(){
           $('#users').empty();
    })

    var myPresenceChannel = socket.subscribe('presence-x');

      function addMember (member) {
                $('<li>').attr('id',member.user_id).append(member.user_info.name).appendTo('#users');
        }


    myPresenceChannel.bind('pusher:subscription_succeeded', function(members){
      // iterate through the members and add them into the DOM
            $.each(members, function (i, member) {  addMember(member) });
    })

    myPresenceChannel.bind('pusher:member_added', function(member){
            addMember(member);
    })

    myPresenceChannel.bind('pusher:member_removed', function(member){
      // remove this member from my list, or optionally redraw from myPresenceChannel.members()

        $('#users').find('#' + member.user_id).remove();

    })




});
