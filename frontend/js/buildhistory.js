const API_BASE = "http://127.0.0.1:5000";
const historyTable = document.getElementById("historyTable");
const searchInput = document.getElementById("searchInput");
const statusFilter = document.getElementById("statusFilter");
const templateFilter = document.getElementById("templateFilter");
const clearBtn = document.getElementById("clearBtn");
const logoutBtn = document.getElementById("logoutBtn");

// ==============================
// LOAD BUILD HISTORY FROM BACKEND
// ==============================

async function loadBuildHistory() {
  if (!historyTable) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/builds`);
    const data = await response.json();

    if (data.builds && data.builds.length > 0) {
      historyTable.innerHTML = data.builds
        .map(
          (b) => `
          <tr data-status="${b.status}" data-template="high">
            <td>${b.build_id.substring(0, 20)}.iso</td>
            <td>${b.config_id}</td>
            <td>High Security Template</td>
            <td>${new Date(b.created_at).toLocaleString()}</td>
            <td><span class="status ${b.status}">${b.status}</span></td>
            <td>${b.iso_filename ? "3.42 GB" : "-"}</td>
            <td>
              ${
                b.status === "completed"
                  ? '<button>⬇</button>'
                  : b.status === "failed"
                  ? '<button onclick="retryBuild(\'' + b.build_id + '\')">↻</button>'
                  : '<button disabled>⏳</button>'
              }
              <button>⋯</button>
            </td>
          </tr>
        `
        )
        .join("");
    } else {
      historyTable.innerHTML = `
        <tr>
          <td colspan="7" style="text-align: center; color: #888; padding: 40px;">
            No builds found. Generate your first ISO from the dashboard.
          </td>
        </tr>
      `;
    }
  } catch (error) {
    console.error("Failed to load build history:", error);
    historyTable.innerHTML = `
      <tr>
        <td colspan="7" style="text-align: center; color: #dc3545; padding: 40px;">
          Failed to load builds. Is the backend running?
        </td>
      </tr>
    `;
  }
}

// ==============================
// FILTERS (client-side)
// ==============================

function filterBuilds() {
  const rows = historyTable.querySelectorAll("tr");
  const searchValue = searchInput.value.toLowerCase();
  const selectedStatus = statusFilter.value;
  const selectedTemplate = templateFilter.value;

  rows.forEach(row => {
    const rowText = row.textContent.toLowerCase();
    const rowStatus = row.dataset.status;
    const rowTemplate = row.dataset.template;

    const matchesSearch = rowText.includes(searchValue);
    const matchesStatus = selectedStatus === "all" || rowStatus === selectedStatus;
    const matchesTemplate = selectedTemplate === "all" || rowTemplate === selectedTemplate;

    row.style.display = (matchesSearch && matchesStatus && matchesTemplate) ? "" : "none";
  });
}

searchInput.addEventListener("input", filterBuilds);
statusFilter.addEventListener("change", filterBuilds);
templateFilter.addEventListener("change", filterBuilds);

clearBtn.addEventListener("click", function () {
  searchInput.value = "";
  statusFilter.value = "all";
  templateFilter.value = "all";
  filterBuilds();
});

// ==============================
// LOGOUT
// ==============================

logoutBtn.addEventListener("click", function () {
  if (confirm("Are you sure you want to log out?")) {
    localStorage.removeItem("user");
    localStorage.removeItem("role");
    window.location.href = "login.html";
  }
});

// ==============================
// RETRY BUILD
// ==============================

async function retryBuild(buildId) {
  if (!confirm("Retry this build?")) return;

  try {
    const response = await fetch(`${API_BASE}/api/config/builds/${buildId}`);
    const data = await response.json();

    if (response.ok && data.config_id) {
      const buildResponse = await fetch(
        `${API_BASE}/api/config/${data.config_id}/build`,
        { method: "POST" }
      );
      const buildData = await buildResponse.json();

      if (buildResponse.ok) {
        alert("Build retried! New ID: " + buildData.build_id);
        loadBuildHistory();
      } else {
        alert("Retry failed: " + (buildData.error || ""));
      }
    }
  } catch (error) {
    console.error("Retry failed:", error);
    alert("Server connection failed");
  }
}

// ==============================
// INIT
// ==============================

document.addEventListener("DOMContentLoaded", loadBuildHistory);
