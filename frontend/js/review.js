// GET DATA
const answers =
JSON.parse(localStorage.getItem("examAnswers"));

const questions =
JSON.parse(localStorage.getItem("examQuestions"));

const reviewList =
document.getElementById("review-list");

let answeredCount = 0;

// SHOW ANSWERS
questions.forEach((q,index) => {

  const card =
  document.createElement("div");

  card.classList.add("review-card");

  const userAnswer =
  answers[index];

  if(userAnswer){
    answeredCount++;
  }

  card.innerHTML = `

    <div class="question">
      Question ${index + 1}
    </div>

    <p>
      ${q.question}
    </p>

    <div class="answer">

      ${
        userAnswer
        ?
        `<span class="correct">
          Your Answer:
          ${userAnswer}
        </span>`
        :
        `<span class="unanswered">
          Not Answered
        </span>`
      }

    </div>

  `;

  reviewList.appendChild(card);

});

// COUNTS
document.getElementById("answered").innerText =
`${answeredCount}/${questions.length}`;

document.getElementById("unanswered").innerText =
questions.length - answeredCount;

// BACK
function goBack(){

  window.location.href = "exam.html";

}

// FINAL SUBMIT
function finalSubmit(){

  // LATER:
  // SEND TO BACKEND

  alert("Exam Submitted Successfully!");

  // CLEAR STORAGE
  localStorage.removeItem("examAnswers");

  localStorage.removeItem("examQuestions");

  // GO TO DASHBOARD
  window.location.href = "dashboard.html";

}