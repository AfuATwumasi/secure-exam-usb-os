const API_BASE = "http://127.0.0.1:5000";

const historyTable = document.getElementById("historyTable");
const searchInput = document.getElementById("searchInput");
const statusFilter = document.getElementById("statusFilter");
const templateFilter = document.getElementById("templateFilter");
const clearBtn = document.getElementById("clearBtn");
const logoutBtn = document.getElementById("logoutBtn");
const totalBuilds = document.getElementById("totalBuilds");
const successfulBuilds = document.getElementById("successfulBuilds");
const failedBuilds = document.getElementById("failedBuilds");
const progressBuilds = document.getElementById("progressBuilds");
const totalSize = document.getElementById("totalSize");
const emptyState = document.getElementById("emptyState");

const adminUsername = localStorage.getItem("username") || localStorage.getItem("user") || "Admin User";

if (adminUsername) {
    const adminNameNode = document.querySelector(".admin-box h4");
    const adminRoleNode = document.querySelector(".admin-box p");
    if (adminNameNode) {
        adminNameNode.textContent = adminUsername;
    }
    if (adminRoleNode) {
        adminRoleNode.textContent = localStorage.getItem("role") || "Administrator";
    }
}

function statusBucket(status) {
    const normalized = String(status || "").toLowerCase();
    if (normalized === "completed" || normalized === "success") return "success";
    if (normalized === "failed") return "failed";
    return "progress";
}

function updateStatistics(builds) {
    totalBuilds.textContent = String(builds.length);
    successfulBuilds.textContent = String(builds.filter(build => statusBucket(build.status) === "success").length);
    failedBuilds.textContent = String(builds.filter(build => statusBucket(build.status) === "failed").length);
    progressBuilds.textContent = String(builds.filter(build => statusBucket(build.status) === "progress").length);

    const totalBytes = builds.reduce((sum, build) => {
        const value = Number(build.file_size_bytes || 0);
        return sum + value;
    }, 0);

    const totalGb = totalBytes / (1024 * 1024 * 1024);
    totalSize.textContent = `${totalGb >= 1 ? totalGb.toFixed(1) : totalBytes} ${totalGb >= 1 ? "GB" : "Bytes"}`;
}

function renderTable(builds) {
    const rows = builds.map(build => `
        <tr>
            <td>${build.iso_name || "-"}</td>
            <td>${build.exam_name || "-"}</td>
            <td>${build.template_name || "-"}</td>
            <td>${build.build_created_at || build.created_at || "-"}</td>
            <td>${build.build_status || build.status || "-"}</td>
            <td>${build.iso_size || build.file_size_bytes || "-"}</td>
            <td>${build.download_url ? `<a href="${build.download_url}">Download</a>` : "-"}</td>
        </tr>
    `).join("");

    historyTable.innerHTML = rows || `
        <tr>
            <td colspan="7" style="text-align:center;padding:40px;">No builds found.</td>
        </tr>
    `;

    emptyState.style.display = builds.length ? "none" : "block";
}

async function loadBuildHistory() {
    try {
        const response = await fetch(`${API_BASE}/api/config/builds`);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || "Unable to load builds");
        }

        const builds = data.builds || [];
        updateStatistics(builds);
        renderTable(builds);
    } catch (error) {
        console.error(error);
        historyTable.innerHTML = `
        <tr>
            <td colspan="7" style="text-align:center;padding:40px;color:red;">
                Failed to connect to backend.
            </td>
        </tr>`;
        emptyState.style.display = "block";
    }
}

searchInput.addEventListener("input", loadBuildHistory);
statusFilter.addEventListener("change", loadBuildHistory);
templateFilter.addEventListener("change", loadBuildHistory);

clearBtn.addEventListener("click", () => {
    searchInput.value = "";
    statusFilter.value = "all";
    templateFilter.value = "all";
    loadBuildHistory();
});

logoutBtn.addEventListener("click", () => {
    localStorage.removeItem("admin_id");
    localStorage.removeItem("user");
    localStorage.removeItem("username");
    localStorage.removeItem("role");
    window.location.href = "login.html";
});

loadBuildHistory();