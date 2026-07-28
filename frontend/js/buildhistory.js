const API_BASE = "http://127.0.0.1:5000";

// ==============================
// DOM ELEMENTS
// ==============================

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

// ==============================
// STATUS CSS MAPPING
// ==============================

const statusClass = {
    pending: "progress",
    building: "progress",
    progress: "progress",
    completed: "success",
    success: "success",
    failed: "failed"
};

// ==============================
// LOAD BUILD HISTORY
// ==============================

async function loadBuildHistory() {

    try {

        const response =
            await fetch(`${API_BASE}/api/config/builds`);

        const data = await response.json();

        if (!response.ok) {

            throw new Error(data.error || "Unable to load builds");

        }

        const builds = data.builds || [];

        updateStatistics(builds);

        renderTable(builds);

    }

    catch (error) {

        console.error(error);

        historyTable.innerHTML = `
        <tr>
            <td colspan="7" style="text-align:center;padding:40px;color:red;">
                Failed to connect to backend.
            </td>
        </tr>`;

    }

}

// ==============================
// UPDATE DASHBOARD CARDS
// ==============================

function updateStatistics(builds){

    totalBuilds.textContent = builds.length;

    successfulBuilds.textContent =
        builds.filter(b =>
            b.status === "completed" ||
            b.status === "success"
        ).length;

    failedBuilds.textContent =
        builds.filter(b =>
            b.status === "failed"
        ).length;

    progressBuilds.textContent =
        builds.filter(b =>
            b.status === "pending" ||
            b.status === "building" ||
            b.status === "progress"
        ).length;

    totalSize.textContent =
        `${(successfulBuilds.textContent * 3.42).toFixed(2)} GB`;

}

// ==============================
// RENDER TABLE
// ==============================

function renderTable(builds){

    historyTable.innerHTML = "";

    if(builds.length === 0){

        emptyState.style.display = "block";

        return;

    }

    emptyState.style.display = "none";

    builds.forEach(build=>{

        const row = document.createElement("tr");

        row.dataset.status = build.status;
        row.dataset.template = "default";

        row.innerHTML = `

        <td>

            ${build.iso_filename || build.build_id + ".iso"}

        </td>

        <td>

            ${build.config_id}

        </td>

        <td>

            Default Exam Template

        </td>

        <td>

            ${new Date(build.created_at).toLocaleString()}

        </td>

        <td>

            <span class="status ${statusClass[build.status]}">

                ${build.status}

            </span>

        </td>

        <td>

            ${build.iso_filename ? "3.42 GB" : "-"}

        </td>

        <td>

            ${actionButtons(build)}

        </td>

        `;

        historyTable.appendChild(row);

    });

}

// ==============================
// ACTION BUTTONS
// ==============================

function actionButtons(build){

    if(build.status==="completed" || build.status==="success"){

        return `

        <button
            disabled
            title="Download endpoint not yet implemented">

            Download

        </button>

        `;

    }

    if(build.status==="failed"){

        return `

        <button
            class="retry-btn"
            onclick="retryBuild('${build.build_id}')">

            Retry

        </button>

        `;

    }

    return `

    <button disabled>

        Building...

    </button>

    `;

}

// ==============================
// RETRY BUILD
// ==============================

async function retryBuild(buildId){

    if(!confirm("Retry this ISO build?")) return;

    try{

        const response =
            await fetch(`${API_BASE}/api/config/builds/${buildId}`);

        const build =
            await response.json();

        if(!response.ok){

            throw new Error(build.error);

        }

        const retry =
            await fetch(

                `${API_BASE}/api/config/${build.config_id}/build`,

                {
                    method:"POST"
                }

            );

        const result =
            await retry.json();

        if(retry.ok){

            alert("ISO build requested.");

            loadBuildHistory();

        }

        else{

            alert(result.error || "Retry failed.");

        }

    }

    catch(error){

        console.error(error);

        alert("Unable to connect to backend.");

    }

}

// ==============================
// SEARCH + FILTERS
// ==============================

function filterBuilds(){

    const rows =
        historyTable.querySelectorAll("tr");

    const search =
        searchInput.value.toLowerCase();

    rows.forEach(row=>{

        const text =
            row.textContent.toLowerCase();

        const status =
            row.dataset.status;

        const template =
            row.dataset.template;

        const searchMatch =
            text.includes(search);

        const statusMatch =
            statusFilter.value==="all" ||
            status===statusFilter.value;

        const templateMatch =
            templateFilter.value==="all" ||
            template===templateFilter.value;

        row.style.display =
            searchMatch &&
            statusMatch &&
            templateMatch

            ?

            ""

            :

            "none";

    });

}

searchInput.addEventListener("input",filterBuilds);

statusFilter.addEventListener("change",filterBuilds);

templateFilter.addEventListener("change",filterBuilds);

// ==============================
// CLEAR FILTERS
// ==============================

clearBtn.addEventListener("click",()=>{

    searchInput.value="";

    statusFilter.value="all";

    templateFilter.value="all";

    filterBuilds();

});

// ==============================
// LOGOUT
// ==============================

logoutBtn.addEventListener("click",()=>{

    if(confirm("Log out?")){

        localStorage.removeItem("user");
        localStorage.removeItem("role");

        window.location.href="login.html";

    }

});

// ==============================
// START
// ==============================

document.addEventListener("DOMContentLoaded",()=>{

    loadBuildHistory();

});   