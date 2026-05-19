// subscriptions/list · subscriptions/lookup panel handlers. MistKit
// side returns 501 (pending #49 / #50); CloudKit JS side hits the real
// browser SDK primitives.

const subsListStatus = document.getElementById('subs-list-status');
const subsListRaw = document.getElementById('subs-list-raw');
const subsLookupStatus = document.getElementById('subs-lookup-status');
const subsLookupRaw = document.getElementById('subs-lookup-raw');

document.getElementById('subs-list-btn').addEventListener('click', async () => {
    setStatus(subsListStatus, 'Fetching…', 'loading');
    try {
        if (currentMode === 'mistkit') {
            try {
                const payload = await fetchJSON('/api/subscriptions');
                renderRaw(subsListRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsListStatus, payload);
                } else {
                    setStatus(subsListStatus, 'Loaded.', 'success');
                }
            } catch (error) {
                const payload = error.payload || { message: error.message };
                renderRaw(subsListRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsListStatus, payload);
                } else {
                    setStatus(subsListStatus, `Failed: ${error.message}`, 'error');
                }
            }
            return;
        }
        const payload = await ckJsDatabase().fetchAllSubscriptions();
        renderRaw(subsListRaw, payload);
        setStatus(subsListStatus, 'Loaded.', 'success');
    } catch (error) {
        renderRaw(subsListRaw, { message: error.message });
        setStatus(subsListStatus, `Failed: ${error.message}`, 'error');
    }
});

document.getElementById('subs-lookup-btn').addEventListener('click', async () => {
    const ids = csv(document.getElementById('subs-lookup-input').value);
    if (ids.length === 0) {
        setStatus(subsLookupStatus, 'Provide at least one subscription ID.', 'error');
        return;
    }
    setStatus(subsLookupStatus, 'Looking up…', 'loading');
    try {
        if (currentMode === 'mistkit') {
            try {
                const payload = await fetchJSON(`/api/subscriptions/${encodeURIComponent(ids[0])}`);
                renderRaw(subsLookupRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsLookupStatus, payload);
                } else {
                    setStatus(subsLookupStatus, 'Loaded.', 'success');
                }
            } catch (error) {
                const payload = error.payload || { message: error.message };
                renderRaw(subsLookupRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsLookupStatus, payload);
                } else {
                    setStatus(subsLookupStatus, `Failed: ${error.message}`, 'error');
                }
            }
            return;
        }
        const payload = await ckJsDatabase().fetchSubscriptions(ids);
        renderRaw(subsLookupRaw, payload);
        setStatus(subsLookupStatus, 'Loaded.', 'success');
    } catch (error) {
        renderRaw(subsLookupRaw, { message: error.message });
        setStatus(subsLookupStatus, `Failed: ${error.message}`, 'error');
    }
});
