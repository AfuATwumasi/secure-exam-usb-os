// ================================
// Backend URL
// ================================

const API_BASE = "http://127.0.0.1:5000";

// Stores generated configuration
let generatedConfig = null;

// Stores saved configuration ID
let configId = null;

// Stores build ID
let buildId = null;

// ================================
// Form Elements
// ================================

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
const generateBtn = document.getElementById("generateBtn");

const progressFill = document.getElementById("progressFill");
const progressText = document.getElementById("progressText");
const buildStatus = document.getElementById("buildStatus");

const buildTable = document.getElementById("buildTable");

const logoutBtn = document.getElementById("logoutBtn");

function getFormData() {

    return {

        exam_name: examName.value.trim(),

        course_code: courseCode.value.trim(),

        exam_url: examUrl.value.trim(),

        exam_duration: Number(duration.value),

        institution: institution.value.trim(),

        exam_server: examServer.value.trim(),

        allowed_domains:
            allowedDomains.value
            .split("\n")
            .map(d => d.trim())
            .filter(Boolean),

        trusted_ssids:
            trustedSSIDs.value
            .split("\n")
            .map(s => s.trim())
            .filter(Boolean),

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

    try {

        const response = await fetch(
            `${API_BASE}/api/config/generate`,
            {

                method: "POST",

                headers: {
                    "Content-Type": "application/json"
                },

                body: JSON.stringify(getFormData())

            }
        );

        const data = await response.json();

        if (!response.ok) {

            throw new Error(data.error);

        }

        generatedConfig = data.config;

        alert("Configuration generated successfully!");

        console.log(generatedConfig);

    }

    catch (error) {

        alert(error.message);

    }

}

// ================================
// Save Configuration
// ================================

async function saveConfiguration() {

    console.log("Saving configuration...");

    if (!generatedConfig) {
        alert("Please generate a configuration first.");
        return;
    }

    try {

        const response = await fetch(`${API_BASE}/api/config/save`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                config: generatedConfig,
                name: examName.value,
                course_code: courseCode.value,
                created_by: "admin"
            })
        });

        const data = await response.json();

        console.log(data);   // <-- Add this

        if (!response.ok) {
            throw new Error(data.error);
        }

        configId = data.config_id;

        console.log("Config ID:", configId);  // <-- Add this

        buildBtn.disabled = false;

    } catch (error) {
        console.error(error);
        alert(error.message);
    }
}

// ================================
// Build ISO
// ================================

async function buildISO(){

    if(!configId){

        alert("Please save the configuration first.");

        return;

    }

    try{

        const response = await fetch(

            `${API_BASE}/api/config/${configId}/build`,

            {
                method:"POST"
            }

        );

        const data = await response.json();

        if(!response.ok){

            throw new Error(data.error);

        }

        buildId = data.build_id;

        buildStatus.textContent = "Build Started...";

        monitorBuild();

    }

    catch(error){

        alert(error.message);

    }

}

// ================================
// Build Progress
// ================================

async function monitorBuild(){

    const timer = setInterval(async()=>{

        const response = await fetch(

            `${API_BASE}/api/config/builds/${buildId}`

        );

        const data = await response.json();

        buildStatus.textContent = data.status;

        if(data.status==="pending"){

            progressFill.style.width="20%";
            progressText.textContent="20%";

        }

        if(data.status==="building"){

            progressFill.style.width="60%";
            progressText.textContent="60%";

        }

        if(data.status==="completed"){

            progressFill.style.width="100%";
            progressText.textContent="100%";

            buildStatus.textContent="ISO Ready";

            clearInterval(timer);

            loadBuildHistory();

        }

        if(data.status==="failed"){

            buildStatus.textContent="Build Failed";

            clearInterval(timer);

        }

    },3000);

}

// ================================
// Load Build History
// ================================

async function loadBuildHistory(){

    const response = await fetch(

        `${API_BASE}/api/config/builds`

    );

    const data = await response.json();

    buildTable.innerHTML="";

    data.builds.forEach(build=>{

        buildTable.innerHTML += `

        <tr>

            <td>${build.iso_filename ?? "-"}</td>

            <td>${build.config_id}</td>

            <td>${build.status}</td>

            <td>${build.created_at}</td>

            <td>${build.build_id}</td>

        </tr>

        `;

    });

}

// ================================
// Logout
// ================================

logoutBtn.addEventListener("click",(event)=>{

    event.preventDefault();

    localStorage.removeItem("user");

    window.location.href="login.html";

});

// ================================
// Events
// ================================

isoForm.addEventListener("submit", async (event) => {

    event.preventDefault();

    await generateConfiguration();

    await saveConfiguration();

    if (configId) {

        buildBtn.disabled = false;

    }

});

buildBtn.addEventListener("click", buildISO);
saveBtn.addEventListener("click",saveConfiguration);
