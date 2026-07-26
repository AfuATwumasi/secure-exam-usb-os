const API_BASE = "http://127.0.0.1:5000";

document
.getElementById("loginForm")
.addEventListener("submit", async function(e){

    e.preventDefault();

    const username =
        document.getElementById("username").value;

    const password =
        document.getElementById("password").value;

    if(username === "" || password === ""){
        alert("Please enter username and password");
        return;
    }

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
