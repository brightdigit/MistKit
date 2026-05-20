// records/lookup · records/changes · records/resolve panel handlers.
// records/query and records/modify are wired in app.js (Notes CRUD).

const recordsLookupInput = document.getElementById('records-lookup-input');
const recordsLookupStatus = document.getElementById('records-lookup-status');
const recordsLookupRaw = document.getElementById('records-lookup-raw');

document.getElementById('records-lookup-btn').addEventListener('click', async () => {
    const names = csv(recordsLookupInput.value);
    if (names.length === 0) {
        setStatus(recordsLookupStatus, 'Provide at least one record name.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: recordsLookupStatus,
        rawEl: recordsLookupRaw,
        label: 'Lookup',
        fn: async () => {
            if (currentMode === 'mistkit') {
                // records/lookup MistKit wrapper is implemented but isn't
                // exposed on the demo server yet — surface that asymmetry
                // by returning a pending banner inline.
                return await postJSON('/api/records/lookup', {
                    database: currentDatabase,
                    recordNames: names,
                });
            }
            const payload = await ckJsDatabase().fetchRecords(names);
            if (payload && payload.hasErrors && payload.errors.length) {
                throw new Error(payload.errors[0].reason || 'CloudKit JS lookup failed');
            }
            return payload;
        },
    });
});

const recordsChangesZone = document.getElementById('records-changes-zone');
const recordsChangesToken = document.getElementById('records-changes-token');
const recordsChangesStatus = document.getElementById('records-changes-status');
const recordsChangesRaw = document.getElementById('records-changes-raw');

document.getElementById('records-changes-btn').addEventListener('click', async () => {
    const zoneName = recordsChangesZone.value.trim() || '_defaultZone';
    const syncToken = recordsChangesToken.value.trim() || undefined;
    await runPanelOperation({
        statusEl: recordsChangesStatus,
        rawEl: recordsChangesRaw,
        label: 'Fetch changes',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/records/changes', {
                    database: currentDatabase,
                    zoneName,
                    syncToken,
                });
            }
            const payload = await ckJsDatabase().fetchRecordZoneChanges({
                zoneID: { zoneName },
                syncToken,
            });
            if (payload && payload.hasErrors && payload.errors.length) {
                throw new Error(payload.errors[0].reason || 'CloudKit JS changes failed');
            }
            return payload;
        },
    });
});

const recordsResolveInput = document.getElementById('records-resolve-input');
const recordsResolveStatus = document.getElementById('records-resolve-status');
const recordsResolveRaw = document.getElementById('records-resolve-raw');

document.getElementById('records-resolve-btn').addEventListener('click', async () => {
    const value = recordsResolveInput.value.trim();
    if (value.length === 0) {
        setStatus(recordsResolveStatus, 'Provide a record name or share URL.', 'error');
        return;
    }
    const isURL = /^https?:\/\//i.test(value);
    if (currentMode === 'mistkit') {
        // records/resolve MistKit wrapper isn't landed yet (#41). Hit the
        // 501 stub to render the pending banner.
        setStatus(recordsResolveStatus, 'Resolve…', 'loading');
        try {
            const payload = await postJSON('/api/records/resolve', { input: value });
            renderRaw(recordsResolveRaw, payload);
            if (isPendingPayload(payload)) {
                renderPendingBanner(recordsResolveStatus, payload);
            } else {
                setStatus(recordsResolveStatus, 'Resolve succeeded.', 'success');
            }
        } catch (error) {
            const payload = error.payload || { message: error.message };
            renderRaw(recordsResolveRaw, payload);
            if (isPendingPayload(payload)) {
                renderPendingBanner(recordsResolveStatus, payload);
            } else {
                setStatus(recordsResolveStatus, `Resolve failed: ${error.message}`, 'error');
            }
        }
        return;
    }
    // CloudKit JS composed call — branch on input shape.
    await runPanelOperation({
        statusEl: recordsResolveStatus,
        rawEl: recordsResolveRaw,
        label: isURL ? 'Resolve share URL' : 'Resolve record name',
        fn: async () => {
            if (isURL) {
                const payload = await ckJsContainer().fetchShareMetadataWithURL({ shareURL: value });
                return { branch: 'shareURL', payload };
            }
            const payload = await ckJsDatabase().fetchRecords([value]);
            if (payload && payload.hasErrors && payload.errors.length) {
                throw new Error(payload.errors[0].reason || 'CloudKit JS resolve failed');
            }
            return { branch: 'recordName', payload };
        },
    });
});
