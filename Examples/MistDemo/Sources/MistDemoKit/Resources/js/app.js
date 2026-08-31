// Shared globals + helpers for the MistDemo web page.
//
// Each operation module (records.js, zones.js, etc.) reads `currentMode` /
// `currentDatabase` set here, and calls these helpers to render output to
// per-panel `<div class="status">` and `<pre>` elements. This module also
// owns the existing Notes CRUD panel — it's the originating shape every
// new panel mirrors.

let container = null;
let webAuthToken = null;
let authenticationInProgress = false;
let currentMode = 'mistkit';            // 'mistkit' | 'cloudkitjs'
let currentDatabase = 'private';        // 'private' | 'public'
let publicDatabaseAvailable = false;
let notes = [];
let selectedRecordName = null;
let authComplete = false;
let queryInFlight = false;
let currentUserRecordName = null;
let currentSort = { field: '___createTime', ascending: false };
const REFRESH_DELAY_MS = 1200;

const authStatusDiv = document.getElementById('auth-status');
const signinButton = document.getElementById('signin-button');
const signoutButton = document.getElementById('signout-button');
const notesCard = document.getElementById('notes-card');
const modeBadge = document.getElementById('mode-badge');
const dbBadge = document.getElementById('db-badge');
const dbPrivateBtn = document.getElementById('db-private');
const dbPublicBtn = document.getElementById('db-public');
const dbHint = document.getElementById('db-hint');
const tbody = document.getElementById('notes-tbody');
const tableStatusEl = document.getElementById('table-status');
const formStatusEl = document.getElementById('form-status');
const formHeading = document.getElementById('form-heading');
const formRecordName = document.getElementById('form-record-name');
const titleInput = document.getElementById('form-title');
const indexInput = document.getElementById('form-index');
const saveBtn = document.getElementById('save-btn');
const clearBtn = document.getElementById('clear-btn');
const deleteBtn = document.getElementById('delete-btn');
const refreshBtn = document.getElementById('refresh-btn');
const recordTypeInput = document.getElementById('record-type');
const queryLimitInput = document.getElementById('query-limit');
const queryZoneInput = document.getElementById('query-zone');
const queryZoneOwnerInput = document.getElementById('query-zone-owner');
const rawResponseEl = document.getElementById('raw-response');
const formImageGenerateBtn = document.getElementById('form-image-generate');
const formImageClearBtn = document.getElementById('form-image-clear');
const formImageStatusEl = document.getElementById('form-image-status');
const formImagePreviewImg = document.getElementById('form-image-preview');
const assetsSourceInput = document.getElementById('assets-source');

// Generated image staged for the next save, or null.
//   { dataURL, base64, blob, byteLength }
let pendingImage = null;

// ---- shared helpers ----

function setStatus(el, message, kind) {
    if (!el) return;
    el.className = `status ${kind || ''}`;
    el.textContent = message;
    if (kind) el.style.display = 'block';
}

function clearStatus(el) {
    if (!el) return;
    el.className = 'status';
    el.textContent = '';
    el.style.display = 'none';
}

// JSON.stringify replacer that renders Dates as ISO strings and drops
// circular references. Some CloudKit JS results (e.g. the value resolved
// by `registerForNotifications`) hold cyclic structures that would
// otherwise throw "JSON.stringify cannot serialize cyclic structures".
function safeReplacer() {
    const seen = new WeakSet();
    return (_key, value) => {
        if (value instanceof Date) return value.toISOString();
        if (value && typeof value === 'object') {
            if (seen.has(value)) return '[Circular]';
            seen.add(value);
        }
        return value;
    };
}

function showRaw(value) {
    rawResponseEl.textContent = value == null ? '(none)' : JSON.stringify(value, safeReplacer(), 2);
}

// Render an arbitrary payload to a specific <pre> element (used by all
// new operation panels). Mirrors `showRaw` but takes the target element
// explicitly.
function renderRaw(el, value) {
    if (!el) return;
    el.textContent = value == null
        ? '(none)'
        : JSON.stringify(value, safeReplacer(), 2);
}

