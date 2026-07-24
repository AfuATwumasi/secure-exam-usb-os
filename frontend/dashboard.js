const isoForm = document.getElementById("isoForm");
const buildTable = document.getElementById("buildTable");

isoForm.addEventListener("submit", function (event) {
  event.preventDefault();

  const examUrl = document.getElementById("examUrl").value;
  const examName = document.getElementById("examName").value;
  const duration = document.getElementById("duration").value;

  if (!examUrl || !examName || !duration) {
    alert("Please fill all required fields.");
    return;
  }
  const isoData = {
  examUrl: examUrl,
  examName: examName,
  duration: duration,

  securityOptions: {
    kioskMode: document.getElementById("kioskMode").checked,
    usbBoot: document.getElementById("usbBoot").checked,
    browserLock: document.getElementById("browserLock").checked,
    examUrlRestriction: document.getElementById("examUrlRestriction").checked,
    autoLogin: document.getElementById("autoLogin").checked,
    disablePrinting: document.getElementById("disablePrinting").checked,
    screenCaptureBlock: document.getElementById("screenCaptureBlock").checked
  }
};

console.log(isoData);

  const isoName = examName.replaceAll(" ", "_") + "_ExamOS.iso";

  const newRow = document.createElement("tr");

  newRow.innerHTML = `
    <td>${isoName}</td>
    <td>${examName}</td>
    <td>Just now</td>
    <td><span class="success">Building</span></td>
    <td>Pending</td>
    <td><button class="download-btn">...</button></td>
  `;

  buildTable.prepend(newRow);

  alert("ISO generation started successfully.");

  isoForm.reset();

  startProgress();
});

function startProgress() {
  let progress = 0;

  const progressText = document.getElementById("progressText");
  const progressFill = document.getElementById("progressFill");

  const interval = setInterval(() => {
    progress += 5;

    progressText.textContent = progress + "%";
    progressFill.style.width = progress + "%";

    if (progress >= 100) {
      clearInterval(interval);
      alert("ISO generated successfully!");
    }
  }, 300);
}

const logoutBtn = document.getElementById("logoutBtn");

logoutBtn.addEventListener("click", function () {

    const confirmLogout = confirm(
        "Are you sure you want to log out?"
    );

    if (confirmLogout) {

        // Redirect back to login page
        window.location.href = "login.html";

    }

});