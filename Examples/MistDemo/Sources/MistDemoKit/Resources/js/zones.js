// zones/list · zones/lookup · zones/modify · zones/changes panel handlers.
// zones/modify is wired on the demo server (POST /api/zones/modify), so the
// MistKit-mode Create/Delete buttons hit the real CloudKitService. The other
// three (list/lookup/changes) have landed MistKit wrappers (#215, #45, #48,
// #367) but aren't yet exposed on the server, so MistKit-mode calls to them
// still 404. CloudKit JS calls are fully exercisable today.

const zonesListStatus = document.getElementById('zones-list-status');
const zonesListRaw = document.getElementById('zones-list-raw');
const zonesListTbody = document.getElementById('zones-list-tbody');
const zonesLookupStatus = document.getElementById('zones-lookup-status');
const zonesLookupRaw = document.getElementById('zones-lookup-raw');
const zonesModifyStatus = document.getElementById('zones-modify-status');
const zonesModifyRaw = document.getElementById('zones-modify-raw');
const zonesChangesStatus = document.getElementById('zones-changes-status');
const zonesChangesRaw = document.getElementById('zones-changes-raw');

// Both the MistKit (`/api/zones/list`) and CloudKit JS
// (`fetchAllRecordZones`) responses wrap the zone array under `zones`;
// CloudKit JS nests the name under `zoneID.zoneName`, MistKit returns a
// flat `zoneName`, so read both.
function renderZonesTable(payload) {
    const zones = (payload && payload.zones) || [];
    renderListTable(zonesListTbody, [
        z => (z.zoneID && z.zoneID.zoneName) ?? z.zoneName,
        z => z.zoneID && z.zoneID.ownerRecordName,
        z => (z.atomic != null ? String(z.atomic) : ''),
    ], Array.isArray(zones) ? zones : [], 'No zones found.');
}

document.getElementById('zones-list-btn').addEventListener('click', async () => {
    const payload = await runPanelOperation({
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
    if (payload) renderZonesTable(payload);
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
            return await ckJsDatabase().saveRecordZones([{ zoneID: { zoneName } }]);
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
            // CloudKit JS does expose a database-level changes primitive
            // (`fetchDatabaseChanges`, returning changed record zones), which
            // is the closest analog to the REST zones/changes endpoint.
            return await ckJsDatabase().fetchDatabaseChanges({ syncToken: token });
        },
    });
});
