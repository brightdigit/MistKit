// swiftlint:disable file_length
//
//  AuthTokenIndexHTML.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#if canImport(Hummingbird)
  // swiftlint:disable type_body_length line_length indentation_width
  /// Inlined CloudKit auth-flow page served by `AuthTokenCommand`.
  ///
  /// Held here as a Swift raw string so MistDemoKit doesn't need a SwiftPM resource
  /// bundle — that bundle would fail iOS-family CodeSign in CI even though the
  /// auth-token CLI flow only runs on macOS / Linux.
  internal enum AuthTokenIndexHTML {
    internal static let content: String = #"""
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>MistKit CloudKit Authentication Example</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  min-height: 100vh;
                  margin: 0;
                  background-color: #f5f5f7;
              }
              .container {
                  background: white;
                  padding: 40px;
                  border-radius: 12px;
                  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
                  max-width: 500px;
              }
              h1 {
                  color: #1d1d1f;
                  font-size: 28px;
                  margin-bottom: 20px;
              }
              p {
                  color: #6e6e73;
                  font-size: 16px;
                  line-height: 1.5;
                  margin-bottom: 30px;
              }

              .status {
                  margin-top: 20px;
                  padding: 12px;
                  border-radius: 8px;
                  font-size: 14px;
              }
              .status.success {
                  background-color: #d1f5d3;
                  color: #1d5e20;
              }
              .status.error {
                  background-color: #fdd;
                  color: #c00;
              }
              .user-info {
                  margin-top: 20px;
                  text-align: left;
                  background-color: #f5f5f7;
                  padding: 16px;
                  border-radius: 8px;
              }
              .user-info h3 {
                  margin-top: 0;
                  color: #1d1d1f;
                  font-size: 18px;
              }
              .user-info pre {
                  background-color: #fff;
                  padding: 12px;
                  border-radius: 6px;
                  overflow-x: auto;
                  font-size: 13px;
                  margin: 8px 0;
              }
              .loading {
                  display: none;
                  color: #86868b;
                  margin-top: 20px;
              }
              .token-display {
                  margin-top: 20px;
                  padding: 16px;
                  background-color: #f0f9ff;
                  border: 1px solid #0369a1;
                  border-radius: 8px;
              }
              .token-display h3 {
                  margin-top: 0;
                  color: #0369a1;
                  font-size: 18px;
              }
              .token-value {
                  font-family: 'Courier New', monospace;
                  font-size: 12px;
                  word-break: break-all;
                  background-color: #fff;
                  padding: 8px;
                  border-radius: 4px;
                  margin: 8px 0;
                  user-select: all;
              }
              .copy-button {
                  background-color: #0369a1;
                  color: white;
                  border: none;
                  padding: 8px 16px;
                  border-radius: 6px;
                  cursor: pointer;
                  font-size: 14px;
              }
              .copy-button:hover {
                  background-color: #0c4a6e;
              }
              .signout-button {
                  background-color: #ff3b30;
                  color: white;
                  border: none;
                  padding: 8px 16px;
                  border-radius: 6px;
                  cursor: pointer;
                  font-size: 14px;
                  margin-top: 10px;
              }
              .signout-button:hover {
                  background-color: #d70015;
              }
          </style>
          <script src="https://cdn.apple-cloudkit.com/ck/2/cloudkit.js" onerror="console.log('Failed to load CloudKit.js')"></script>
      </head>
      <body>
          <div class="container">
              <h1>MistKit CloudKit Example</h1>
              <p>Sign in with your Apple ID to test CloudKit Web Services authentication and API access.</p>

              <div id="signin-button"></div>
              <button id="signout-button" class="signout-button" style="display: none;">Sign Out</button>

              <div id="loading" class="loading">Authenticating...</div>
              <div id="status"></div>

              <!--
                  Manual fallback: shown when polling container._auth._ckSession times out.
                  This form lets the user copy the token from devtools and paste it in.
              -->
              <div id="manual-token-form" style="display: none; margin-top: 16px; padding: 12px; border: 1px solid #d0d7de; border-radius: 6px; background: #f6f8fa;">
                  <h3 style="margin-top: 0;">Paste Web Auth Token Manually</h3>
                  <p style="font-size: 13px; color: #57606a;">
                      Automatic capture failed (CloudKit's auth iframe is sandboxed).
                      Open DevTools &rarr; Application &rarr; Cookies &rarr; <code>icloud.com</code>,
                      find a cookie value starting with <code>158__</code>, and paste it below.
                  </p>
                  <input id="manual-token-input" type="text" placeholder="158__..." style="width: 100%; padding: 8px; box-sizing: border-box; font-family: monospace;">
                  <button id="manual-token-submit" type="button" style="margin-top: 8px; padding: 8px 16px;">Submit Token</button>
              </div>

              <div id="user-info"></div>
          </div>

          <script>
              async function loadServerConfig() {
                  const response = await fetch('/api/config');
                  if (!response.ok) throw new Error('Failed to load server config: ' + response.status);
                  return response.json();
              }

              let container = null;
              const statusDiv = document.getElementById('status');
              const userInfoDiv = document.getElementById('user-info');
              const signinButton = document.getElementById('signin-button');
              const signoutButton = document.getElementById('signout-button');
              const loadingDiv = document.getElementById('loading');

              // Store the web auth token when received
              let webAuthToken = null;
              let currentUserIdentity = null;
              let tokenPromiseResolve = null;
              let tokenPromiseReject = null;

              // Track if authentication is already in progress
              let authenticationInProgress = false;

              function showStatus(message, isError = false) {
                  statusDiv.className = 'status ' + (isError ? 'error' : 'success');
                  statusDiv.textContent = message;
                  statusDiv.style.display = 'block';
              }

              function showLoading(show) {
                  loadingDiv.style.display = show ? 'block' : 'none';
              }

              async function handleAuthentication(userIdentity) {
                  console.log('=== Authentication Successful ===');
                  console.log('User Identity:', userIdentity);
                  currentUserIdentity = userIdentity;
                  authenticationInProgress = false;

                  // Update UI
                  showStatus('Signed in successfully! Waiting for web auth token...', false);
                  updateSignInState(true);

                  // Poll container._auth._ckSession — populated by CloudKit JS itself.
                  const tokenPromise = new Promise((resolve, reject) => {
                      tokenPromiseResolve = resolve;
                      tokenPromiseReject = reject;

                      // Poll the CloudKit JS auth object for its session token.
                      const pollIntervalMs = 250;
                      const pollDeadlineMs = 10_000;
                      const pollStart = Date.now();
                      const pollHandle = setInterval(() => {
                          const sessionToken = container?._auth?._ckSession;
                          if (sessionToken) {
                              clearInterval(pollHandle);
                              console.log('✅ Token captured from container._auth._ckSession (poll)');
                              webAuthToken = sessionToken;
                              window.cloudKitWebAuthToken = sessionToken;
                              if (tokenPromiseResolve) {
                                  tokenPromiseResolve(sessionToken);
                                  tokenPromiseResolve = null;
                                  tokenPromiseReject = null;
                              }
                              return;
                          }
                          if (Date.now() - pollStart >= pollDeadlineMs) {
                              clearInterval(pollHandle);
                          }
                      }, pollIntervalMs);

                      setTimeout(() => {
                          clearInterval(pollHandle);
                          reject(new Error('Timeout waiting for web auth token after 10 seconds'));
                      }, pollDeadlineMs);
                  });

                  try {
                      const token = await tokenPromise;
                      console.log('✅ Token received, sending to server...');
                      await handleAuthenticationWithToken(userIdentity, token);
                  } catch (error) {
                      console.error('Token wait timeout or error:', error);
                      showStatus('Automatic token capture failed. Paste the token manually below.', true);
                      showManualTokenForm(userIdentity);
                  }
              }

              // Surface the manual-paste form when automatic capture has failed.
              function showManualTokenForm(userIdentity) {
                  const form = document.getElementById('manual-token-form');
                  const input = document.getElementById('manual-token-input');
                  const submit = document.getElementById('manual-token-submit');
                  if (!form || !input || !submit) return;

                  form.style.display = 'block';
                  input.value = '';
                  input.focus();

                  const handler = async () => {
                      const token = input.value.trim();
                      if (!token) {
                          showStatus('Please paste a token first.', true);
                          return;
                      }
                      form.style.display = 'none';
                      webAuthToken = token;
                      window.cloudKitWebAuthToken = token;
                      authenticationInProgress = true;
                      await handleAuthenticationWithToken(userIdentity, token);
                  };

                  // Replace any prior listeners by cloning the button (idempotent across timeouts)
                  const cloned = submit.cloneNode(true);
                  submit.parentNode.replaceChild(cloned, submit);
                  cloned.addEventListener('click', handler);
                  input.addEventListener('keydown', (event) => {
                      if (event.key === 'Enter') handler();
                  });
              }

              function updateSignInState(isSignedIn) {
                  signoutButton.style.display = isSignedIn ? 'inline-block' : 'none';
              }

              async function handleAuthenticationWithToken(userIdentity, token) {
                  try {
                      console.log('Starting authentication with token...');
                      showLoading(true);
                      statusDiv.style.display = 'none';
                      userInfoDiv.innerHTML = '';

                      if (userIdentity && token) {
                          showStatus('Successfully authenticated with web token!');

                          // Show sign out button
                          signoutButton.style.display = 'inline-block';

                          console.log('User Identity:', userIdentity);
                          console.log('Web Auth Token:', token);

                          // Send token to our server
                          const response = await fetch('/api/authenticate', {
                              method: 'POST',
                              headers: {
                                  'Content-Type': 'application/json'
                              },
                              body: JSON.stringify({
                                  sessionToken: token,
                                  userRecordName: userIdentity.userRecordName
                              })
                          });

                          if (response.ok) {
                              const data = await response.json();
                              displayUserInfo(data);
                          } else {
                              const errorText = await response.text();
                              throw new Error(`Server authentication failed: ${errorText}`);
                          }
                      } else {
                          throw new Error('Missing user identity or authentication token');
                      }
                  } catch (error) {
                      showStatus('Authentication failed: ' + error.message, true);
                      console.error('Authentication error:', error);
                  } finally {
                      showLoading(false);
                      authenticationInProgress = false; // Reset the flag
                  }
              }

              function displayUserInfo(data) {
                  let html = '';

                  // Display web auth token prominently
                  if (webAuthToken) {
                      html += `
                          <div class="token-display">
                              <h3>Web Auth Token</h3>
                              <p>Use this token for command-line CloudKit API access:</p>
                              <div class="token-value" id="token-value">${webAuthToken}</div>
                              <button class="copy-button" onclick="copyToken()">Copy Token</button>
                          </div>
                      `;
                  }

                  html += `<div class="user-info"><h3>CloudKit Data</h3>`;

                  // Display user info if available
                  if (data.cloudKitData.user) {
                      html += `
                          <h4>User Profile</h4>
                          <p><strong>Record Name:</strong> ${data.cloudKitData.user.userRecordName}</p>
                          ${data.cloudKitData.user.firstName ? `<p><strong>First Name:</strong> ${data.cloudKitData.user.firstName}</p>` : ''}
                          ${data.cloudKitData.user.lastName ? `<p><strong>Last Name:</strong> ${data.cloudKitData.user.lastName}</p>` : ''}
                          ${data.cloudKitData.user.emailAddress ? `<p><strong>Email:</strong> ${data.cloudKitData.user.emailAddress}</p>` : ''}
                      `;
                  }

                  // Display zones
                  if (data.cloudKitData.zones && data.cloudKitData.zones.length > 0) {
                      html += `<h4>Available Zones</h4><ul>`;
                      data.cloudKitData.zones.forEach(zone => {
                          html += `<li><strong>${zone.zoneName}</strong>`;
                          if (zone.capabilities && zone.capabilities.length > 0) {
                              html += ` - Capabilities: ${zone.capabilities.join(', ')}`;
                          }
                          html += `</li>`;
                      });
                      html += `</ul>`;
                  }

                  // Display any errors
                  if (data.cloudKitData.error) {
                      html += `<p style="color: #c00;"><strong>Error:</strong> ${data.cloudKitData.error}</p>`;
                      html += `<p><em>Note: Make sure to configure your CloudKit container and API token correctly.</em></p>`;
                  }

                  html += `
                      <h4>Raw Response</h4>
                      <pre>${JSON.stringify(data.cloudKitData, null, 2)}</pre>
                  </div>`;

                  userInfoDiv.innerHTML = html;
              }

              function copyToken() {
                  const tokenValue = document.getElementById('token-value').textContent;
                  navigator.clipboard.writeText(tokenValue).then(() => {
                      const button = document.querySelector('.copy-button');
                      const originalText = button.textContent;
                      button.textContent = 'Copied!';
                      setTimeout(() => {
                          button.textContent = originalText;
                      }, 2000);
                  });
              }

              // Sign out functionality
              async function signOutUser() {
                  try {
                      console.log('Signing out user...');
                      await container.signOut();

                      // Clear application state
                      webAuthToken = null;
                      currentUserIdentity = null;
                      authenticationInProgress = false;

                      // Update UI
                      showStatus('Signed out successfully.');
                      userInfoDiv.innerHTML = '';
                      signoutButton.style.display = 'none';

                      // Clear any CloudKit cookies
                      const cookies = document.cookie.split(';');
                      for (const cookie of cookies) {
                          const [name] = cookie.trim().split('=');
                          if (name && (name.includes('cloudkit') || name.includes('ck') || name.includes('iCloud'))) {
                              document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
                              console.log('Cleared cookie:', name);
                          }
                      }

                      console.log('Sign out complete');
                  } catch (error) {
                      console.error('Sign out error:', error);
                      showStatus('Sign out failed: ' + error.message, true);
                  }
              }

              // Add sign out button event listener
              signoutButton.addEventListener('click', signOutUser);

              // Initialize CloudKit authentication
              async function initializeCloudKit() {
                  try {
                      // Check if CloudKit is properly loaded
                      if (typeof CloudKit === 'undefined') {
                          throw new Error('CloudKit.js failed to load');
                      }

                      const serverConfig = await loadServerConfig();
                      console.log('Initializing CloudKit with container:', serverConfig.containerIdentifier);

                      CloudKit.configure({
                          containers: [{
                              containerIdentifier: serverConfig.containerIdentifier,
                              apiTokenAuth: {
                                  apiToken: serverConfig.apiToken,
                                  persist: true,
                                  signInButton: {
                                      id: 'signin-button',
                                      theme: 'black'
                                  }
                              },
                              environment: 'development'
                          }]
                      });
                      console.log('CloudKit configured successfully');
                      container = CloudKit.getDefaultContainer();

                      // Debug: Check authentication state before setUpAuth
                      console.log('Container auth state before setup:', container._auth);

                      // Set up authentication and check if user is already signed in
                      const userIdentity = await container.setUpAuth();

                      // Debug: Check authentication state after setUpAuth
                      console.log('Container auth state after setup:', container._auth);
                      console.log('User identity from setUpAuth:', userIdentity);

                      // Check if we have the session token directly from the auth object
                      const sessionToken = container._auth?._ckSession;
                      console.log('Session token from auth:', sessionToken);

                      if (userIdentity) {
                          // User is already signed in
                          showStatus('Already signed in. Processing authentication...');

                          // If we have the session token, use it directly
                          if (sessionToken && !authenticationInProgress) {
                              console.log('Using session token from container._auth._ckSession');
                              webAuthToken = sessionToken;
                              authenticationInProgress = true;
                              await handleAuthenticationWithToken(userIdentity, sessionToken);
                          } else {
                              await handleAuthentication(userIdentity);
                          }
                      } else {
                          // User is not signed in, wait for sign-in
                          showStatus('Please click "Sign In with Apple ID" to authenticate.');
                      }

                      // Set up event handlers for sign-in and sign-out
                      container.whenUserSignsIn().then(async (userIdentity) => {
                          console.log('User signed in:', userIdentity);
                          await handleAuthentication(userIdentity);
                      });

                      container.whenUserSignsOut().then(() => {
                          console.log('User signed out');
                          showStatus('Signed out successfully.');
                          userInfoDiv.innerHTML = '';
                          signoutButton.style.display = 'none';
                      });

                  } catch (error) {
                      console.error('CloudKit setup error:', error);
                      if (error.message && error.message.includes('421')) {
                          showStatus('CloudKit container setup issue. Check CloudKit Console for: 1) Container exists 2) Development environment enabled 3) Web services configured', true);
                      } else {
                          showStatus('CloudKit setup failed: ' + error.message, true);
                      }
                  }
              }

              // Add error handling for CloudKit
              window.addEventListener('error', function(event) {
                  console.log('Global error:', event.error, event.filename, event.lineno);
              });

              // Initialize CloudKit when page loads
              initializeCloudKit();

              // Expose debugging helpers on localhost only
              if (['localhost', '127.0.0.1'].includes(window.location.hostname)) {
                  window.mistKitDebug = {
                      container: () => CloudKit.getDefaultContainer(),
                      token: () => window.cloudKitWebAuthToken || webAuthToken,
                      setToken: (token) => {
                          window.cloudKitWebAuthToken = token;
                          webAuthToken = token;
                          console.log('Token manually set');
                      },
                      sendToServer: () => {
                          const container = CloudKit.getDefaultContainer();
                          if (container && container.userIdentity) {
                              handleAuthenticationWithToken(container.userIdentity, window.cloudKitWebAuthToken || webAuthToken);
                          } else {
                              console.error('Not signed in');
                          }
                      },
                      inspectContainer: () => {
                          const container = CloudKit.getDefaultContainer();
                          console.log('Container:', container);
                          console.log('Container properties:', Object.keys(container));
                          console.log('User identity:', container.userIdentity);

                          // Try to find token in various places
                          const locations = {
                              'session.webAuthToken': container.session?.webAuthToken,
                              '_auth.webAuthToken': container._auth?.webAuthToken,
                              '_auth._ckSession': container._auth?._ckSession,
                              'window.cloudKitWebAuthToken': window.cloudKitWebAuthToken,
                              'webAuthToken variable': webAuthToken
                          };

                          console.log('Checked token locations:', locations);

                          for (const [path, value] of Object.entries(locations)) {
                              if (value) {
                                  console.log(`✅ Found at ${path}:`, value);
                              }
                          }
                      }
                  };

                  console.log('MistKit Debug helpers available:');
                  console.log('  mistKitDebug.container()     - Get CloudKit container');
                  console.log('  mistKitDebug.token()         - Get current token');
                  console.log('  mistKitDebug.setToken(tok)   - Manually set token');
                  console.log('  mistKitDebug.sendToServer()  - Send token to server');
                  console.log('  mistKitDebug.inspectContainer() - Inspect container for token');
              }
          </script>
      </body>
      </html>
      """#
  }
  // swiftlint:enable type_body_length line_length indentation_width
#endif
