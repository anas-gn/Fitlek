# Sirvya meal scanner

The Home meal card and center Sirvya logo open the scanner with an inline live camera preview. Review the photo in the dark green scanner screen, choose how much of the visible plate was eaten, and optionally describe sauces or hidden ingredients. Gallery selection is also supported. Results show estimated calories, protein, carbs, fat, ingredient weights, confidence and assumptions. Changing ingredient weight scales its nutrition; added ingredients use nutrition entered from a label or recipe. Meal metadata syncs to the client diary in MySQL. Photos remain locally on the device, separately for each signed-in user, including after logout. There is no AI assistant.

## Azure configuration

The supplied **hungry-agent-21633vt4h7** Foundry endpoint was verified to serve **GPT-4.1 mini**. The local backend environment has been configured with this endpoint and the supplied key in its ignored `.env` file. In the deployed backend environment, configure:

```
AZURE_OPENAI_ENDPOINT=https://sirvya-resource.services.ai.azure.com/api/projects/sirvya/agents/hungry-agent-21633vt4h7/endpoint/protocols/openai/responses
AZURE_OPENAI_API_KEY=YOUR-PRIVATE-KEY
AZURE_OPENAI_API_VERSION=v1
```

This uses your exact full Responses endpoint with API-key authentication. The agent controls its model deployment; no `AZURE_OPENAI_DEPLOYMENT` is needed for this endpoint. Each scan is independent, sends `store: false`, and does not reuse a conversation across users. A live stateless request succeeded even though the supplied Python example creates a conversation. The backend sends explicitly typed `message` items with `input_image`. This agent rejects per-request structured-output format overrides, so the JSON schema is included in the prompt and the backend validates the returned ingredient data before the app displays it. Direct model endpoints still use strict structured outputs.

A live test using the food image in the supplied mockup identified grilled chicken, rice and vegetables, returned six ingredients, and estimated 608 kcal. This verifies image input and nutrition output, not the nutritional accuracy of a photo-based estimate.

Never put this key in Flutter assets, source control, or the mobile app. Restart/redeploy `mobile_app/backend` after configuration. The app uses its existing API base URL and authenticated `POST /api/meals/analyze` route. The meal quota, diary and nutrition tables must exist; see the migrations directory. Production already has these tables.

Direct Azure model endpoints remain supported: set the resource root (e.g. `https://YOUR-RESOURCE.openai.azure.com`), `AZURE_OPENAI_DEPLOYMENT=YOUR-DEPLOYMENT-NAME` and `AZURE_OPENAI_API_VERSION=2024-10-21` to use Chat Completions. A full direct `/openai/v1/responses` endpoint uses Responses with the configured deployment as `model`.

Photos are decoded, rotated, resized to at most 1280 pixels and stripped of metadata before transmission to Azure. The backend keeps images in memory and does not persist or log them. The user confirms analysis with **Use photo** before a photo is sent.

## Cost and limits

Each analysis uses one model request capped at 2,200 output tokens. Ingredient edits and history do not call Azure. The backend enforces a durable daily allowance in MySQL (default three), configurable in web_admin with per-client overrides and bonus credits. A separate per-process guard enforces ten seconds between attempts and at most eight simultaneous analyses. The daily allowance survives restarts; the short burst guard does not. Multiple processes still need shared concurrency control to enforce an aggregate Azure throughput limit. Configure Azure spending alerts and quota separately: the stated $100 credit and 100k TPM are not a guaranteed scan count or a hard spending cap enforced by this code.

## Verification

Run `node --test test/meal_analysis.test.mjs` in the backend and Flutter analysis/tests in the mobile app. After Azure configuration, verify on Android/iOS: camera permission denied, camera cancellation, gallery photo, a Moroccan dish (e.g. tagine/couscous), non-food image rejection, portion selection, ingredient edits, saved history after restart, and expired session/network errors. Camera capture uses an inline live preview and a circular shutter button; the Sirvya photo review and result screens follow the supplied mockup.

References: [Azure image input](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/gpt-with-vision), [Azure structured outputs](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/structured-outputs), [GPT-4.1 mini](https://developers.openai.com/api/docs/models/gpt-4.1-mini).