// Render a simple read-only table of `items` into `tbody`. `getters` is an
// array of `item => cellValue` functions, one per column — its length must
// match the table's column count. Used by the Zones and Subscriptions list
// panels to present results as a table instead of raw JSON.
function renderListTable(tbody, getters, items, emptyMessage) {
    if (!tbody) return;
    tbody.innerHTML = '';
    if (!items || items.length === 0) {
        const tr = document.createElement('tr');
        const td = document.createElement('td');
        td.colSpan = getters.length;
        td.className = 'empty-state';
        td.textContent = emptyMessage;
        tr.appendChild(td);
        tbody.appendChild(tr);
        return;
    }
    for (const item of items) {
        const tr = document.createElement('tr');
        for (const get of getters) {
            const td = document.createElement('td');
            const value = get(item);
            td.textContent = (value == null || value === '') ? '—' : String(value);
            tr.appendChild(td);
        }
        tbody.appendChild(tr);
    }
}

// Run an operation and pipe its progress through the panel's status div
// + raw `<pre>`. Common shape across every new panel:
//   - "loading…" while in-flight
//   - success body rendered as JSON in the pre
//   - errors rendered as red banner + payload (or message) in the pre
async function runPanelOperation({ statusEl, rawEl, label, fn }) {
    setStatus(statusEl, `${label}…`, 'loading');
    try {
        const result = await fn();
        renderRaw(rawEl, result);
        setStatus(statusEl, `${label} succeeded.`, 'success');
        return result;
    } catch (error) {
        const payload = error && error.payload ? error.payload : { message: error.message };
        renderRaw(rawEl, payload);
        const msg = (error && error.message) || 'Unknown error';
        setStatus(statusEl, `${label} failed: ${msg}`, 'error');
        return null;
    }
}

async function postJSON(path, body) {
    const init = { headers: { 'Content-Type': 'application/json' } };
    if (body !== undefined) {
        init.method = 'POST';
        init.body = JSON.stringify(body);
    }
    const response = await fetch(path, init);
    const text = await response.text();
    let payload;
    try { payload = text ? JSON.parse(text) : null; } catch { payload = { message: text }; }
    if (!response.ok) {
        const msg = (payload && (payload.message || payload.error)) || `HTTP ${response.status}`;
        const err = new Error(msg);
        err.payload = payload;
        err.status = response.status;
        throw err;
    }
    return payload;
}

async function fetchJSON(path) {
    const response = await fetch(path);
    const text = await response.text();
    let payload;
    try { payload = text ? JSON.parse(text) : null; } catch { payload = { message: text }; }
    if (!response.ok) {
        const msg = (payload && (payload.message || payload.error)) || `HTTP ${response.status}`;
        const err = new Error(msg);
        err.payload = payload;
        err.status = response.status;
        throw err;
    }
    return payload;
}

function ckJsDatabase() {
    return currentDatabase === 'public'
        ? container.publicCloudDatabase
        : container.privateCloudDatabase;
}

function ckJsContainer() {
    return container;
}

function csv(value) {
    return (value || '')
        .split(',')
        .map(s => s.trim())
        .filter(s => s.length > 0);
}

// ---- image generation (Note.image asset) ----

