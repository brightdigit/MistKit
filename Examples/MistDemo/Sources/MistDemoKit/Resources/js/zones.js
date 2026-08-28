// zones/list · zones/lookup · zones/modify · changes/database · changes/zone
// panel handlers. All five endpoints are wired on the demo server in MistKit
// mode; CloudKit JS mode hits the browser SDK directly.

const zonesListStatus = document.getElementById('zones-list-status');
const zonesListRaw = document.getElementById('zones-list-raw');
const zonesListTbody = document.getElementById('zones-list-tbody');
const zonesLookupStatus = document.getElementById('zones-lookup-status');
const zonesLookupRaw = document.getElementById('zones-lookup-raw');
const zonesModifyStatus = document.getElementById('zones-modify-status');
const zonesModifyRaw = document.getElementById('zones-modify-raw');
const zonesChangesStatus = document.getElementById('zones-changes-status');
const zonesChangesRaw = document.getElementById('zones-changes-raw');
const zonesChangesUseZonesBtn = document.getElementById('zones-changes-use-zones-btn');
const zonesRecordChangesZones = document.getElementById('zones-record-changes-zones');
const zonesRecordChangesToken = document.getElementById('zones-record-changes-token');
const zonesRecordChangesStatus = document.getElementById('zones-record-changes-status');
const zonesRecordChangesRaw = document.getElementById('zones-record-changes-raw');

// Last successful changes/database payload — powers "Use changed zones →".
let lastDatabaseChangesPayload = null;

function zoneNameFromEntry(entry) {
    if (!entry) return null;
    if (entry.zoneName) return entry.zoneName;
    if (entry.zoneID && entry.zoneID.zoneName) return entry.zoneID.zoneName;
    if (entry.zone && entry.zone.zoneName) return entry.zone.zoneName;
    return null;
}

function changedZoneNamesFromDatabaseChanges(payload) {
    const zones = (payload && payload.zones) || [];
    if (!Array.isArray(zones)) return [];
    return zones.map(zoneNameFromEntry).filter(Boolean);
}

function updateUseChangedZonesButton() {
    if (!zonesChangesUseZonesBtn) return;
    const names = changedZoneNamesFromDatabaseChanges(lastDatabaseChangesPayload);
    zonesChangesUseZonesBtn.disabled = names.length === 0;
}

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
    const payload = await runPanelOperation({
        statusEl: zonesChangesStatus,
        rawEl: zonesChangesRaw,
        label: 'Database changes',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/zones/changes', {
                    database: currentDatabase,
                    syncToken: token,
                });
            }
            // CloudKit JS exposes `fetchDatabaseChanges` (changed record zones),
            // the closest analog to REST `changes/database`.
            return await ckJsDatabase().fetchDatabaseChanges({ syncToken: token });
        },
    });
    if (payload) {
        lastDatabaseChangesPayload = payload;
        updateUseChangedZonesButton();
    }
});

if (zonesChangesUseZonesBtn) {
    zonesChangesUseZonesBtn.addEventListener('click', () => {
        const names = changedZoneNamesFromDatabaseChanges(lastDatabaseChangesPayload);
        if (names.length === 0) {
            setStatus(zonesChangesStatus, 'No changed zones in the last database-changes response.', 'error');
            return;
        }
        if (zonesRecordChangesZones) {
            zonesRecordChangesZones.value = names.join(', ');
        }
        setStatus(
            zonesChangesStatus,
            `Prefilled ${names.length} zone name(s) for changes/zone.`,
            'success'
        );
    });
}

document.getElementById('zones-record-changes-btn').addEventListener('click', async () => {
    const zoneNames = csv(zonesRecordChangesZones.value);
    if (zoneNames.length === 0) {
        setStatus(zonesRecordChangesStatus, 'Provide at least one zone name.', 'error');
        return;
    }
    const syncToken = zonesRecordChangesToken.value.trim() || undefined;
    await runPanelOperation({
        statusEl: zonesRecordChangesStatus,
        rawEl: zonesRecordChangesRaw,
        label: 'Zone record changes',
        fn: async () => {
            if (currentMode === 'mistkit') {
                return await postJSON('/api/changes/zone', {
                    database: currentDatabase,
                    zones: zoneNames.map(zoneName => ({
                        zoneName,
                        syncToken,
                    })),
                });
            }
            const results = [];
            for (const zoneName of zoneNames) {
                const payload = await ckJsDatabase().fetchRecordZoneChanges({
                    zoneID: { zoneName },
                    syncToken,
                });
                if (payload && payload.hasErrors && payload.errors.length) {
                    throw new Error(payload.errors[0].reason || `CloudKit JS changes failed for ${zoneName}`);
                }
                results.push({ zoneName, payload });
            }
            return { zones: results };
        },
    });
});
