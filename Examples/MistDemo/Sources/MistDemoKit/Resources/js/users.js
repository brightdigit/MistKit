// users/caller · users/discover panel handlers. The deprecated
// users/lookup/email and users/lookup/id primitives are not exposed —
// users/discover is Apple's supported replacement and handles both email
// and record-name lookups (phone-number support tracked in #398).

const usersCallerStatus = document.getElementById('users-caller-status');
const usersCallerRaw = document.getElementById('users-caller-raw');
const usersDiscoverStatus = document.getElementById('users-discover-status');
const usersDiscoverRaw = document.getElementById('users-discover-raw');

document.getElementById('users-caller-btn').addEventListener('click', async () => {
    await runPanelOperation({
        statusEl: usersCallerStatus,
        rawEl: usersCallerRaw,
        label: 'Fetch caller',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await fetchJSON('/api/users/caller');
            }
            return await ckJsContainer().fetchCurrentUserIdentity();
        },
    });
});

document.getElementById('users-discover-btn').addEventListener('click', async () => {
    const emails = csv(document.getElementById('users-discover-emails').value);
    const userRecordNames = csv(document.getElementById('users-discover-record-names').value);
    if (emails.length === 0 && userRecordNames.length === 0) {
        setStatus(usersDiscoverStatus, 'Provide at least one email or record name.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: usersDiscoverStatus,
        rawEl: usersDiscoverRaw,
        label: 'Discover users',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/users/discover', { emails, userRecordNames });
            }
            // CloudKit JS exposes per-item primitives — loop and aggregate
            // to match the REST endpoint's batch shape.
            const results = [];
            for (const email of emails) {
                try {
                    const identity = await ckJsContainer().discoverUserIdentityWithEmailAddress(email);
                    results.push({ email, identity });
                } catch (error) {
                    results.push({ email, error: error.message });
                }
            }
            for (const recordName of userRecordNames) {
                try {
                    const identity = await ckJsContainer().discoverUserIdentityWithUserRecordName(recordName);
                    results.push({ userRecordName: recordName, identity });
                } catch (error) {
                    results.push({ userRecordName: recordName, error: error.message });
                }
            }
            return { discovered: results };
        },
    });
});