// Generates a 96×96 PNG with a deterministic-per-call random background and
// the title's first character — enough variety to verify uploads/rereferences
// distinguish between notes, without needing the user to pick a file.
function generateNoteImage(title) {
    const size = 96;
    const canvas = document.createElement('canvas');
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext('2d');
    const hue = Math.floor(Math.random() * 360);
    ctx.fillStyle = `hsl(${hue}, 70%, 55%)`;
    ctx.fillRect(0, 0, size, size);
    ctx.fillStyle = 'white';
    ctx.font = 'bold 56px -apple-system, BlinkMacSystemFont, sans-serif';
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    const initial = ((title || '').trim()[0] || '?').toUpperCase();
    ctx.fillText(initial, size / 2, size / 2 + 2);
    const base64 = canvas.toDataURL('image/png').split(',', 2)[1];
    const bin = atob(base64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    const blob = new Blob([bytes], { type: 'image/png' });
    return { base64, blob, byteLength: bytes.length };
}

// Returns the flat Asset descriptor from an image field, or null when the
// field is missing/empty. MistKit returns `image` as a bare Asset shape;
// CloudKit JS wraps it in `{ value: ... }`. Both formats are handled.
function existingImageDescriptor(note) {
    const field = note && note.raw && note.raw.fields && note.raw.fields.image;
    if (!field) return null;
    const value = (typeof field === 'object' && 'value' in field) ? field.value : field;
    return (value && typeof value === 'object') ? value : null;
}

function refreshImageState() {
    if (pendingImage) {
        formImagePreviewImg.src = 'data:image/png;base64,' + pendingImage.base64;
        formImagePreviewImg.style.display = 'block';
        formImageStatusEl.textContent =
            `Generated (${pendingImage.byteLength} bytes) — save to upload.`;
        formImageClearBtn.disabled = false;
        return;
    }
    const existing = existingImageDescriptor(selectedNote());
    if (existing) {
        if (existing.downloadURL) {
            formImagePreviewImg.src = existing.downloadURL;
            formImagePreviewImg.style.display = 'block';
        } else {
            formImagePreviewImg.src = '';
            formImagePreviewImg.style.display = 'none';
        }
        const sizeLabel = existing.size != null ? ` (${existing.size} bytes)` : '';
        formImageStatusEl.textContent =
            `Existing image attached${sizeLabel} — Generate to replace.`;
        formImageClearBtn.disabled = true;
        return;
    }
    formImagePreviewImg.style.display = 'none';
    formImagePreviewImg.src = '';
    formImageStatusEl.textContent = 'No image attached.';
    formImageClearBtn.disabled = true;
}

formImageGenerateBtn.addEventListener('click', () => {
    pendingImage = generateNoteImage(titleInput.value);
    refreshImageState();
});
formImageClearBtn.addEventListener('click', () => {
    pendingImage = null;
    refreshImageState();
});

// ---- form state for Notes CRUD ----

function selectedNote() {
    return notes.find(n => n.recordName === selectedRecordName) || null;
}

function refreshFormState() {
    const note = selectedNote();
    if (note) {
        formHeading.textContent = 'Edit note';
        formRecordName.textContent = `· ${note.recordName}`;
        saveBtn.textContent = 'Save';
        deleteBtn.disabled = false;
    } else {
        formHeading.textContent = 'New note';
        formRecordName.textContent = '';
        saveBtn.textContent = 'Create';
        deleteBtn.disabled = true;
    }
}

function clearForm() {
    selectedRecordName = null;
    titleInput.value = '';
    indexInput.value = '';
    pendingImage = null;
    clearStatus(formStatusEl);
    refreshFormState();
    refreshImageState();
    renderRows();
}

function loadNoteIntoForm(note) {
    selectedRecordName = note.recordName;
    titleInput.value = note.title ?? '';
    indexInput.value = note.index != null ? String(note.index) : '';
    pendingImage = null;
    if (assetsSourceInput) assetsSourceInput.value = note.recordName;
    clearStatus(formStatusEl);
    refreshFormState();
    refreshImageState();
    renderRows();
}

// ---- render Notes table ----

function renderRows() {
    tbody.innerHTML = '';
    if (notes.length === 0) {
        const tr = document.createElement('tr');
        const td = document.createElement('td');
        td.colSpan = 5;
        td.className = 'empty-state';
        td.textContent = 'No notes — Refresh or Create one.';
        tr.appendChild(td);
        tbody.appendChild(tr);
        return;
    }
    for (const note of notes) {
        const tr = document.createElement('tr');
        tr.title = note.recordName;
        if (note.recordName === selectedRecordName) tr.classList.add('selected');
        tr.addEventListener('click', (e) => {
            if (e.target.closest('button')) return;
            loadNoteIntoForm(note);
        });

        const titleTd = document.createElement('td');
        titleTd.textContent = note.title ?? '';
        if (note.createdBy && note.createdBy === currentUserRecordName) {
            const youBadge = document.createElement('span');
            youBadge.className = 'badge badge-you';
            youBadge.textContent = 'You';
            youBadge.title = `Created by ${note.createdBy}`;
            titleTd.appendChild(youBadge);
        }
        tr.appendChild(titleTd);

        const indexTd = document.createElement('td');
        indexTd.textContent = note.index != null ? String(note.index) : '';
        tr.appendChild(indexTd);

        const createdTd = document.createElement('td');
        createdTd.className = 'timestamp';
        createdTd.textContent = formatTimestamp(note.created);
        if (note.created) createdTd.title = note.created.toISOString();
        tr.appendChild(createdTd);

        const modifiedTd = document.createElement('td');
        modifiedTd.className = 'timestamp';
        modifiedTd.textContent = formatTimestamp(note.modified);
        if (note.modified) modifiedTd.title = note.modified.toISOString();
        tr.appendChild(modifiedTd);

        const actionsTd = document.createElement('td');
        actionsTd.className = 'actions';
        const delBtn = document.createElement('button');
        delBtn.className = 'danger';
        delBtn.type = 'button';
        delBtn.textContent = 'Delete';
        delBtn.addEventListener('click', () => deleteNote(note));
        actionsTd.appendChild(delBtn);
        tr.appendChild(actionsTd);

        tbody.appendChild(tr);
    }
}

function refreshSortIndicators() {
    document.querySelectorAll('th.sortable').forEach(th => {
        const field = th.dataset.sortField;
        const isActive = currentSort && currentSort.field === field;
        th.classList.toggle('active', isActive);
        const indicator = th.querySelector('.sort-indicator');
        if (isActive) {
            indicator.textContent = currentSort.ascending ? '↑' : '↓';
        } else {
            indicator.textContent = '';
        }
    });
}

document.querySelectorAll('th.sortable').forEach(th => {
    th.addEventListener('click', () => {
        const field = th.dataset.sortField;
        if (currentSort && currentSort.field === field) {
            currentSort = currentSort.ascending
                ? { field, ascending: false }
                : null;
        } else {
            currentSort = { field, ascending: true };
        }
        refreshSortIndicators();
        if (authComplete) queryNotes();
    });
});

// ---- payload normalization ----

function normalizeRecords(payload) {
    const list = (payload && payload.records) || [];
    return list.map(record => {
        const fields = record.fields || {};
        const titleField = fields.title;
        const indexField = fields.index;
        return {
            recordName: record.recordName,
            recordType: record.recordType,
            recordChangeTag: record.recordChangeTag,
            title: titleField && (titleField.value ?? titleField),
            index: indexField && Number(indexField.value ?? indexField),
            created: toDate(record.created),
            modified: toDate(record.modified),
            createdBy: extractUserRecordName(record.created),
            raw: record,
        };
    });
}

function extractUserRecordName(value) {
    if (value == null || typeof value !== 'object' || value instanceof Date) {
        return null;
    }
    return value.userRecordName ?? null;
}

function toDate(value) {
    if (value == null) return null;
    if (value instanceof Date) return value;
    if (typeof value === 'number') return new Date(value);
    if (typeof value === 'object') {
        const inner = value.timestamp;
        if (inner == null) return null;
        if (inner instanceof Date) return inner;
        if (typeof inner === 'number') return new Date(inner);
        if (typeof inner === 'string') {
            const parsed = Date.parse(inner);
            return isNaN(parsed) ? null : new Date(parsed);
        }
    }
    return null;
}

function formatTimestamp(date) {
    if (!date) return '—';
    return date.toLocaleString(undefined, {
        dateStyle: 'short', timeStyle: 'short',
    });
}

function buildFields() {
    const out = {};
    const title = titleInput.value.trim();
    if (title.length > 0) out.title = title;
    const indexRaw = indexInput.value.trim();
    if (indexRaw.length > 0) {
        const parsed = Number(indexRaw);
        if (!isFinite(parsed)) {
            throw new Error('Index must be a number.');
        }
        out.index = parsed;
    }
    return out;
}

function ckJsFields(fields) {
    const wrapped = {};
    for (const [k, v] of Object.entries(fields)) {
        wrapped[k] = { value: v };
    }
    return wrapped;
}

// ---- Notes CRUD operations ----

/** Selected toolbar zone for query and writes. Drops stray owner without name. */
function selectedZone() {
    const zoneName = queryZoneInput.value.trim() || undefined;
    const zoneOwner = zoneName
        ? (queryZoneOwnerInput.value.trim() || undefined)
        : undefined;
    return { zoneName, zoneOwner };
}

/** CloudKit JS per-record zoneID shape (unlike query's top-level zoneID). */
function ckJsRecordZoneID(zoneName, zoneOwner) {
    if (!zoneName) return undefined;
    return zoneOwner
        ? { zoneName, ownerRecordName: zoneOwner }
        : { zoneName };
}

async function queryNotes() {
    if (queryInFlight) return;
    const recordType = recordTypeInput.value.trim();
    const limit = parseInt(queryLimitInput.value, 10);
    const { zoneName, zoneOwner } = selectedZone();
    queryInFlight = true;
    setQueryControlsDisabled(true);
    const dbLabel = currentDatabase === 'public' ? 'public' : 'private';
    const modeLabel = currentMode === 'mistkit' ? 'MistKit' : 'CloudKit JS';
    setStatus(tableStatusEl, `Loading ${dbLabel} via ${modeLabel}`, 'loading');
    try {
        let payload;
        if (currentMode === 'mistkit') {
            payload = await postJSON('/api/records/query', {
                recordType,
                database: currentDatabase,
                limit: isFinite(limit) ? limit : undefined,
                sortBy: currentSort
                    ? [{ field: currentSort.field, ascending: currentSort.ascending }]
                    : undefined,
                zoneName,
                zoneOwner,
            });
        } else {
            const query = { recordType };
            if (currentSort) {
                query.sortBy = [{
                    fieldName: currentSort.field,
                    ascending: currentSort.ascending,
                }];
            }
            // CloudKit JS names the owner `ownerRecordName` inside zoneID.
            if (zoneName) {
                query.zoneID = ckJsRecordZoneID(zoneName, zoneOwner);
            }
            payload = await ckJsDatabase().performQuery(query, {
                resultsLimit: isFinite(limit) ? limit : undefined,
            });
            if (payload && payload.hasErrors && payload.errors.length) {
                throw new Error(payload.errors[0].reason || 'CloudKit JS query failed');
            }
        }
        notes = normalizeRecords(payload);
        if (selectedRecordName && !notes.some(n => n.recordName === selectedRecordName)) {
            clearForm();
        } else {
            refreshFormState();
            renderRows();
        }
        showRaw(payload);
        setStatus(tableStatusEl, `Loaded ${notes.length} record${notes.length === 1 ? '' : 's'}.`, 'success');
    } catch (error) {
        setStatus(tableStatusEl, `Query failed: ${error.message}`, 'error');
        showRaw(error.payload || { message: error.message });
    } finally {
        queryInFlight = false;
        setQueryControlsDisabled(false);
        refreshDatabasePicker();
    }
}

function setQueryControlsDisabled(disabled) {
    const ids = [
        'refresh-btn', 'db-private', 'db-public',
        'mode-mistkit', 'mode-cloudkitjs',
        'save-btn', 'delete-btn',
        'query-zone', 'query-zone-owner',
    ];
    for (const id of ids) {
        const el = document.getElementById(id);
        if (el) el.disabled = disabled;
    }
}

async function saveNote() {
    let fields;
    try {
        fields = buildFields();
    } catch (error) {
        setStatus(formStatusEl, error.message, 'error');
        return;
    }
    const recordType = recordTypeInput.value.trim();
    const note = selectedNote();
    const isUpdate = note != null;
    const hasPendingImage = pendingImage != null;
    if (Object.keys(fields).length === 0 && !hasPendingImage) {
        setStatus(formStatusEl, 'Provide a title, index, or image.', 'error');
        return;
    }
    const label = isUpdate ? 'Update' : 'Create';
    clearStatus(formStatusEl);
    try {
        let payload;
        // MistKit asset uploads are a two-step flow: POST bytes to
        // /api/assets/upload, then create/update with the returned descriptor.
        // CloudKit JS handles upload inline through saveRecords by passing a
        // Blob in the field value.
        const { zoneName, zoneOwner } = selectedZone();
        let uploadedRecordName = null;
        if (hasPendingImage && currentMode === 'mistkit') {
            setStatus(formStatusEl, 'Uploading image…', 'loading');
            const receipt = await postJSON('/api/assets/upload', {
                recordType,
                fieldName: 'image',
                recordName: isUpdate ? note.recordName : undefined,
                database: currentDatabase,
                data: pendingImage.base64,
                zoneName,
                zoneOwner,
            });
            uploadedRecordName = receipt.recordName;
            // FieldValue's Asset case decodes the bare Asset shape directly.
            fields.image = receipt.asset;
        }
        if (currentMode === 'mistkit') {
            if (isUpdate) {
                payload = await postJSON('/api/records/update', {
                    recordType,
                    database: currentDatabase,
                    recordName: note.recordName,
                    fields,
                    recordChangeTag: note.recordChangeTag,
                    zoneName,
                    zoneOwner,
                });
            } else {
                payload = await postJSON('/api/records/create', {
                    recordType,
                    database: currentDatabase,
                    recordName: uploadedRecordName || undefined,
                    fields,
                    zoneName,
                    zoneOwner,
                });
            }
        } else {
            const ckFields = ckJsFields(fields);
            if (hasPendingImage) {
                // CloudKit JS treats Blob/File values as asset uploads and
                // attaches them inline during saveRecords.
                ckFields.image = { value: pendingImage.blob };
            }
            const record = { recordType, fields: ckFields };
            if (isUpdate) {
                record.recordName = note.recordName;
                record.recordChangeTag = note.recordChangeTag;
            }
            const zoneID = ckJsRecordZoneID(zoneName, zoneOwner);
            if (zoneID) record.zoneID = zoneID;
            payload = await ckJsDatabase().saveRecords([record]);
            if (payload && payload.hasErrors && payload.errors.length) {
                throw new Error(payload.errors[0].reason || 'CloudKit JS save failed');
            }
        }
        pendingImage = null;
        showRaw(payload);
        setStatus(formStatusEl, `${label} succeeded.`, 'success');
        if (!isUpdate) clearForm();
        if (!isUpdate) {
            setStatus(
                formStatusEl,
                `Created — waiting ${REFRESH_DELAY_MS}ms for CloudKit to settle`,
                'loading'
            );
            await new Promise(r => setTimeout(r, REFRESH_DELAY_MS));
        }
        await queryNotes();
    } catch (error) {
        setStatus(formStatusEl, `${label} failed: ${error.message}`, 'error');
        showRaw(error.payload || { message: error.message });
    }
}

async function deleteNote(note, statusEl = tableStatusEl) {
    clearStatus(statusEl);
    try {
        let payload;
        const { zoneName, zoneOwner } = selectedZone();
        if (currentMode === 'mistkit') {
            payload = await postJSON('/api/records/delete', {
                recordType: note.recordType,
                database: currentDatabase,
                recordName: note.recordName,
                recordChangeTag: note.recordChangeTag,
                zoneName,
                zoneOwner,
            });
        } else {
            const deleteSpec = { recordName: note.recordName };
            const zoneID = ckJsRecordZoneID(zoneName, zoneOwner);
            if (zoneID) deleteSpec.zoneID = zoneID;
            payload = await ckJsDatabase().deleteRecords([deleteSpec]);
            if (payload && payload.hasErrors && payload.errors.length) {
                throw new Error(payload.errors[0].reason || 'CloudKit JS delete failed');
            }
        }
        showRaw(payload);
        setStatus(statusEl, `Deleted ${note.recordName}.`, 'success');
        if (note.recordName === selectedRecordName) clearForm();
        await queryNotes();
    } catch (error) {
        setStatus(statusEl, `Delete failed: ${error.message}`, 'error');
        showRaw(error.payload || { message: error.message });
    }
}

saveBtn.addEventListener('click', saveNote);
clearBtn.addEventListener('click', clearForm);
deleteBtn.addEventListener('click', () => {
    const note = selectedNote();
    if (note) deleteNote(note, formStatusEl);
});
refreshBtn.addEventListener('click', queryNotes);

refreshFormState();
refreshSortIndicators();
refreshImageState();
