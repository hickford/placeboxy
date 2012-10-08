$(document).ready(function()
{
    if ($('#input').length)
    {
        $('#input').focus()
    }
    
    var pusher = new Pusher( '<%= Pusher.key %>'); 
    pusher.connection.bind('connected', function (x) {
          $('#connected').text('Real-time connection');
    });

    pusher.connection.bind('unavailable', function(){
          $('#connected').text('Real-time connection unavaliable');
    });
    
    pusher.connection.bind('disconnected', function(){
          $('#connected').text('Real-time disconnected');
    });

    pusher.connection.bind('connecting', function(){
          $('#connected').text('Attempting real-time connection');
    });

    var myPresenceChannel = pusher.subscribe('presence-x');

    function addMember (member) {
                $('<li>').attr('id',member.id).append(member.info.name).prependTo('#users').hide().slideDown();
        };

    myPresenceChannel.bind('pusher:subscription_succeeded', function(members){
      members.each(function(member) {
        addMember(member) });
    });

    myPresenceChannel.bind('pusher:member_added', function(member){
            addMember(member);
    });

    myPresenceChannel.bind('pusher:member_removed', function(member){
      // remove this member from my list, or optionally redraw from myPresenceChannel.members()
        $('#users').find('#' + member.user_id).remove();
    });

});
