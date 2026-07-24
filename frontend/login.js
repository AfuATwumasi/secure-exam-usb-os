document
.getElementById("loginForm")
.addEventListener("submit", function(e){

    e.preventDefault();

    const username =
        document.getElementById("username").value;

    const password =
        document.getElementById("password").value;

    if(username === "" || password === ""){
        alert("Please enter username and password");
        return;
    }

    alert("Login Successful");

    // Later:
    // connect to Flask backend

    // window.location.href = "dashboard.html";
});