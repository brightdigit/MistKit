//
//  AuthTokenIndexHTML+ScriptInit.swift
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
  // swiftlint:disable line_length indentation_width
  extension AuthTokenIndexHTML {
    /// JS for sign-out, CloudKit container initialization, and dev-only
    /// debug helpers exposed via `window.mistKitDebug`.
    internal static let scriptInit: String = #"""

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
      """#
  }
// swiftlint:enable line_length indentation_width
#endif
