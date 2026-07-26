const isoForm = document.getElementById("isoForm");

isoForm.addEventListener("submit", async (event) => {
    event.preventDefault();

    // Collect form values
    const examUrl = document.getElementById("examUrl").value.trim();
    const examName = document.getElementById("examName").value.trim();
    const duration = document.getElementById("duration").value.trim();
    const profile = document.getElementById("securityProfile").value;

    // Security options
    const kioskMode = document.getElementById("kioskMode").checked;
    const disablePrinting = document.getElementById("disablePrinting").checked;
    const disableScreenshots = document.getElementById("screenCaptureBlock").checked;

    try {

        const response = await fetch("http://127.0.0.1:5000/api/config/generate", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                exam_url: examUrl,
                exam_name: examName,
                exam_duration: duration,
                profile: profile,
                kiosk_mode: kioskMode,
                disable_printing: disablePrinting,
                disable_screenshots: disableScreenshots
            })
        });

        const data = await response.json();

        if (response.ok) {
            console.log(data);

            alert("Configuration generated successfully!");

            // We'll use this in the next step
            window.generatedConfig = data.config;

        } else {
            alert(data.error || "Configuration generation failed.");
        }

    } catch (error) {
        console.error(error);
        alert("Unable to connect to the backend.");
    }
});