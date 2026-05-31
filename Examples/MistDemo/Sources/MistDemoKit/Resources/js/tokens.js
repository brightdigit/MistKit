// tokens/create + tokens/register panel handler. The CloudKit JS SDK
// combines token creation and registration into a single
// `container.registerForNotifications()` call (and surfaces incoming
// notifications via `addNotificationListener`). MistKit-side hits the real
// /api/tokens (#52) and /api/tokens/register (#53) routes in sequence,
// feeding the minted token into the register step.

const tokensStatus = document.getElementById('tokens-status');
const tokensRaw = document.getElementById('tokens-raw');

// MistKit mode has no SDK listener, so we mirror CloudKit JS's
// `addNotificationListener` by hand: long-poll the `webcourierURL` returned by
// /api/tokens. The courier is consume-on-delivery (one notification per
// response, then it closes), so we re-fetch in a loop; an empty body is a
// keepalive/timeout — just poll again. (Verified wire format: see #379 and
// WEB_COURIER_SPIKE.md.)
//
// CAVEAT: this fetches cross-origin against Apple's courier host. CloudKit JS
// polls the same host from the browser, but if CORS blocks a hand-rolled fetch,
// route the poll through a server proxy instead (the server already holds the
// webcourierURL). The catch below surfaces that failure with a hint.
let courierListener = null;

function stopCourierListener() {
    if (courierListener) {
        courierListener.abort();
        courierListener = null;
    }
}

// Map the courier wire payload ({ aps, ck }) onto the documented
// CloudKit.Notification fields — the JS twin of Swift's CourierNotification.
function decodeCourierNotification(payload) {
    const ck = (payload && payload.ck) || {};
    const qry = ck.qry || {};
    const reasons = { 1: 'recordCreated', 2: 'recordUpdated', 3: 'recordDeleted' };
    return {
        notificationID: ck.nid,
        containerIdentifier: ck.cid,
        subscriptionID: qry.sid,
        recordName: qry.rid,
        zoneID: qry.zid,
        reason: reasons[qry.fo] || qry.fo,
        alertBody: payload && payload.aps && payload.aps.alert,
    };
}

async function listenOnCourier(webcourierURL) {
    stopCourierListener();
    const controller = new AbortController();
    courierListener = controller;
    while (!controller.signal.aborted) {
        let response;
        try {
            response = await fetch(webcourierURL, { signal: controller.signal });
        } catch (error) {
            if (controller.signal.aborted) { return; }
            renderRaw(tokensRaw, {
                courierError: error.message,
                hint: 'If this is a CORS failure, proxy the courier poll through the server.',
            });
            return;
        }
        const body = (await response.text()).trim();
        if (!body) { continue; } // keepalive/timeout — re-poll
        try {
            renderRaw(tokensRaw, { lastNotification: decodeCourierNotification(JSON.parse(body)) });
        } catch (_parseError) {
            renderRaw(tokensRaw, { lastNotificationRaw: body });
        }
    }
}

document.getElementById('tokens-register-btn').addEventListener('click', async () => {
    if (currentMode === 'mistkit') {
        // Both create + register are pending. Hit both 501s sequentially and
        // render the combined response so the asymmetry vs CloudKit JS is
        // visible on a single panel.
        setStatus(tokensStatus, 'Registering…', 'loading');
        const result = { create: null, register: null };
        try {
            result.create = await postJSON('/api/tokens', {});
        } catch (error) { result.create = error.payload || { message: error.message }; }
        // tokens/register takes the apnsToken minted by tokens/create — feed
        // the created token forward so the two-step REST flow is exercised
        // end-to-end (CloudKit JS rolls both into registerForNotifications()).
        const createdToken = result.create && result.create.apnsToken;
        const createdEnvironment =
            (result.create && result.create.apnsEnvironment) || 'development';
        try {
            result.register = await postJSON('/api/tokens/register',
                createdToken
                    ? { apnsToken: createdToken, apnsEnvironment: createdEnvironment }
                    : {});
        } catch (error) { result.register = error.payload || { message: error.message }; }
        renderRaw(tokensRaw, result);
        if (isPendingPayload(result.create) || isPendingPayload(result.register)) {
            renderPendingBanner(tokensStatus, result.create || result.register);
            return;
        }
        // Mirror registerForNotifications(): once the token is minted, start
        // listening on its courier URL so incoming pushes render live.
        const webcourierURL = result.create && result.create.webcourierURL;
        if (webcourierURL) {
            setStatus(tokensStatus, 'Registered — listening for notifications…', 'success');
            listenOnCourier(webcourierURL);
        } else {
            setStatus(tokensStatus, 'Registered.', 'success');
        }
        return;
    }

    setStatus(tokensStatus, 'Registering for notifications…', 'loading');
    try {
        // Switching to the SDK listener — stop any hand-rolled MistKit poll.
        stopCourierListener();
        const result = await ckJsContainer().registerForNotifications();
        renderRaw(tokensRaw, result);
        setStatus(tokensStatus, 'Registered.', 'success');
        try {
            ckJsContainer().addNotificationListener((notification) => {
                renderRaw(tokensRaw, { lastNotification: notification });
            });
        } catch (_listenerError) {
            // addNotificationListener is best-effort; older CloudKit JS
            // versions don't expose it. Don't fail the panel if the
            // listener wire-up fails.
        }
    } catch (error) {
        renderRaw(tokensRaw, { message: error.message });
        setStatus(tokensStatus, `Failed: ${error.message}`, 'error');
    }
});
