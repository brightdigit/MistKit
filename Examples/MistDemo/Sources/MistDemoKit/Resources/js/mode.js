// Mode + database toggles. Reads `currentMode` / `currentDatabase` /
// `publicDatabaseAvailable` set in app.js and updates the picker
// disabled-state + banner copy.

document.getElementById('mode-mistkit').addEventListener('click', () => setMode('mistkit'));
document.getElementById('mode-cloudkitjs').addEventListener('click', () => setMode('cloudkitjs'));

function setMode(mode) {
    if (mode === currentMode) return;
    currentMode = mode;
    document.getElementById('mode-mistkit').classList.toggle('active', mode === 'mistkit');
    document.getElementById('mode-cloudkitjs').classList.toggle('active', mode === 'cloudkitjs');
    modeBadge.textContent = mode === 'mistkit' ? 'MistKit' : 'CloudKit JS';
    refreshDatabasePicker();
    if (authComplete) queryNotes();
}

dbPrivateBtn.addEventListener('click', () => setDatabase('private'));
dbPublicBtn.addEventListener('click', () => setDatabase('public'));

function setDatabase(database) {
    if (database === currentDatabase) return;
    if (database === 'public' && !isPublicAllowedForCurrentMode()) {
        return;
    }
    currentDatabase = database;
    refreshDatabasePicker();
    if (authComplete) queryNotes();
}

function isPublicAllowedForCurrentMode() {
    return currentMode === 'cloudkitjs' || publicDatabaseAvailable;
}

function refreshDatabasePicker() {
    const publicAllowed = isPublicAllowedForCurrentMode();
    dbPublicBtn.disabled = !publicAllowed;
    if (!publicAllowed && currentDatabase === 'public') {
        currentDatabase = 'private';
    }
    dbPrivateBtn.classList.toggle('active', currentDatabase === 'private');
    dbPublicBtn.classList.toggle('active', currentDatabase === 'public');
    dbBadge.textContent = currentDatabase === 'public' ? 'Public' : 'Private';
    if (!publicDatabaseAvailable && currentMode === 'mistkit') {
        dbHint.textContent =
            'MistKit + Public requires server-to-server credentials ' +
            '(CLOUDKIT_KEY_ID + CLOUDKIT_PRIVATE_KEY[_PATH]). ' +
            'Restart the server with those set to enable Public on this side.';
    } else if (currentMode === 'mistkit' && currentDatabase === 'public') {
        dbHint.textContent =
            'Heads-up: on MistKit + Public, records you write are owned ' +
            'by the server-to-server key, not your iCloud user — so they ' +
            'won’t carry a "You" badge.';
    } else {
        dbHint.textContent =
            'Private uses the captured Apple ID web-auth token; Public ' +
            'uses server-to-server signing on the MistKit side and the ' +
            'API token on the CloudKit JS side.';
    }
}

refreshDatabasePicker();
