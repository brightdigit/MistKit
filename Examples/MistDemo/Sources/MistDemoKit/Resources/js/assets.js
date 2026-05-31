// assets/rereference handler embedded in the Notes panel. The asset field
// is fixed to `image` since the Notes schema has a single ASSET field, so
// the UI only asks for source + target record names. MistKit POSTs to
// /api/assets/rereference (server composes assets/rereference +
// records/modify); CloudKit JS composes the same flow client-side: fetch
// source → reuse CloudKit.Asset descriptor → save target.

const assetsTargetInput = document.getElementById('assets-target');
const assetsStatus = document.getElementById('assets-status');
const assetsRaw = document.getElementById('assets-raw');
const ASSET_FIELD = 'image';

document.getElementById('assets-rereference-btn').addEventListener('click', async () => {
    const source = document.getElementById('assets-source')?.value.trim() ?? '';
    const target = assetsTargetInput.value.trim();
    if (!source || !target) {
        setStatus(assetsStatus, 'Provide both a source and a target record name.', 'error');
        return;
    }
    if (source === target) {
        setStatus(assetsStatus, 'Source and target must be different records.', 'error');
        return;
    }
    if (currentMode === 'mistkit') {
        setStatus(assetsStatus, 'Rereferencing…', 'loading');
        try {
            const payload = await postJSON('/api/assets/rereference', {
                sourceRecordName: source,
                assetField: ASSET_FIELD,
                targetRecordName: target,
                targetAssetField: ASSET_FIELD,
                database: currentDatabase,
            });
            renderRaw(assetsRaw, payload);
            setStatus(assetsStatus, `Rereferenced onto ${target}.`, 'success');
            await queryNotes();
        } catch (error) {
            const payload = error.payload || { message: error.message };
            renderRaw(assetsRaw, payload);
            setStatus(assetsStatus, `Failed: ${error.message}`, 'error');
        }
        return;
    }
    setStatus(assetsStatus, 'Fetching source record…', 'loading');
    try {
        const fetchPayload = await ckJsDatabase().fetchRecords([source]);
        if (fetchPayload.hasErrors && fetchPayload.errors.length) {
            throw new Error(fetchPayload.errors[0].reason || 'Fetch source failed');
        }
        const sourceRecord = (fetchPayload.records || [])[0];
        if (!sourceRecord) throw new Error(`Source record ${source} not found.`);
        const assetDescriptor = sourceRecord.fields && sourceRecord.fields[ASSET_FIELD];
        if (!assetDescriptor) {
            throw new Error(`Field ${ASSET_FIELD} not present on source record.`);
        }
        setStatus(assetsStatus, 'Saving target with reused asset…', 'loading');
        const savePayload = await ckJsDatabase().saveRecords([{
            recordName: target,
            recordType: sourceRecord.recordType,
            fields: { [ASSET_FIELD]: assetDescriptor },
        }]);
        if (savePayload.hasErrors && savePayload.errors.length) {
            throw new Error(savePayload.errors[0].reason || 'Save target failed');
        }
        renderRaw(assetsRaw, { fetchSource: fetchPayload, saveTarget: savePayload });
        setStatus(assetsStatus, `Rereferenced onto ${target}.`, 'success');
        await queryNotes();
    } catch (error) {
        renderRaw(assetsRaw, { message: error.message });
        setStatus(assetsStatus, `Failed: ${error.message}`, 'error');
    }
});
