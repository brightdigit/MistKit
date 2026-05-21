// CloudKit JS bootstrap + Apple ID auth flow. Polls the internal
// `_ckSession` token from the CloudKit JS container once the user signs
// in, then forwards it to `/api/authenticate` so the server can use it
// for MistKit-mode requests.

function setAuthed(authed) {
    authComplete = authed;
    document.querySelectorAll('.pre-auth').forEach(card => {
        card.classList.toggle('pre-auth', !authed);
    });
    signoutButton.style.display = authed ? 'inline-block' : 'none';
}

async function loadServerConfig() {
    const response = await fetch('/api/config');
    if (!response.ok) throw new Error('Failed to load server config: ' + response.status);
    return response.json();
}

async function pollWebAuthToken() {
    const pollIntervalMs = 250;
    const pollDeadlineMs = 10_000;
    const pollStart = Date.now();
    return new Promise((resolve, reject) => {
        const handle = setInterval(() => {
            const token = container?._auth?._ckSession;
            if (token) {
                clearInterval(handle);
                resolve(token);
                return;
            }
            if (Date.now() - pollStart >= pollDeadlineMs) {
                clearInterval(handle);
                reject(new Error('Timeout waiting for web auth token'));
            }
        }, pollIntervalMs);
    });
}

async function postAuthenticate(userIdentity, token) {
    const response = await fetch('/api/authenticate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            sessionToken: token,
            userRecordName: userIdentity.userRecordName,
        }),
    });
    if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
    }
    return response.status;
}

function renderTokenDisplay(token) {
    notesCard.style.display = 'none';
    document.getElementById('signin-area').style.display = 'none';
    const card = document.createElement('div');
    card.className = 'card';
    card.innerHTML = `
        <h2>Web Auth Token captured</h2>
        <p>Use this token for command-line CloudKit API access:</p>
        <pre style="user-select: all; padding: 12px; background: #f6f8fa; border-radius: 6px; word-break: break-all; white-space: pre-wrap;">${token}</pre>
        <p>The server has shut down — you can close this window.</p>
    `;
    document.querySelector('.layout').appendChild(card);
}

async function handleAuthentication(userIdentity) {
    if (authenticationInProgress) return;
    authenticationInProgress = true;
    currentUserRecordName = userIdentity?.userRecordName ?? null;
    setStatus(authStatusDiv, 'Capturing web auth token...', 'success');
    try {
        const token = await pollWebAuthToken();
        webAuthToken = token;
        const status = await postAuthenticate(userIdentity, token);
        if (status === 205) {
            setStatus(authStatusDiv, 'Authentication complete.', 'success');
            renderTokenDisplay(token);
        } else {
            setStatus(authStatusDiv, `Authenticated as ${userIdentity.userRecordName}.`, 'success');
            setAuthed(true);
            queryNotes();
        }
    } catch (error) {
        setStatus(authStatusDiv, `Authentication failed: ${error.message}`, 'error');
    } finally {
        authenticationInProgress = false;
    }
}

signoutButton.addEventListener('click', async () => {
    try {
        await container.signOut();
        webAuthToken = null;
        currentUserRecordName = null;
        setAuthed(false);
        notes = [];
        clearForm();
        setStatus(authStatusDiv, 'Signed out.', 'success');
    } catch (error) {
        setStatus(authStatusDiv, 'Sign out failed: ' + error.message, 'error');
    }
});

async function initializeCloudKit() {
    try {
        if (typeof CloudKit === 'undefined') {
            throw new Error('CloudKit.js failed to load');
        }
        const serverConfig = await loadServerConfig();
        publicDatabaseAvailable = !!serverConfig.publicDatabaseAvailable;
        refreshDatabasePicker();
        CloudKit.configure({
            containers: [{
                containerIdentifier: serverConfig.containerIdentifier,
                apiTokenAuth: {
                    apiToken: serverConfig.apiToken,
                    persist: true,
                    signInButton: { id: 'signin-button', theme: 'black' },
                },
                environment: serverConfig.environment || 'development',
            }],
        });
        container = CloudKit.getDefaultContainer();
        const userIdentity = await container.setUpAuth();
        if (userIdentity) {
            setStatus(authStatusDiv, 'Already signed in. Capturing token...', 'success');
            await handleAuthentication(userIdentity);
        } else {
            setStatus(authStatusDiv, 'Click "Sign In with Apple ID" to authenticate.', 'success');
        }
        container.whenUserSignsIn().then((identity) => handleAuthentication(identity));
        container.whenUserSignsOut().then(() => {
            webAuthToken = null;
            currentUserRecordName = null;
            setAuthed(false);
            notes = [];
            clearForm();
            setStatus(authStatusDiv, 'Signed out.', 'success');
        });
    } catch (error) {
        setStatus(authStatusDiv, 'CloudKit setup failed: ' + error.message, 'error');
    }
}

initializeCloudKit();
