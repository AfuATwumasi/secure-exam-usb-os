const roles = document.querySelectorAll(".role");
const submitBtn = document.getElementById("submitBtn");

let currentRole = "student";

roles.forEach(button => {

  button.addEventListener("click", () => {

    // Remove active class
    roles.forEach(btn => btn.classList.remove("active"));

    // Add active class
    button.classList.add("active");

    // Update role
    currentRole = button.dataset.role;

    // Update button text
    if (submitBtn) {
      submitBtn.textContent =
        `Sign In as ${capitalize(currentRole)}`;
    }

  });

});

// ==============================
// CAPITALIZE HELPER
// ==============================

function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}

// ==============================
// LOGIN FORM
// ==============================

const loginForm = document.getElementById("loginForm");

if (loginForm) {

  loginForm.addEventListener("submit", async function(e) {

  e.preventDefault();

  const email =
    document.getElementById("email").value;

  const password =
    document.getElementById("password").value;

  try {

    // SEND TO BACKEND
    const response = await fetch(
      "http://localhost:5000/login",
      {

        method: "POST",

        headers: {
          "Content-Type": "application/json"
        },

        body: JSON.stringify({
          email: email,
          password: password,
          role: currentRole
        })

      }
    );

    // CONVERT RESPONSE
    const data = await response.json();

    console.log(data);

    // SUCCESS
    if(response.ok){

      // SAVE USER
      localStorage.setItem("user", email);

      // REDIRECT
      window.location.href =
        "dashboard.html";

    }

    // FAILED LOGIN
    else{

      alert(data.message);

    }

  }

  catch(error){

    console.log(error);

    alert("Server connection failed");

  }

});

}

// ==============================
// DISPLAY USERNAME
// ==============================

const username = localStorage.getItem("user");

const usernameElement =
  document.getElementById("username");

if (username && usernameElement) {

  usernameElement.textContent = username;

}

// ==============================
// LOGOUT
// ==============================

function logout() {

  localStorage.removeItem("user");

  window.location.href = "login.html";

}

// ==============================
// EXAM MODAL
// ==============================

function openModal() {

  const modal =
    document.getElementById("examModal");

  if (modal) {
    modal.style.display = "flex";
  }

}

function closeModal() {

  const modal =
    document.getElementById("examModal");

  if (modal) {
    modal.style.display = "none";
  }

}

// ==============================
// VERIFY EXAM CODE
// ==============================

function verifyCode() {

  alert("Code Verified!");

  closeModal();

}