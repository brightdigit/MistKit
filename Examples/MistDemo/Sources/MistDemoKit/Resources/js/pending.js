// Render the standard "pending #N" banner. Used by panel modules that
// hit endpoints whose MistKit Swift wrapper hasn't landed yet — the
// server returns 501 with a JSON body containing `endpoint` + `tracking`,
// and this module formats that into a yellow advisory above the raw
// response area.

function renderPendingBanner(statusEl, payload) {
    if (!statusEl) return;
    const endpoint = (payload && payload.endpoint) || 'unknown';
    const tracking = (payload && payload.tracking) || '#?';
    const msg =
        `MistKit support pending for ${endpoint} — tracked in ${tracking}. ` +
        `Switch to CloudKit JS mode to exercise this endpoint today.`;
    statusEl.className = 'status error';
    statusEl.textContent = msg;
    statusEl.style.display = 'block';
}

// Treat the structured 501 body as a "pending"  response rather than a
// hard error so the panel surfaces the asymmetry visibly. Returns true
// if the payload is a pending-stub body.
function isPendingPayload(payload) {
    return payload
        && typeof payload === 'object'
        && payload.error === 'not_implemented'
        && typeof payload.endpoint === 'string'
        && typeof payload.tracking === 'string';
}
