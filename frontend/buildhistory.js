const searchInput = document.getElementById("searchInput");
const statusFilter = document.getElementById("statusFilter");
const templateFilter = document.getElementById("templateFilter");
const clearBtn = document.getElementById("clearBtn");
const logoutBtn = document.getElementById("logoutBtn");

const tableRows = document.querySelectorAll("#historyTable tr");

function filterBuilds() {
  const searchValue = searchInput.value.toLowerCase();
  const selectedStatus = statusFilter.value;
  const selectedTemplate = templateFilter.value;

  tableRows.forEach(row => {
    const rowText = row.textContent.toLowerCase();
    const rowStatus = row.dataset.status;
    const rowTemplate = row.dataset.template;

    const matchesSearch = rowText.includes(searchValue);
    const matchesStatus =
      selectedStatus === "all" || rowStatus === selectedStatus;
    const matchesTemplate =
      selectedTemplate === "all" || rowTemplate === selectedTemplate;

    if (matchesSearch && matchesStatus && matchesTemplate) {
      row.style.display = "";
    } else {
      row.style.display = "none";
    }
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

logoutBtn.addEventListener("click", function () {
  const confirmLogout = confirm("Are you sure you want to log out?");

  if (confirmLogout) {
    window.location.href = "login.html";
  }
});