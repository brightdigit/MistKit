//
//  AuthTokenIndexHTML+ScriptAuth.swift
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
  // swiftlint:disable indentation_width
  extension AuthTokenIndexHTML {
    /// JS for the auth flow: setup, sign-in handlers, manual token paste,
    /// and the sign-in-state UI helper.
    internal static let scriptAuth: String = #"""
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
      """#
  }
// swiftlint:enable indentation_width
#endif
