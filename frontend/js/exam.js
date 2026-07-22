// =====================================
// API CONFIG
// =====================================

const API_BASE =
"http://127.0.0.1:5000";


// =====================================
// QUESTIONS FROM BACKEND
// =====================================

let questions = [];


// =====================================
// EXAM STATE
// =====================================

let currentQuestion = 0;

let answers = {};

let flagged = [];


// =====================================
// ELEMENTS
// =====================================

const questionText =
document.getElementById("question-text");

const optionsContainer =
document.getElementById("options-container");

const currentQuestionText =
document.getElementById("current-question");

const totalQuestions =
document.getElementById("total-questions");

const questionGrid =
document.getElementById("question-grid");

const progress =
document.getElementById("progress");

const answeredCount =
document.getElementById("answered-count");

const flagBtn =
document.getElementById("flagBtn");

const timer =
document.getElementById("timer");


// =====================================
// FETCH QUESTIONS FROM BACKEND
// =====================================

async function fetchQuestions() {

  try {

    const response = await fetch(
      `${API_BASE}/questions`
    );

    const data =
    await response.json();

    questions = data.questions;

    // SET TOTAL
    totalQuestions.innerText =
    questions.length;

    // LOAD FIRST QUESTION
    loadQuestion();

    // CREATE SIDEBAR
    createSidebar();

    // UPDATE ANSWERS
    updateAnsweredCount();

  }

  catch(error) {

    console.error(
      "Failed to fetch questions:",
      error
    );

    alert(
      "Could not load exam questions."
    );

  }

}


// =====================================
// LOAD QUESTION
// =====================================

function loadQuestion() {

  const q =
  questions[currentQuestion];

  if(!q) return;

  questionText.innerText =
  q.question;

  currentQuestionText.innerText =
  currentQuestion + 1;

  optionsContainer.innerHTML = "";

  q.options.forEach(option => {

    const button =
    document.createElement("button");

    button.classList.add("option");

    button.innerText = option;

    // SELECTED
    if(
      answers[currentQuestion] === option
    ){
      button.classList.add("selected");
    }

    button.addEventListener("click", () => {

      answers[currentQuestion] =
      option;

      updateAnsweredCount();

      loadQuestion();

      updateSidebar();

    });

    optionsContainer.appendChild(button);

  });

  updateProgress();

  updateFlagButton();

}


// =====================================
// NEXT QUESTION
// =====================================

document.getElementById("nextBtn")
.addEventListener("click", () => {

  if(
    currentQuestion <
    questions.length - 1
  ){

    currentQuestion++;

    loadQuestion();

    updateSidebar();

  }

});


// =====================================
// PREVIOUS QUESTION
// =====================================

document.getElementById("prevBtn")
.addEventListener("click", () => {

  if(currentQuestion > 0){

    currentQuestion--;

    loadQuestion();

    updateSidebar();

  }

});


// =====================================
// SIDEBAR
// =====================================

function createSidebar() {

  questionGrid.innerHTML = "";

  questions.forEach((q,index) => {

    const btn =
    document.createElement("button");

    btn.innerText = index + 1;

    btn.classList.add("q-number");

    // ACTIVE
    if(index === currentQuestion){
      btn.classList.add("active");
    }

    // ANSWERED
    if(answers[index]){
      btn.classList.add("answered");
    }

    // FLAGGED
    if(flagged.includes(index)){
      btn.classList.add("flag-sidebar");
    }

    btn.addEventListener("click", () => {

      currentQuestion = index;

      loadQuestion();

      updateSidebar();

    });

    questionGrid.appendChild(btn);

  });

}

function updateSidebar() {

  createSidebar();

}


// =====================================
// PROGRESS BAR
// =====================================

function updateProgress() {

  const percent =
  ((currentQuestion + 1)
  / questions.length) * 100;

  progress.style.width =
  percent + "%";

}


// =====================================
// ANSWER COUNT
// =====================================

function updateAnsweredCount() {

  answeredCount.innerText =
  Object.keys(answers).length;

}


// =====================================
// FLAGGING
// =====================================

flagBtn.addEventListener("click", () => {

  if(flagged.includes(currentQuestion)){

    flagged =
    flagged.filter(
      q => q !== currentQuestion
    );

  }

  else{

    flagged.push(currentQuestion);

  }

  updateFlagButton();

  updateSidebar();

});

function updateFlagButton() {

  if(flagged.includes(currentQuestion)){

    flagBtn.classList.add("flagged");

  }

  else{

    flagBtn.classList.remove("flagged");

  }

}


// =====================================
// TIMER
// =====================================

let time = 30 * 60;

setInterval(() => {

  let minutes =
  Math.floor(time / 60);

  let seconds =
  time % 60;

  seconds =
  seconds < 10
  ? "0" + seconds
  : seconds;

  timer.innerText =
  `${minutes}:${seconds}`;

  if(time > 0){

    time--;

  }

},1000);


// =====================================
// SUBMIT EXAM
// =====================================

async function submitExam() {

  try {

    const response = await fetch(
      `${API_BASE}/submit`,
      {

        method: "POST",

        headers: {
          "Content-Type":
          "application/json"
        },

        body: JSON.stringify({

          answers: answers

        })

      }
    );

    const data =
    await response.json();

    alert(data.message);

    // OPTIONAL REDIRECT
    window.location.href =
    "dashboard.html";

  }

  catch(error) {

    console.error(
      "Submission failed:",
      error
    );

    alert(
      "Could not submit exam."
    );

  }

}


// =====================================
// SET EXAM TITLE FROM LOCAL STORAGE
// =====================================

const examTitleEl = document.getElementById("exam-title");
const storedTitle = localStorage.getItem("examTitle");
if (examTitleEl && storedTitle) {
  examTitleEl.textContent = storedTitle;
}

// =====================================
// INITIAL LOAD
// =====================================

fetchQuestions();
