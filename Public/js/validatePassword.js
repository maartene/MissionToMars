var myInput = document.getElementById("password");
var repeat = document.getElementById("passwordRepeat");
var letter = document.getElementById("letter");
var capital = document.getElementById("capital");
var number = document.getElementById("number");
var length = document.getElementById("length");
var saveButton = document.getElementById("saveButton")

var previousFocus = ""

myInput.onkeyup = validate
repeat.onkeyup = validate

// When the user starts to type something inside the password field
function validate() {
    // Validate match
    var result = true;

    if(myInput.value == repeat.value) {
        match.classList.remove("text-warning");
        match.classList.add("text-success");
    } else {
        match.classList.remove("text-success");
        match.classList.add("text-warning");
        result = false;
    }

  // Validate lowercase letters
  var lowerCaseLetters = /[a-z]/g;
  if(myInput.value.match(lowerCaseLetters)) { 
    letter.classList.remove("text-warning");
    letter.classList.add("text-success");
  } else {
    letter.classList.remove("text-success");
    letter.classList.add("text-warning");
    result = false;
}

  // Validate capital letters
  var upperCaseLetters = /[A-Z]/g;
  if(myInput.value.match(upperCaseLetters)) { 
    capital.classList.remove("text-warning");
    capital.classList.add("text-success");
  } else {
    capital.classList.remove("text-success");
    capital.classList.add("text-warning");
    result = false;
  }

  // Validate numbers
  var numbers = /[0-9]/g;
  if(myInput.value.match(numbers)) { 
    number.classList.remove("text-warning");
    number.classList.add("text-success");
  } else {
    number.classList.remove("text-success");
    number.classList.add("text-warning");
    result = false;
  }

  // Validate length
  if(myInput.value.length >= 8) {
    length.classList.remove("text-warning");
    length.classList.add("text-success");
  } else {
    length.classList.remove("text-warning");
    length.classList.add("text-success");
    result = false;
  }

    if (result == false) {
        saveButton.classList.add("disabled");
    } else {
        saveButton.classList.remove("disabled");
    }
}