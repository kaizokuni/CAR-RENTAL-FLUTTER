
// Native fetch used


async function test() {
    try {
        // 1. Login
        console.log("Logging in...");
        const loginRes = await fetch('http://localhost:8080/api/v1/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email: 'superadmin@platform.com', password: 'Secret123!' })
        });

        if (!loginRes.ok) {
            console.error("Login failed:", await loginRes.text());
            return;
        }

        const loginData = await loginRes.json();
        const token = loginData.token;
        console.log("Login successful, token received.");

        // 2. Get current landing page
        console.log("Fetching landing page...");
        const getRes = await fetch('http://localhost:8080/api/v1/landing-page', {
            headers: { 'Authorization': `Bearer ${token}` }
        });

        if (!getRes.ok) {
            console.error("Get failed:", await getRes.text());
            return;
        }

        const currentSettings = await getRes.json();
        console.log("Current is_live:", currentSettings.is_live);

        // 3. Update is_live to true
        console.log("Updating is_live to true...");
        currentSettings.is_live = true;

        const updateRes = await fetch('http://localhost:8080/api/v1/landing-page', {
            method: 'PUT',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(currentSettings)
        });

        if (!updateRes.ok) {
            console.error("Update failed:", await updateRes.text());
            return;
        }
        console.log("Update successful.");

        // 4. Verify
        console.log("Verifying...");
        const verifyRes = await fetch('http://localhost:8080/api/v1/landing-page', {
            headers: { 'Authorization': `Bearer ${token}` }
        });
        const verifySettings = await verifyRes.json();
        console.log("New is_live:", verifySettings.is_live);

    } catch (e) {
        console.error("Error:", e);
    }
}

test();
