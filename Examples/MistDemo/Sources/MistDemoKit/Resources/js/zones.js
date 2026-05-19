// zones/list · zones/lookup · zones/modify · zones/changes panel handlers.
// All four endpoints have landed MistKit wrappers (#215, #45, #48, #367)
// but aren't yet exposed on the demo server; calls to the MistKit side
// hit 404 from the server until the corresponding /api/* routes wire in.
// CloudKit JS calls are fully exercisable today.

const zonesListStatus = document.getElementById('zones-list-status');
const zonesListRaw = document.getElementById('zones-list-raw');
const zonesLookupStatus = document.getElementById('zones-lookup-status');
const zonesLookupRaw = document.getElementById('zones-lookup-raw');
const zonesModifyStatus = document.getElementById('zones-modify-status');
const zonesModifyRaw = document.getElementById('zones-modify-raw');
const zonesChangesStatus = document.getElementById('zones-changes-status');
const zonesChangesRaw = document.getElementById('zones-changes-raw');

document.getElementById('zones-list-btn').addEventListener('click', async () => {
    await runPanelOperation({
        statusEl: zonesListStatus,
        rawEl: zonesListRaw,
        label: 'List zones',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/zones/list', { database: currentDatabase });
            }
            return await ckJsDatabase().fetchAllRecordZones();
        },
    });
});

document.getElementById('zones-lookup-btn').addEventListener('click', async () => {
    const zoneNames = csv(document.getElementById('zones-lookup-input').value);
    if (zoneNames.length === 0) {
        setStatus(zonesLookupStatus, 'Provide at least one zone name.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: zonesLookupStatus,
        rawEl: zonesLookupRaw,
        label: 'Lookup zones',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/zones/lookup', {
                    database: currentDatabase,
                    zoneNames,
                });
            }
            const zoneIDs = zoneNames.map(name => ({ zoneName: name }));
            return await ckJsDatabase().fetchRecordZones(zoneIDs);
        },
    });
});

document.getElementById('zones-modify-create-btn').addEventListener('click', async () => {
    const zoneName = document.getElementById('zones-modify-create').value.trim();
    if (zoneName.length === 0) {
        setStatus(zonesModifyStatus, 'Provide a zone name to create.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: zonesModifyStatus,
        rawEl: zonesModifyRaw,
        label: 'Create zone',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/zones/modify', {
                    database: currentDatabase,
                    create: [{ zoneName }],
                });
            }
            return await ckJsDatabase().saveRecordZones([{ zoneName }]);
        },
    });
});

document.getElementById('zones-modify-delete-btn').addEventListener('click', async () => {
    const zoneName = document.getElementById('zones-modify-delete').value.trim();
    if (zoneName.length === 0) {
        setStatus(zonesModifyStatus, 'Provide a zone name to delete.', 'error');
        return;
    }
    await runPanelOperation({
        statusEl: zonesModifyStatus,
        rawEl: zonesModifyRaw,
        label: 'Delete zone',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/zones/modify', {
                    database: currentDatabase,
                    delete: [{ zoneName }],
                });
            }
            return await ckJsDatabase().deleteRecordZones([{ zoneName }]);
        },
    });
});

document.getElementById('zones-changes-btn').addEventListener('click', async () => {
    const token = document.getElementById('zones-changes-token').value.trim() || undefined;
    await runPanelOperation({
        statusEl: zonesChangesStatus,
        rawEl: zonesChangesRaw,
        label: 'Zone changes',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/zones/changes', {
                    database: currentDatabase,
                    syncToken: token,
                });
            }
            // CloudKit JS doesn't expose a direct zones/changes — the
            // equivalent is composed per-zone via fetchRecordChanges, so
            // surface that pedagogical asymmetry inline.
            return {
                note: 'CloudKit JS exposes per-zone records/changes only — there is no direct zones/changes browser primitive.',
                composedFrom: 'database.fetchRecordChanges(zoneID, { previousServerChangeToken })',
            };
        },
    });
});
