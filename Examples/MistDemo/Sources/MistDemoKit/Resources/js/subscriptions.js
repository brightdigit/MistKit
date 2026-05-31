// subscriptions/list · subscriptions/lookup · subscriptions/modify panel
// handlers. MistKit side hits the real /api/subscriptions* routes
// (#49/#50/#51); CloudKit JS side hits the browser SDK primitives. The
// pending-banner branches remain as a defensive fallback.

const subsListStatus = document.getElementById('subs-list-status');
const subsListRaw = document.getElementById('subs-list-raw');
const subsListTbody = document.getElementById('subs-list-tbody');
const subsLookupStatus = document.getElementById('subs-lookup-status');
const subsLookupRaw = document.getElementById('subs-lookup-raw');

// CloudKit JS `fetchAllSubscriptions` resolves to `{ subscriptions: [...] }`;
// the MistKit route (pending #49) will mirror that shape. Each subscription
// carries `subscriptionID`, `subscriptionType`, and an optional `query`
// (record-type subscriptions) and `zoneID` (zone subscriptions).
function renderSubscriptionsTable(payload) {
    const subs = (payload && payload.subscriptions) || [];
    renderListTable(subsListTbody, [
        s => s.subscriptionID ?? s.subscriptionId,
        s => s.subscriptionType,
        s => s.query && s.query.recordType,
        s => s.zoneID && s.zoneID.zoneName,
    ], Array.isArray(subs) ? subs : [], 'No subscriptions found.');
}

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
                    renderSubscriptionsTable(payload);
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
        renderSubscriptionsTable(payload);
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

// ---- Create (subscriptions/modify) ----

const subsCreateType = document.getElementById('subs-create-type');
const subsCreateQueryFields = document.getElementById('subs-create-query-fields');
const subsCreateZoneFields = document.getElementById('subs-create-zone-fields');
const subsCreateStatus = document.getElementById('subs-create-status');
const subsCreateRaw = document.getElementById('subs-create-raw');

// Toggle the type-specific input row to match the selected subscription type.
function refreshSubsCreateFields() {
    const isZone = subsCreateType.value === 'zone';
    subsCreateQueryFields.style.display = isZone ? 'none' : '';
    subsCreateZoneFields.style.display = isZone ? '' : 'none';
}
subsCreateType.addEventListener('change', refreshSubsCreateFields);
refreshSubsCreateFields();

// Build a CloudKit.Subscription dictionary from the form. Throws with a
// user-facing message when a required field for the chosen type is missing.
function buildSubscription() {
    const type = subsCreateType.value;
    const id = document.getElementById('subs-create-id').value.trim();
    const subscription = { subscriptionType: type };
    if (id) subscription.subscriptionID = id;
    if (type === 'zone') {
        const zoneName = document.getElementById('subs-create-zone').value.trim();
        if (!zoneName) throw new Error('Provide a zone name.');
        subscription.zoneID = { zoneName };
    } else {
        const recordType = document.getElementById('subs-create-record-type').value;
        const firesOn = Array.from(
            document.querySelectorAll('.subs-fires-on:checked')
        ).map(cb => cb.value);
        if (!firesOn.length) throw new Error('Select at least one "Fires on" operation.');
        subscription.firesOn = firesOn;
        subscription.query = { recordType };
    }
    return subscription;
}

document.getElementById('subs-create-btn').addEventListener('click', async () => {
    let subscription;
    try {
        subscription = buildSubscription();
    } catch (error) {
        setStatus(subsCreateStatus, error.message, 'error');
        return;
    }
    setStatus(subsCreateStatus, 'Creating…', 'loading');
    try {
        if (currentMode === 'mistkit') {
            // subscriptions/modify MistKit wrapper isn't landed yet (#51) —
            // hit the 501 stub and render the pending banner inline.
            try {
                const payload = await postJSON('/api/subscriptions/modify', subscription);
                renderRaw(subsCreateRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsCreateStatus, payload);
                } else {
                    setStatus(subsCreateStatus, 'Created.', 'success');
                }
            } catch (error) {
                const payload = error.payload || { message: error.message };
                renderRaw(subsCreateRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsCreateStatus, payload);
                } else {
                    setStatus(subsCreateStatus, `Failed: ${error.message}`, 'error');
                }
            }
            return;
        }
        const payload = await ckJsDatabase().saveSubscriptions(subscription);
        renderRaw(subsCreateRaw, payload);
        if (payload && payload.hasErrors && payload.errors.length) {
            throw new Error(payload.errors[0].reason || 'CloudKit JS save subscription failed');
        }
        setStatus(subsCreateStatus, 'Created.', 'success');
    } catch (error) {
        renderRaw(subsCreateRaw, error.payload || { message: error.message });
        setStatus(subsCreateStatus, `Failed: ${error.message}`, 'error');
    }
});

// ---- Delete (subscriptions/modify) ----

const subsDeleteStatus = document.getElementById('subs-delete-status');
const subsDeleteRaw = document.getElementById('subs-delete-raw');

document.getElementById('subs-delete-btn').addEventListener('click', async () => {
    const ids = csv(document.getElementById('subs-delete-input').value);
    if (ids.length === 0) {
        setStatus(subsDeleteStatus, 'Provide at least one subscription ID.', 'error');
        return;
    }
    setStatus(subsDeleteStatus, 'Deleting…', 'loading');
    try {
        if (currentMode === 'mistkit') {
            // CloudKit Web Services models delete as part of subscriptions/modify,
            // whose MistKit wrapper isn't landed yet (#51) — hit the 501 stub.
            try {
                const payload = await postJSON('/api/subscriptions/modify', {
                    delete: ids.map(id => ({ subscriptionID: id })),
                });
                renderRaw(subsDeleteRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsDeleteStatus, payload);
                } else {
                    setStatus(subsDeleteStatus, 'Deleted.', 'success');
                }
            } catch (error) {
                const payload = error.payload || { message: error.message };
                renderRaw(subsDeleteRaw, payload);
                if (isPendingPayload(payload)) {
                    renderPendingBanner(subsDeleteStatus, payload);
                } else {
                    setStatus(subsDeleteStatus, `Failed: ${error.message}`, 'error');
                }
            }
            return;
        }
        const payload = await ckJsDatabase().deleteSubscriptions(ids);
        renderRaw(subsDeleteRaw, payload);
        if (payload && payload.hasErrors && payload.errors.length) {
            throw new Error(payload.errors[0].reason || 'CloudKit JS delete subscription failed');
        }
        setStatus(subsDeleteStatus, 'Deleted.', 'success');
    } catch (error) {
        renderRaw(subsDeleteRaw, error.payload || { message: error.message });
        setStatus(subsDeleteStatus, `Failed: ${error.message}`, 'error');
    }
});
