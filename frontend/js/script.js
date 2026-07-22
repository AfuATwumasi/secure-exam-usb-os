// ==============================
// API CONFIG
// ==============================

const API_BASE = "http://127.0.0.1:5000";

// ==============================
// ROLE SELECT (Login Page)
// ==============================

const roles = document.querySelectorAll(".role");
const submitBtn = document.getElementById("submitBtn");

let currentRole = "student";

roles.forEach(button => {
  button.addEventListener("click", () => {
    roles.forEach(btn => btn.classList.remove("active"));
    button.classList.add("active");
    currentRole = button.dataset.role;
    if (submitBtn) {
      submitBtn.textContent = `Sign In as ${capitalize(currentRole)}`;
    }
  });
});

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

    const email = document.getElementById("email").value;
    const password = document.getElementById("password").value;

    try {
      const response = await fetch(`${API_BASE}/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: email,
          password: password,
          role: currentRole,
        }),
      });

      const data = await response.json();

      if (response.ok) {
        localStorage.setItem("user", email);
        localStorage.setItem("role", currentRole);

        // Route to appropriate dashboard
        if (currentRole === "admin") {
          window.location.href = "admin-dashboard.html";
        } else {
          window.location.href = "dashboard.html";
        }
      } else {
        alert(data.message);
      }
    } catch (error) {
      console.log(error);
      alert("Server connection failed");
    }
  });
}

// ==============================
// DISPLAY USERNAME
// ==============================

const username = localStorage.getItem("user");
const usernameElement = document.getElementById("username");

if (username && usernameElement) {
  usernameElement.textContent = username;
}

// ==============================
// LOGOUT
// ==============================

function logout() {
  localStorage.removeItem("user");
  localStorage.removeItem("role");
  window.location.href = "login.html";
}

// ==============================
// EXAM MODAL
// ==============================

function openModal() {
  const modal = document.getElementById("examModal");
  if (modal) modal.style.display = "flex";
}

function closeModal() {
  const modal = document.getElementById("examModal");
  if (modal) modal.style.display = "none";
}

function verifyCode() {
  alert("Code Verified!");
  closeModal();
}

// ==============================
// DASHBOARD — Load exams from backend
// ==============================

async function loadDashboard() {
  const examGrids = document.querySelectorAll(".exam-grid");
  if (!examGrids.length) return; // not on dashboard page

  try {
    const response = await fetch(`${API_BASE}/dashboard`);
    const data = await response.json();

    if (data.exams && data.exams.length > 0) {
      // Update the first exam grid with dynamic data
      const grid = examGrids[0];
      grid.innerHTML = "";

      data.exams.forEach((exam, index) => {
        const colors = ["blue", "purple", "gray", "yellow"];
        const colorClass = colors[index % colors.length];

        const card = document.createElement("div");
        card.classList.add("exam-card");
        card.innerHTML = `
          <div class="card-top ${colorClass}"></div>
          <div class="card-content">
            <h4>${exam.title}</h4>
            <p>${exam.description}</p>
            <p class="exam-info">
              ${exam.question_count} Questions • ${exam.duration_minutes} mins • Pass: ${exam.pass_mark}%
            </p>
            <button class="enter-btn" onclick="startExam('${exam.id}', '${exam.title}')">
              Enter Exam
            </button>
          </div>
        `;
        grid.appendChild(card);
      });
    }
  } catch (error) {
    console.error("Failed to load dashboard:", error);
  }
}

// ==============================
// START EXAM — Navigate to exam page
// ==============================

function startExam(examId, examTitle) {
  localStorage.setItem("examId", examId);
  localStorage.setItem("examTitle", examTitle);
  window.location.href = "exam.html";
}

// ==============================
// AUTO-LOAD DASHBOARD ON PAGE LOAD
// ==============================

document.addEventListener("DOMContentLoaded", loadDashboard);
