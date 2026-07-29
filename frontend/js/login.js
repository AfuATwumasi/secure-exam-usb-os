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

    try{
        const response = await fetch(`${API_BASE}/login`,{
            method:"POST",
            headers:{
                "Content-Type":"application/json"
            },
            body:JSON.stringify({
                email: email,
                password: password,
                role: "admin"
            })
        });

        const data = await response.json();

        if(response.ok){
            localStorage.setItem("user", email);
            localStorage.setItem("role", "admin");
            window.location.href = "dashboard.html";
        }else{
            alert(data.message || "Login failed");
        }

    }catch(error){
        console.error(error);
        alert("Unable to connect to the backend.");
    }
});
</｜｜DSML｜｜>
</write_to_file>