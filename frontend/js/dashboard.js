const API_BASE = "http://127.0.0.1:5000";

let generatedConfig = null;
let configId = null;
let buildId = null;

const isoForm = document.getElementById("isoForm");
const examName = document.getElementById("examName");
const courseCode = document.getElementById("courseCode");
const examUrl = document.getElementById("examUrl");
const duration = document.getElementById("duration");
const institution = document.getElementById("institution");
const examServer = document.getElementById("examServer");
const allowedDomains = document.getElementById("allowedDomains");
const trustedSSIDs = document.getElementById("trustedSSIDs");
const securityProfile = document.getElementById("securityProfile");
const kioskMode = document.getElementById("kioskMode");
const disableTerminal = document.getElementById("disableTerminal");
const disableUSB = document.getElementById("disableUSB");
const disablePrinting = document.getElementById("disablePrinting");
const disableScreenshots = document.getElementById("disableScreenshots");
const allowEthernet = document.getElementById("allowEthernet");
const buildBtn = document.getElementById("buildBtn");
const progressFill = document.getElementById("progressFill");
const progressText = document.getElementById("progressText");
const buildStatus = document.getElementById("buildStatus");
const logoutBtn = document.getElementById("logoutBtn");

const adminId = localStorage.getItem("admin_id");
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

function getFormData() {
    return {
        exam_name: examName.value.trim(),
        course_code: courseCode.value.trim(),
        exam_url: examUrl.value.trim(),
        exam_duration: Number(duration.value),
        institution: institution.value.trim(),
        exam_server: examServer.value.trim(),
        allowed_domains: allowedDomains.value.split("\n").map(value => value.trim()).filter(Boolean),
        trusted_ssids: trustedSSIDs.value.split("\n").map(value => value.trim()).filter(Boolean),
        profile: securityProfile.value,
        kiosk_mode: kioskMode.checked,
        disable_terminal: disableTerminal.checked,
        disable_usb: disableUSB.checked,
        disable_printing: disablePrinting.checked,
        disable_screenshots: disableScreenshots.checked,
        allow_ethernet: allowEthernet.checked
    };
}

async function generateConfiguration() {
    const response = await fetch(`${API_BASE}/api/config/generate`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify(getFormData())
    });

    const data = await response.json();

    if (!response.ok) {
        throw new Error(data.error || "Configuration generation failed");
    }

    generatedConfig = data.config;
    return data;
}

async function saveConfiguration() {
    if (!generatedConfig) {
        throw new Error("Please generate a configuration first.");
    }

    const response = await fetch(`${API_BASE}/api/config/save`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            config: generatedConfig,
            name: examName.value.trim(),
            course_code: courseCode.value.trim(),
            created_by: adminId ? Number(adminId) : null,
            admin_id: adminId ? Number(adminId) : null
        })
    });

    const data = await response.json();

    if (!response.ok) {
        throw new Error(data.error || "Configuration save failed");
    }

    configId = data.config_id;
    buildBtn.disabled = false;
    return data;
}

async function buildISO() {
    if (!configId) {
        alert("Please save the configuration first.");
        return;
    }

    const response = await fetch(`${API_BASE}/api/config/${configId}/build`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            admin_id: adminId ? Number(adminId) : null
        })
    });

    const data = await response.json();

    if (!response.ok) {
        throw new Error(data.error || "ISO build request failed");
    }

    buildId = data.build_id;
    buildStatus.textContent = "Build Started...";
    monitorBuild();
}

async function monitorBuild() {
    const timer = setInterval(async () => {
        const response = await fetch(`${API_BASE}/api/config/builds/${buildId}`);
        const data = await response.json();

        if (!response.ok) {
            clearInterval(timer);
            buildStatus.textContent = data.error || "Build lookup failed";
            return;
        }

        const status = String(data.status || "").toLowerCase();
        buildStatus.textContent = data.status || "Unknown";

        if (status === "pending") {
            progressFill.style.width = "20%";
            progressText.textContent = "20%";
        } else if (status === "building") {
            progressFill.style.width = "60%";
            progressText.textContent = "60%";
        } else if (status === "completed") {
            progressFill.style.width = "100%";
            progressText.textContent = "100%";
            buildStatus.textContent = "ISO Ready";
            clearInterval(timer);
        } else if (status === "failed") {
            buildStatus.textContent = "Build Failed";
            clearInterval(timer);
        }
    }, 3000);
}

isoForm.addEventListener("submit", async (event) => {
    event.preventDefault();

    try {
        await generateConfiguration();
        await saveConfiguration();
        alert("Configuration generated and saved successfully!");
    } catch (error) {
        alert(error.message);
    }
});

buildBtn.addEventListener("click", async () => {
    try {
        await buildISO();
    } catch (error) {
        alert(error.message);
    }
});

logoutBtn.addEventListener("click", () => {
    localStorage.removeItem("admin_id");
    localStorage.removeItem("user");
    localStorage.removeItem("username");
    localStorage.removeItem("role");
    window.location.href = "login.html";
});