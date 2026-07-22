// API CONFIG
const API_BASE = "http://127.0.0.1:5000";

// GET DATA FROM LOCAL STORAGE
const answers = JSON.parse(localStorage.getItem("examAnswers"));
const questions = JSON.parse(localStorage.getItem("examQuestions"));

const reviewList = document.getElementById("review-list");

let answeredCount = 0;

// SHOW ANSWERS
questions.forEach((q, index) => {
  const card = document.createElement("div");
  card.classList.add("review-card");

  const userAnswer = answers[index];

  if (userAnswer) {
    answeredCount++;
  }

  card.innerHTML = `
    <div class="question">Question ${index + 1}</div>
    <p>${q.question}</p>
    <div class="answer">
      ${
        userAnswer
          ? `<span class="correct">Your Answer: ${userAnswer}</span>`
          : `<span class="unanswered">Not Answered</span>`
      }
    </div>
  `;

  reviewList.appendChild(card);
});

// COUNTS
document.getElementById("answered").innerText = `${answeredCount}/${questions.length}`;
document.getElementById("unanswered").innerText = questions.length - answeredCount;

// BACK
function goBack() {
  window.location.href = "exam.html";
}

// FINAL SUBMIT — sends to backend
async function finalSubmit() {
  try {
    const response = await fetch(`${API_BASE}/submit`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        answers: answers,
        questions: questions,
      }),
    });

    const data = await response.json();

    if (response.ok) {
      alert(data.message || "Exam Submitted Successfully!");
    } else {
      alert(data.message || "Submission failed");
    }
  } catch (error) {
    console.error("Submission failed:", error);
    alert("Could not submit exam. Server may be offline.");
  }

  // CLEAR STORAGE
  localStorage.removeItem("examAnswers");
  localStorage.removeItem("examQuestions");

  // GO TO DASHBOARD
  window.location.href = "dashboard.html";
}
