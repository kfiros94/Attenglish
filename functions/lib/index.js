"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateActivitiesWithAI = void 0;
const admin = require("firebase-admin");
const https_1 = require("firebase-functions/v2/https");
const v2_1 = require("firebase-functions/v2");
const v2_2 = require("firebase-functions/v2");
// Initialize Firebase Admin
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
        // 3. Call Claude API
        v2_2.logger.info('Calling Claude AI API for user:', decodedToken.uid);
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
            v2_2.logger.error('Claude API error:', errorText);
            if (apiResponse.status === 401) {
                response.status(403).json({
                    error: {
                        message: 'Invalid API key',
                        status: 'PERMISSION_DENIED',
                    },
                });
                return;
            }
            else if (apiResponse.status === 429) {
                response.status(429).json({
                    error: {
                        message: 'Rate limit exceeded. Please try again in a few minutes.',
                        status: 'RESOURCE_EXHAUSTED',
                    },
                });
                return;
            }
            else {
                response.status(500).json({
                    error: {
                        message: `API error: ${apiResponse.status}`,
                        status: 'INTERNAL',
                    },
                });
                return;
            }
        }
        // 5. Parse and return response
        const jsonResponse = await apiResponse.json();
        const content = jsonResponse.content[0].text;
        // Clean markdown code blocks if present
        const cleanedContent = content
            .replace(/```json/g, '')
            .replace(/```/g, '')
            .trim();
        // Parse as JSON
        const parsedResponse = JSON.parse(cleanedContent);
        v2_2.logger.info(`Successfully generated ${((_a = parsedResponse.activities) === null || _a === void 0 ? void 0 : _a.length) || 0} activities`);
        response.status(200).json({
            success: true,
            data: parsedResponse,
        });
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