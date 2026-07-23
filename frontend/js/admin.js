// ==============================
// ADMIN DASHBOARD — Exam OS Config
// ==============================

const API_BASE = "http://127.0.0.1:5000";

// ==============================
// GENERATE CONFIG FORM
// ==============================

const configForm = document.getElementById("configForm");
let lastGeneratedConfig = null;
let lastGeneratedConfigId = null;

if (configForm) {
  configForm.addEventListener("submit", async function (e) {
    e.preventDefault();

    const examUrl = document.getElementById("examUrl").value;
    const examName = document.getElementById("examName").value;
    const courseCode = document.getElementById("courseCode").value;
    const duration = parseInt(document.getElementById("duration").value) || 120;
    const ssidsRaw = document.getElementById("ssids").value;
    const trustedSsids = ssidsRaw
      ? ssidsRaw.split(",").map((s) => s.trim()).filter(Boolean)
      : undefined;
    const examServer = document.getElementById("examServer").value;
    const profile = document.getElementById("profile").value;

    const payload = {
      exam_url: examUrl,
      exam_name: examName,
      course_code: courseCode,
      exam_duration: duration,
      profile: profile,
    };

    if (trustedSsids && trustedSsids.length > 0) payload.trusted_ssids = trustedSsids;
    if (examServer) payload.exam_server = examServer;

    // For custom profile, read the toggles
    if (profile === "custom") {
      payload.disable_terminal = document.getElementById("disableTerminal").checked;
      payload.disable_usb = document.getElementById("disableUsb").checked;
      payload.disable_printing = document.getElementById("disablePrinting").checked;
      payload.disable_screenshots = document.getElementById("disableScreenshots").checked;
      payload.kiosk_mode = document.getElementById("kioskMode").checked;
    }

    try {
      document.getElementById("generateBtn").textContent = "Generating...";
      document.getElementById("generateBtn").disabled = true;

      const response = await fetch(`${API_BASE}/api/config/generate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await response.json();

      if (response.ok) {
        lastGeneratedConfig = data.config;
        document.getElementById("configJsonPreview").textContent = data.config_json;
        document.getElementById("configOutput").style.display = "block";
        document.getElementById("saveMessage").textContent = "";
      } else {
        alert("Error: " + (data.error || data.message));
      }
    } catch (error) {
      console.error("Config generation failed:", error);
      alert("Server connection failed. Is the backend running?");
    } finally {
      document.getElementById("generateBtn").textContent = "Generate Configuration";
      document.getElementById("generateBtn").disabled = false;
    }
  });
}

// ==============================
// SAVE CONFIG TO DATABASE
// ==============================

document.getElementById("saveConfigBtn")?.addEventListener("click", async function () {
  if (!lastGeneratedConfig) return;

  const name = document.getElementById("examName").value;
  const description = document.getElementById("courseCode").value
    ? `Exam configuration for ${document.getElementById("courseCode").value}`
    : "Generated from admin dashboard";

  try {
    this.textContent = "Saving...";
    this.disabled = true;

    const response = await fetch(`${API_BASE}/api/config/save`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        config: lastGeneratedConfig,
        name: name,
        description: description,
        course_code: document.getElementById("courseCode").value,
      }),
    });

    const data = await response.json();

    if (response.ok) {
      lastGeneratedConfigId = data.config_id;
      document.getElementById("saveMessage").textContent =
        "✅ Saved! ID: " + data.config_id;
      document.getElementById("saveMessage").className = "save-message success";
      loadConfigList(); // Refresh the list
    } else {
      document.getElementById("saveMessage").textContent =
        "❌ " + (data.error || "Save failed");
      document.getElementById("saveMessage").className = "save-message error";
    }
  } catch (error) {
    console.error("Save failed:", error);
    document.getElementById("saveMessage").textContent =
      "❌ Server connection failed";
    document.getElementById("saveMessage").className = "save-message error";
  } finally {
    this.textContent = "Save to Database";
    this.disabled = false;
  }
});

// ==============================
// COPY JSON TO CLIPBOARD
// ==============================

document.getElementById("copyConfigBtn")?.addEventListener("click", function () {
  const text = document.getElementById("configJsonPreview").textContent;
  navigator.clipboard.writeText(text).then(() => {
    this.textContent = "Copied!";
    setTimeout(() => (this.textContent = "Copy JSON"), 2000);
  });
});

// ==============================
// LOAD SAVED CONFIGURATIONS
// ==============================

async function loadConfigList() {
  const configList = document.getElementById("configList");
  if (!configList) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/`);
    const data = await response.json();

    if (data.configs && data.configs.length > 0) {
      configList.innerHTML = data.configs
        .map(
          (cfg) => `
          <div class="list-item">
            <div class="list-item-header">
              <strong>${cfg.name}</strong>
              <span class="badge badge-${cfg.profile}">${cfg.profile}</span>
            </div>
            <p class="list-item-url">${cfg.exam_url}</p>
            <p class="list-item-meta">
              ${cfg.description || ""}
              <br />
              <small>Created: ${new Date(cfg.created_at).toLocaleString()}</small>
            </p>
            <div class="list-item-actions">
              <a href="${API_BASE}/api/config/${cfg.config_id}" target="_blank" class="btn-small">View</a>
              <button class="btn-small btn-danger" onclick="deleteConfig('${cfg.config_id}')">Delete</button>
              <button class="btn-small btn-build" onclick="requestBuild('${cfg.config_id}')">Build ISO</button>
            </div>
          </div>
        `
        )
        .join("");
    } else {
      configList.innerHTML = '<p class="empty-text">No configurations saved yet.</p>';
    }
  } catch (error) {
    console.error("Failed to load configs:", error);
    configList.innerHTML = '<p class="error-text">Failed to load. Is the backend running?</p>';
  }
}

// ==============================
// LOAD ISO BUILDS
// ==============================

async function loadBuildList() {
  const buildList = document.getElementById("buildList");
  if (!buildList) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/builds`);
    const data = await response.json();

    if (data.builds && data.builds.length > 0) {
      buildList.innerHTML = data.builds
        .map(
          (b) => `
          <div class="list-item">
            <div class="list-item-header">
              <strong>${b.build_id}</strong>
              <span class="badge badge-${b.status}">${b.status}</span>
            </div>
            <p class="list-item-meta">
              Config: ${b.config_id}<br />
              ${b.iso_filename ? "ISO: " + b.iso_filename : ""}
              ${b.sha256_hash ? "<br />SHA256: " + b.sha256_hash.substring(0, 16) + "..." : ""}
              ${b.error_message ? "<br /><span class='error-text'>" + b.error_message + "</span>" : ""}
              <br />
              <small>Requested: ${new Date(b.created_at).toLocaleString()}</small>
            </p>
          </div>
        `
        )
        .join("");
    } else {
      buildList.innerHTML = '<p class="empty-text">No ISO builds requested yet.</p>';
    }
  } catch (error) {
    console.error("Failed to load builds:", error);
    buildList.innerHTML = '<p class="error-text">Failed to load.</p>';
  }
}

// ==============================
// DELETE CONFIG
// ==============================

async function deleteConfig(configId) {
  if (!confirm("Delete this configuration?")) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/${configId}`, {
      method: "DELETE",
    });

    if (response.ok) {
      loadConfigList();
    } else {
      const data = await response.json();
      alert("Delete failed: " + (data.error || "Unknown error"));
    }
  } catch (error) {
    console.error("Delete failed:", error);
    alert("Server connection failed");
  }
}

// ==============================
// REQUEST ISO BUILD
// ==============================

async function requestBuild(configId) {
  if (!confirm("Request an ISO build for this configuration?")) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/${configId}/build`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    });

    const data = await response.json();

    if (response.ok) {
      alert("Build requested! ID: " + data.build_id);
      loadBuildList();
    } else {
      alert("Build request failed: " + (data.error || "Unknown error"));
    }
  } catch (error) {
    console.error("Build request failed:", error);
    alert("Server connection failed");
  }
}

// ==============================
// INIT
// ==============================

document.addEventListener("DOMContentLoaded", function () {
  loadConfigList();
  loadBuildList();
});
