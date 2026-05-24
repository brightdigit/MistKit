// tokens/create + tokens/register panel handler. The CloudKit JS SDK
// combines token creation and registration into a single
// `container.registerForNotifications()` call (and surfaces incoming
// notifications via `addNotificationListener`). MistKit-side hits the real
// /api/tokens (#52) and /api/tokens/register (#53) routes in sequence,
// feeding the minted token into the register step.

const tokensStatus = document.getElementById('tokens-status');
const tokensRaw = document.getElementById('tokens-raw');

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
        try {
            result.register = await postJSON('/api/tokens/register',
                createdToken ? { apnsToken: createdToken } : {});
        } catch (error) { result.register = error.payload || { message: error.message }; }
        renderRaw(tokensRaw, result);
        if (isPendingPayload(result.create) || isPendingPayload(result.register)) {
            renderPendingBanner(tokensStatus, result.create || result.register);
        } else {
            setStatus(tokensStatus, 'Registered.', 'success');
        }
        return;
    }

    setStatus(tokensStatus, 'Registering for notifications…', 'loading');
    try {
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
