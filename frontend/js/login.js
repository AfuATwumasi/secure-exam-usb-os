const API_BASE = "http://127.0.0.1:5000";

document
.getElementById("loginForm")
.addEventListener("submit", async function(e){

    e.preventDefault();

    const email = document.getElementById("email").value.trim();
    const password = document.getElementById("password").value.trim();

    if(email === "" || password === ""){
        alert("Please enter email and password");
        return;
    }

<<<<<<< HEAD
    try {
        const response = await fetch(`${API_BASE}/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                email: username,
                password: password,
                role: "admin"
            }),
        });

        const data = await response.json();

        if (response.ok) {
            localStorage.setItem("user", username);
            localStorage.setItem("role", "admin");
            window.location.href = "dashboard.html";
        } else {
            alert(data.message || "Login failed");
        }
    } catch (error) {
        console.error("Login failed:", error);
        alert("Server connection failed. Is the backend running?");
    }
});
=======
    try{

        const response = await fetch("http://127.0.0.1:5000/login",{

            method:"POST",

            headers:{
                "Content-Type":"application/json"
            },

            body:JSON.stringify({
                email,
                password
            })

        });

        const data = await response.json();

        if(response.ok){
            alert(data.message);
            window.location.href = "dashboard.html";
        }else{
            alert(data.message);
        }

    }catch(error){

        console.error(error);
        alert("Unable to connect to the backend.");

    }

});
>>>>>>> ac0ed2d (Update frontend files for secure exam OS)
