$(function(){

    $('#input').focus()

    var pusher = new Pusher( '<%= Pusher.key %>'); 
    pusher.bind('pusher:connection_established', function () {
        $('#connected').text('connected');
    });

});
