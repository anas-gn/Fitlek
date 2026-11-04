# Sirvya meal scanner

The Home meal card and center Sirvya logo open the native camera. Review the photo in the dark green scanner screen, choose how much of the visible plate was eaten, and optionally describe sauces or hidden ingredients. Gallery selection is also supported. Results show estimated calories, protein, carbs, fat, ingredient weights, confidence and assumptions. Changing ingredient weight scales its nutrition; added ingredients use nutrition entered from a label or recipe. Saved meals and photos remain on this device, separately for each signed-in user (latest 100 meals). There is no AI assistant.

## Azure configuration

The supplied **hungry-agent-21633vt4h7** Foundry endpoint was verified to serve **GPT-4.1 mini**. The local backend environment has been configured with this endpoint and the supplied key in its ignored `.env` file. In the deployed backend environment, configure:

```
AZURE_OPENAI_ENDPOINT=https://sirvya-resource.services.ai.azure.com/api/projects/sirvya/agents/hungry-agent-21633vt4h7/endpoint/protocols/openai/responses
AZURE_OPENAI_API_KEY=YOUR-PRIVATE-KEY
AZURE_OPENAI_API_VERSION=v1
```

This uses your exact full Responses endpoint with API-key authentication. The agent controls its model deployment; no `AZURE_OPENAI_DEPLOYMENT` is needed for this endpoint. Each scan is independent, sends `store: false`, and does not reuse a conversation across users. A live stateless request succeeded even though the supplied Python example creates a conversation. The backend sends explicitly typed `message` items with `input_image`. This agent rejects per-request structured-output format overrides, so the JSON schema is included in the prompt and the backend validates the returned ingredient data before the app displays it. Direct model endpoints still use strict structured outputs.

A live test using the food image in the supplied mockup identified grilled chicken, rice and vegetables, returned six ingredients, and estimated 608 kcal. This verifies image input and nutrition output, not the nutritional accuracy of a photo-based estimate.

Never put this key in Flutter assets, source control, or the mobile app. Restart/redeploy `mobile_app/backend` after configuration. The app uses its existing API base URL and authenticated `POST /api/meals/analyze` route. No database migration or extra package is needed.

Direct Azure model endpoints remain supported: set the resource root (e.g. `https://YOUR-RESOURCE.openai.azure.com`), `AZURE_OPENAI_DEPLOYMENT=YOUR-DEPLOYMENT-NAME` and `AZURE_OPENAI_API_VERSION=2024-10-21` to use Chat Completions. A full direct `/openai/v1/responses` endpoint uses Responses with the configured deployment as `model`.

Photos are decoded, rotated, resized to at most 1280 pixels and stripped of metadata before transmission to Azure. The backend keeps images in memory and does not persist or log them. The user confirms analysis with **Use photo** before a photo is sent.

## Cost and limits

Each analysis uses one model request capped at 2,200 output tokens. Ingredient edits and history do not call Azure. The backend allows 30 attempts per user per rolling 24 hours, at least 10 seconds apart, and at most eight simultaneous analyses per server process. These guards reset when the process restarts. Multiple processes require a shared durable limiter before public rollout. Configure Azure spending alerts and quota separately: the stated $100 credit and 100k TPM are not a guaranteed scan count or a hard spending cap enforced by this code.

## Verification

Run `node --test test/meal_analysis.test.mjs` in the backend and Flutter analysis/tests in the mobile app. After Azure configuration, verify on Android/iOS: camera permission denied, camera cancellation, gallery photo, a Moroccan dish (e.g. tagine/couscous), non-food image rejection, portion selection, ingredient edits, saved history after restart, and expired session/network errors. Camera capture uses the phone's native camera UI; the Sirvya photo review and result screens follow the supplied mockup.

References: [Azure image input](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/gpt-with-vision), [Azure structured outputs](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/structured-outputs), [GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
