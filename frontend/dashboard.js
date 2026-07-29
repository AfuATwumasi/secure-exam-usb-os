const API_BASE = "http://127.0.0.1:5000";
const isoForm = document.getElementById("isoForm");
const buildTable = document.getElementById("buildTable");

// ==============================
// GENERATE ISO FORM
// ==============================

isoForm.addEventListener("submit", async function (event) {
  event.preventDefault();

  const examUrl = document.getElementById("examUrl").value;
  const examName = document.getElementById("examName").value;
  const duration = document.getElementById("duration").value;

  if (!examUrl || !examName || !duration) {
    alert("Please fill all required fields.");
    return;
  }

  // Map security checkboxes to backend fields
  const securityOptions = {
    kiosk_mode: document.getElementById("kioskMode").checked,
    disable_terminal: document.getElementById("browserLock").checked,
    disable_printing: document.getElementById("disablePrinting").checked,
    disable_screenshots: document.getElementById("screenCaptureBlock").checked,
  };

  const payload = {
    exam_url: examUrl,
    exam_name: examName,
    exam_duration: parseInt(duration) || 120,
    profile: "strict",
    ...securityOptions,
  };

  try {
    const response = await fetch(`${API_BASE}/api/config/generate`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await response.json();

    if (!response.ok) {
      alert("Error: " + (data.error || "Generation failed"));
      return;
    }

    // Save config to database
    const saveResponse = await fetch(`${API_BASE}/api/config/save`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        config: data.config,
        name: examName,
        description: `Exam: ${examName}`,
      }),
    });

    const saveData = await saveResponse.json();

    if (!saveResponse.ok) {
      alert("Config saved but could not be stored: " + (saveData.error || ""));
      return;
    }

    // Request ISO build
    const buildResponse = await fetch(
      `${API_BASE}/api/config/${saveData.config_id}/build`,
      { method: "POST" }
    );

    const buildData = await buildResponse.json();

    if (buildResponse.ok) {
      alert(`ISO build started! Build ID: ${buildData.build_id}`);
    } else {
      alert("Build request failed: " + (buildData.error || ""));
    }

    // Add row to recent builds table
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

    isoForm.reset();
    loadRecentBuilds(); // Refresh the list
  } catch (error) {
    console.error("ISO generation failed:", error);
    alert("Server connection failed. Is the backend running?");
  }
});

// ==============================
// LOAD RECENT BUILDS
// ==============================

async function loadRecentBuilds() {
  if (!buildTable) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/builds`);
    const data = await response.json();

    if (data.builds && data.builds.length > 0) {
      // Show only the 5 most recent
      const recent = data.builds.slice(0, 5);
      buildTable.innerHTML = recent
        .map(
          (b) => `
          <tr>
            <td>${b.build_id.substring(0, 16)}.iso</td>
            <td>${b.config_id}</td>
            <td>${new Date(b.created_at).toLocaleDateString()}</td>
            <td><span class="${b.status}">${b.status}</span></td>
            <td>${b.iso_filename ? "3.42 GB" : "-"}</td>
            <td>
              ${
                b.status === "completed"
                  ? '<button class="download-btn">⬇</button>'
                  : b.status === "failed"
                  ? '<button class="retry-btn">↻</button>'
                  : '<button disabled>⏳</button>'
              }
            </td>
          </tr>
        `
        )
        .join("");
    }
  } catch (error) {
    console.error("Failed to load builds:", error);
  }
}

// ==============================
// LOGOUT
// ==============================

const logoutBtn = document.getElementById("logoutBtn");
if (logoutBtn) {
  logoutBtn.addEventListener("click", function () {
    if (confirm("Are you sure you want to log out?")) {
      localStorage.removeItem("user");
      localStorage.removeItem("role");
      window.location.href = "login.html";
    }
  });
}

// ==============================
// INIT
// ==============================

document.addEventListener("DOMContentLoaded", loadRecentBuilds);