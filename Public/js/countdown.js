var countdownLabel = document.getElementById("countdown");

var secondsToGo = document.getElementById("countdownValue").value;
var endDate = new Date().getTime() + secondsToGo * 1000;

update()

function update() {
    var now = new Date().getTime();

    // Find the distance between now and the count down date
    var distance = endDate - now;

    //console.log("Distance: " + distance);

    var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
    var seconds = Math.floor((distance % (1000 * 60)) / 1000);

    // Display the result in the element with id="demo"
    countdownLabel.innerHTML = minutes + "m " + seconds + "s ";

    // If the count down is finished, write some text 
    if (distance < 0) {
       window.location.reload()
    }
}

var x = setInterval(update, 1000)