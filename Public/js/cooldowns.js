var countDownDate = new Date().getTime() + 60000;

var x = setInterval(function() {
    var now = new Date().getTime();

    var distance = countDownDate - now;
    //console.log("distance: "+distance);
    if (distance < 0) {
//        var countDownDate = new Date().getTime() + 60000;
        window.location.reload()
    }
}, 5000);