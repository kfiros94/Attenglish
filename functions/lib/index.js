"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateActivitiesWithAI = void 0;
const admin = require("firebase-admin");
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const v2_2 = require("firebase-functions/v2");
// Initialize Firebase Admin.
admin.initializeApp();
// Set global options
(0, v2_1.setGlobalOptions)({
    timeoutSeconds: 120,
    memory: '512MiB',
});
/**
 * Cloud Function to proxy Claude AI API calls from web clients
 *
 * This function solves the CORS issue that prevents web browsers from
 * calling the Anthropic API directly. It:
 * 1. Accepts requests from authenticated Flutter web clients
 * 2. Forwards the prompt to Claude API with proper authentication
 * 3. Returns the AI-generated activities to the client
 *
 * Security: Only authenticated users can call this function
 */
exports.generateActivitiesWithAI = (0, https_1.onRequest)({ cors: true }, // Allow all origins for now
async (request, response) => {
    var _a;
    // Enable CORS for all origins
    response.set('Access-Control-Allow-Origin', '*');
    response.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    response.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    // Handle preflight request
    if (request.method === 'OPTIONS') {
        response.status(204).send('');
        return;
    }
    // Only allow POST
    if (request.method !== 'POST') {
        response.status(405).json({ error: 'Method not allowed' });
        return;
    }
    try {
        // 1. Verify authentication from Authorization header
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            response.status(401).json({
                error: {
                    message: 'Unauthenticated',
                    status: 'UNAUTHENTICATED',
                },
            });
            return;
        }
        const idToken = authHeader.split('Bearer ')[1];
        let decodedToken;
        try {
            decodedToken = await admin.auth().verifyIdToken(idToken);
        }
        catch (error) {
            response.status(401).json({
                error: {
                    message: 'Invalid authentication token',
                    status: 'UNAUTHENTICATED',
                },
            });
            return;
        }
        // 2. Extract parameters from body
        const { prompt, apiKey } = request.body;
        if (!prompt) {
            response.status(400).json({
                error: {
                    message: 'Missing required parameter: prompt',
                    status: 'INVALID_ARGUMENT',
                },
            });
            return;
        }
        if (!apiKey) {
            response.status(400).json({
                error: {
                    message: 'Missing required parameter: apiKey',
                    status: 'INVALID_ARGUMENT',
                },
            });
            return;
        }
        // 3. Call Claude API with retry logic
        v2_2.logger.info('Calling Claude AI API for user:', decodedToken.uid);
        const MAX_RETRIES = 3;
        const INITIAL_DELAY_MS = 2000; // Start with 2 seconds
        let lastError = null;
        for (let attempt = 0; attempt < MAX_RETRIES; attempt++) {
            try {
                v2_2.logger.info(`API attempt ${attempt + 1}/${MAX_RETRIES}`);
                const apiResponse = await fetch('https://api.anthropic.com/v1/messages', {
                    method: 'POST',
                    headers: {
                        'x-api-key': apiKey,
                        'anthropic-version': '2023-06-01',
                        'content-type': 'application/json',
                    },
                    body: JSON.stringify({
                        model: 'claude-sonnet-4-20250514',
                        max_tokens: 8000,
                        messages: [
                            {
                                role: 'user',
                                content: prompt,
                            }
                        ],
                    }),
                });
                // 4. Handle API response
                if (!apiResponse.ok) {
                    const errorText = await apiResponse.text();
                    // Handle overload error (529) with retry
                    if (apiResponse.status === 529) {
                        v2_2.logger.warn(`API overloaded (attempt ${attempt + 1}/${MAX_RETRIES})`);
                        if (attempt < MAX_RETRIES - 1) {
                            // Calculate exponential backoff: 2s, 4s, 8s
                            const delayMs = INITIAL_DELAY_MS * Math.pow(2, attempt);
                            v2_2.logger.info(`Waiting ${delayMs}ms before retry...`);
                            await new Promise(resolve => setTimeout(resolve, delayMs));
                            continue; // Retry
                        }
                        else {
                            // Max retries reached
                            v2_2.logger.error('Max retries reached, API still overloaded');
                            response.status(503).json({
                                error: {
                                    message: 'Claude API is currently experiencing high traffic. Please try again in a few minutes.',
                                    status: 'UNAVAILABLE',
                                },
                            });
                            return;
                        }
                    }
                    // Handle authentication errors (don't retry)
                    else if (apiResponse.status === 401) {
                        v2_2.logger.error('Invalid API key');
                        response.status(403).json({
                            error: {
                                message: 'Invalid API key',
                                status: 'PERMISSION_DENIED',
                            },
                        });
                        return;
                    }
                    // Handle rate limit (429) with retry
                    else if (apiResponse.status === 429) {
                        v2_2.logger.warn(`Rate limited (attempt ${attempt + 1}/${MAX_RETRIES})`);
                        if (attempt < MAX_RETRIES - 1) {
                            const delayMs = INITIAL_DELAY_MS * Math.pow(2, attempt);
                            v2_2.logger.info(`Waiting ${delayMs}ms before retry...`);
                            await new Promise(resolve => setTimeout(resolve, delayMs));
                            continue; // Retry
                        }
                        else {
                            response.status(429).json({
                                error: {
                                    message: 'Rate limit exceeded. Please try again in a few minutes.',
                                    status: 'RESOURCE_EXHAUSTED',
                                },
                            });
                            return;
                        }
                    }
                    // Other errors (don't retry)
                    else {
                        v2_2.logger.error('Claude API error:', errorText);
                        response.status(500).json({
                            error: {
                                message: `API error: ${apiResponse.status}`,
                                status: 'INTERNAL',
                            },
                        });
                        return;
                    }
                }
                // 5. Success! Parse and return response
                const jsonResponse = await apiResponse.json();
                const content = jsonResponse.content[0].text;
                // Clean markdown code blocks if present
                const cleanedContent = content
                    .replace(/```json/g, '')
                    .replace(/```/g, '')
                    .trim();
                // Parse as JSON
                const parsedResponse = JSON.parse(cleanedContent);
                v2_2.logger.info(`Successfully generated ${((_a = parsedResponse.activities) === null || _a === void 0 ? void 0 : _a.length) || 0} activities (attempt ${attempt + 1})`);
                response.status(200).json({
                    success: true,
                    data: parsedResponse,
                });
                return; // Success! Exit function
            }
            catch (error) {
                v2_2.logger.error(`Error on attempt ${attempt + 1}:`, error);
                lastError = error;
                // Retry on network errors
                if (attempt < MAX_RETRIES - 1) {
                    const delayMs = INITIAL_DELAY_MS * Math.pow(2, attempt);
                    v2_2.logger.info(`Network error, waiting ${delayMs}ms before retry...`);
                    await new Promise(resolve => setTimeout(resolve, delayMs));
                    continue; // Retry
                }
            }
        }
        // If we get here, all retries failed
        v2_2.logger.error('All retry attempts failed:', lastError);
        throw lastError || new Error('Failed after maximum retries');
    }
    catch (error) {
        v2_2.logger.error('Error in generateActivitiesWithAI:', error);
        // Handle JSON parsing errors
        if (error instanceof SyntaxError) {
            response.status(500).json({
                error: {
                    message: 'Invalid JSON response from AI',
                    status: 'INTERNAL',
                },
            });
            return;
        }
        // Generic error
        response.status(500).json({
            error: {
                message: 'Failed to generate activities: ' + error.message,
                status: 'INTERNAL',
            },
        });
    }
});
//# sourceMappingURL=index.js.map