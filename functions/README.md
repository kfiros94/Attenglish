# Firebase Cloud Functions for Attenglish

This directory contains Firebase Cloud Functions that enable the Attenglish app to work on web browsers.

## Why Cloud Functions?

Web browsers have CORS (Cross-Origin Resource Sharing) restrictions that prevent direct API calls to external services like the Claude AI API. Cloud Functions act as a secure proxy, handling these API calls server-side.

## Functions

### `generateActivitiesWithAI`

Proxies Claude AI API calls for generating educational activities from text.

**Input:**
- `prompt` (string): The prompt to send to Claude AI
- `apiKey` (string): Your Anthropic API key

**Output:**
- `success` (boolean): Whether the operation succeeded
- `data` (object): The parsed JSON response from Claude AI containing activities

**Security:**
- Only authenticated users can call this function
- API key is passed from the client (not stored server-side for security)
- 2-minute timeout for long-running AI generations

## Setup and Deployment

### Prerequisites

1. Node.js 18 or higher
2. Firebase CLI: `npm install -g firebase-tools`
3. Firebase project with Blaze plan (required for Cloud Functions)

### Initial Setup

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Compile TypeScript
npm run build
```

### Deployment

**Deploy all functions:**
```bash
firebase deploy --only functions
```

**Deploy specific function:**
```bash
firebase deploy --only functions:generateActivitiesWithAI
```

### Testing Locally

You can test functions locally using the Firebase emulator:

```bash
# Start emulator
npm run serve

# Or from project root
firebase emulators:start --only functions
```

## File Structure

```
functions/
├── src/
│   └── index.ts          # Main Cloud Function code
├── lib/                  # Compiled JavaScript (auto-generated)
├── package.json          # Node.js dependencies
├── tsconfig.json         # TypeScript configuration
└── README.md            # This file
```

## Environment Variables

The Claude AI API key is NOT stored in environment variables for security reasons. Instead, it's:
1. Stored securely in the Flutter app configuration
2. Passed to the Cloud Function with each request
3. Only accessible to authenticated users

## Cost Considerations

Cloud Functions on Firebase Blaze plan:
- First 2 million invocations/month: FREE
- After that: $0.40 per million invocations
- Network egress: First 5GB free, then $0.12/GB

For typical usage (100 generations/day), costs should remain in the free tier.

## Monitoring

View function logs in Firebase Console:
- Go to Firebase Console > Functions
- Click on function name to see logs
- Or use: `firebase functions:log`

## Troubleshooting

**Error: "unauthenticated"**
- User is not logged in to Firebase Auth
- Solution: Ensure user signs in before using AI generation

**Error: "permission-denied"**
- Invalid API key provided
- Solution: Check API key in app configuration

**Error: "resource-exhausted"**
- Claude AI rate limit hit
- Solution: Wait a few minutes before retrying

**Function timeout**
- Generation taking > 2 minutes
- Solution: Try with shorter text or simpler prompts

## Development

To modify the Cloud Function:

1. Edit `src/index.ts`
2. Compile: `npm run build`
3. Test locally: `npm run serve`
4. Deploy: `firebase deploy --only functions`

## Security Notes

- Function validates user authentication before processing
- API key is never logged or stored server-side
- All errors are sanitized before returning to client
- Rate limiting is enforced by Claude AI API
