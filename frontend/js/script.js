const roles = document.querySelectorAll(".role");
const submitBtn = document.getElementById("submitBtn");

let currentRole = "student";

roles.forEach(button => {
  button.addEventListener("click", () => {

    // Remove active from all
    roles.forEach(btn => btn.classList.remove("active"));

    // Add active to clicked
    button.classList.add("active");

    // Update role
    currentRole = button.dataset.role;

    // Update button text
    submitBtn.textContent = `Sign In as ${capitalize(currentRole)}`;
  });
});

// Capitalize helper
function capitalize(word) {
  return word.charAt(0).toUpperCase() + word.slice(1);
}

// Form submission
document.getElementById("loginForm").addEventListener("submit", function(e) {
  e.preventDefault();

  const email = document.getElementById("email").value;
  const password = document.getElementById("password").value;

  console.log("Role:", currentRole);
  console.log("Email:", email);
  console.log("Password:", password);

  alert(`Logging in as ${capitalize(currentRole)}`);
});