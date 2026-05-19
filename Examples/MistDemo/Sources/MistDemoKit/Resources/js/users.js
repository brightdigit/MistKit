// users/caller · users/discover · users/lookup/email · users/lookup/id
// panel handlers. All four MistKit wrappers landed in #215 but aren't
// exposed on the demo server yet; CloudKit JS fully exercises every
// endpoint today.

const usersCallerStatus = document.getElementById('users-caller-status');
const usersCallerRaw = document.getElementById('users-caller-raw');
const usersEmailStatus = document.getElementById('users-email-status');
const usersEmailRaw = document.getElementById('users-email-raw');
const usersIdStatus = document.getElementById('users-id-status');
const usersIdRaw = document.getElementById('users-id-raw');
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
            return await ckJsContainer().fetchUserIdentityMe();
        },
    });
});

document.getElementById('users-email-btn').addEventListener('click', async () => {
    const email = document.getElementById('users-email-input').value.trim();
    if (!email) {
        setStatus(usersEmailStatus, 'Provide an email address.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: usersEmailStatus,
        rawEl: usersEmailRaw,
        label: 'Lookup by email',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/users/lookup/email', { emails: [email] });
            }
            return await ckJsContainer().discoverUserIdentity({ emailAddress: email });
        },
    });
});

document.getElementById('users-id-btn').addEventListener('click', async () => {
    const recordName = document.getElementById('users-id-input').value.trim();
    if (!recordName) {
        setStatus(usersIdStatus, 'Provide a user record name.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: usersIdStatus,
        rawEl: usersIdRaw,
        label: 'Lookup by record name',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/users/lookup/id', { userRecordNames: [recordName] });
            }
            return await ckJsContainer().discoverUserIdentity({ userRecordName: recordName });
        },
    });
});

document.getElementById('users-discover-btn').addEventListener('click', async () => {
    const emails = csv(document.getElementById('users-discover-input').value);
    if (emails.length === 0) {
        setStatus(usersDiscoverStatus, 'Provide at least one email.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: usersDiscoverStatus,
        rawEl: usersDiscoverRaw,
        label: 'Discover users',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/users/discover', { emails });
            }
            // CloudKit JS exposes a per-email primitive — loop and aggregate
            // to match the REST endpoint's batch shape.
            const results = [];
            for (const email of emails) {
                try {
                    const identity = await ckJsContainer().discoverUserIdentity({ emailAddress: email });
                    results.push({ email, identity });
                } catch (error) {
                    results.push({ email, error: error.message });
                }
            }
            return { discovered: results };
        },
    });
});
