// assets/rereference panel handler. The MistKit side is pending #31 —
// the 501 stub renders the pending banner. CloudKit JS composes the
// rereference as: fetch source → reuse CloudKit.Asset descriptor →
// save target.

const assetsStatus = document.getElementById('assets-status');
const assetsRaw = document.getElementById('assets-raw');

document.getElementById('assets-rereference-btn').addEventListener('click', async () => {
    const source = document.getElementById('assets-source').value.trim();
    const field = document.getElementById('assets-field').value.trim();
    const target = document.getElementById('assets-target').value.trim();
    const targetField = document.getElementById('assets-target-field').value.trim() || field;
    if (!source || !field || !target) {
        setStatus(assetsStatus, 'Provide source, asset field, and target.', 'error');
        return;
    }
    if (currentMode === 'mistkit') {
        setStatus(assetsStatus, 'Rereferencing…', 'loading');
        try {
            const payload = await postJSON('/api/assets/rereference', {
                sourceRecordName: source,
                assetField: field,
                targetRecordName: target,
                targetAssetField: targetField,
            });
            renderRaw(assetsRaw, payload);
            if (isPendingPayload(payload)) {
                renderPendingBanner(assetsStatus, payload);
            } else {
                setStatus(assetsStatus, 'Rereferenced.', 'success');
            }
        } catch (error) {
            const payload = error.payload || { message: error.message };
            renderRaw(assetsRaw, payload);
            if (isPendingPayload(payload)) {
                renderPendingBanner(assetsStatus, payload);
            } else {
                setStatus(assetsStatus, `Failed: ${error.message}`, 'error');
            }
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
        const assetDescriptor = sourceRecord.fields && sourceRecord.fields[field];
        if (!assetDescriptor) {
            throw new Error(`Field ${field} not present on source record.`);
        }
        setStatus(assetsStatus, 'Saving target with reused asset…', 'loading');
        const savePayload = await ckJsDatabase().saveRecords([{
            recordName: target,
            recordType: sourceRecord.recordType,
            fields: { [targetField]: assetDescriptor },
        }]);
        if (savePayload.hasErrors && savePayload.errors.length) {
            throw new Error(savePayload.errors[0].reason || 'Save target failed');
        }
        renderRaw(assetsRaw, { fetchSource: fetchPayload, saveTarget: savePayload });
        setStatus(assetsStatus, 'Rereferenced.', 'success');
    } catch (error) {
        renderRaw(assetsRaw, { message: error.message });
        setStatus(assetsStatus, `Failed: ${error.message}`, 'error');
    }
});
