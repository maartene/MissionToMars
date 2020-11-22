var usernameInput = document.getElementById("usernameInput");
var usernameValidation = document.getElementById("usernameValidation");
var deleteButton = document.getElementById("deleteButton")

usernameInput.onkeyup = usernameValidate

// When the user starts to type something inside the password field
function usernameValidate() {
    // Validate match
    var result = (usernameInput.value == usernameValidation.value)

    if (result == false) {
        deleteButton.classList.add("disabled");
    } else {
        deleteButton.classList.remove("disabled");
    }
}