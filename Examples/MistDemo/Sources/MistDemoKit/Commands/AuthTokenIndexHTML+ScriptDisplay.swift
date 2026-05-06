//
//  AuthTokenIndexHTML+ScriptDisplay.swift
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
    /// JS for token-based authentication, user info display, and clipboard
    /// helpers.
    internal static let scriptDisplay: String = #"""
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
      """#
  }
// swiftlint:enable line_length indentation_width
#endif
