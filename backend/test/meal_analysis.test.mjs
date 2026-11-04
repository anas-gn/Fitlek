import test from 'node:test';
import assert from 'node:assert/strict';
import { analyzeMeal, validateMeal } from '../services/mealAnalysis.js';

const meal = () => ({ isFood: true, name: 'Chicken tagine', confidence: 'medium', notes: 'Oil is estimated.',
  ingredients: [{ name: 'Chicken', grams: 120, calories: 198, protein: 37, carbs: 0, fat: 4.3 }] });
const env = { AZURE_OPENAI_ENDPOINT: 'https://example.openai.azure.com', AZURE_OPENAI_API_KEY: 'test-only', AZURE_OPENAI_DEPLOYMENT: 'my-mini' };
const agentEnv = { AZURE_OPENAI_ENDPOINT: 'https://example.services.ai.azure.com/api/projects/sirvya/agents/meal-agent/endpoint/protocols/openai/responses', AZURE_OPENAI_API_KEY: 'test-only' };
const responseMeal = () => ({ status: 'completed', output: [{ type: 'message', role: 'assistant', content: [{ type: 'output_text', text: JSON.stringify(meal()) }] }] });

test('Foundry Responses keeps the full agent URL and uses typed image input with validated JSON', async () => {
  const result = await analyzeMeal(Buffer.from('test-image'), { portion: 0.5, notes: 'olive oil' }, {
    env: agentEnv, fetchImpl: async (url, options) => {
      assert.equal(url.pathname, '/api/projects/sirvya/agents/meal-agent/endpoint/protocols/openai/responses');
      assert.equal(url.searchParams.get('api-version'), 'v1');
      assert.equal(options.headers['api-key'], 'test-only');
      const body = JSON.parse(options.body);
      assert.equal(body.store, false);
      assert.equal(body.model, undefined); // Agent controls its deployed model.
      assert.equal(body.conversation, undefined); // No history shared across scans/users.
      assert.equal(body.text, undefined); // Foundry rejects text.format overrides on an agent.
      assert.match(body.input[0].content[0].text, /Return only a JSON object/);
      assert.match(body.input[0].content[0].text, /"additionalProperties":false/);
      assert.equal(body.input[1].type, 'message');
      assert.equal(body.max_output_tokens, 2200);
      assert.equal(JSON.parse(body.input[1].content[0].text).consumedFractionOfPhoto, 0.5);
      assert.equal(body.input[1].content[1].type, 'input_image');
      assert.match(body.input[1].content[1].image_url, /^data:image\/jpeg;base64,/);
      return { ok: true, json: async () => responseMeal() };
    },
  });
  assert.equal(result.name, 'Chicken tagine');
});
test('direct model Responses retains strict schema and configured model', async () => {
  await analyzeMeal(Buffer.from('test-image'), {}, { env: { ...env, AZURE_OPENAI_ENDPOINT: 'https://example.openai.azure.com/openai/v1/responses' },
    fetchImpl: async (url, options) => {
      assert.equal(url.pathname, '/openai/v1/responses');
      const body = JSON.parse(options.body);
      assert.equal(body.model, 'my-mini');
      assert.equal(body.text.format.strict, true);
      return { ok: true, json: async () => responseMeal() };
    } });
});
test('Responses rejects incomplete output, refusals and malformed nutrition', async () => {
  for (const value of [
    { ...responseMeal(), status: 'incomplete' },
    { status: 'completed', output: [{ type: 'message', role: 'assistant', content: [{ type: 'refusal', refusal: 'No' }] }] },
    { status: 'completed', output: [{ type: 'message', role: 'assistant', content: [{ type: 'output_text', text: 'not JSON' }] }] },
  ]) {
    await assert.rejects(analyzeMeal(Buffer.from(''), {}, { env: agentEnv,
      fetchImpl: async () => ({ ok: true, json: async () => value }) }), { status: 502 });
  }
});
test('Azure request uses the configured deployment, image input and strict output', async () => {
  let request;
  const result = await analyzeMeal(Buffer.from('test-image'), { portion: 0.5, notes: 'olive oil' }, { env,
    fetchImpl: async (url, options) => {
      request = JSON.parse(options.body);
      assert.equal(url.pathname, '/openai/deployments/my-mini/chat/completions');
      assert.equal(options.headers['api-key'], 'test-only');
      return { ok: true, json: async () => ({ choices: [{ finish_reason: 'stop', message: { content: JSON.stringify(meal()) } }] }) };
    } });
  assert.equal(result.name, 'Chicken tagine');
  assert.equal(request.response_format.json_schema.strict, true);
  assert.equal(JSON.parse(request.messages[1].content[0].text).consumedFractionOfPhoto, 0.5);
  assert.match(request.messages[1].content[1].image_url.url, /^data:image\/jpeg;base64,/);
});
test('rejects non-food, missing ingredients and invalid numeric nutrition', () => {
  assert.throws(() => validateMeal({ isFood: false }), { status: 422 });
  assert.throws(() => validateMeal({ ...meal(), ingredients: [] }), { status: 502 });
  for (const bad of [-1, NaN, Infinity, '120']) {
    const value = meal(); value.ingredients[0].grams = bad;
    assert.throws(() => validateMeal(value), { status: 502 });
  }
});
test('missing Azure config prevents any paid request', async () => {
  await assert.rejects(analyzeMeal(Buffer.from(''), {}, { env: {}, fetchImpl: () => assert.fail('should not call Azure') }), { status: 503 });
});
test('Azure rate limits, timeouts and incomplete output are safe errors', async () => {
  await assert.rejects(analyzeMeal(Buffer.from(''), {}, { env, fetchImpl: async () => ({ ok: false, status: 429 }) }), { status: 429 });
  await assert.rejects(analyzeMeal(Buffer.from(''), {}, { env, fetchImpl: async () => { throw Error('secret upstream details'); } }), { status: 504 });
  await assert.rejects(analyzeMeal(Buffer.from(''), {}, { env, fetchImpl: async () => ({ ok: true,
    json: async () => ({ choices: [{ finish_reason: 'length', message: { content: JSON.stringify(meal()) } }] }) }) }), { status: 502 });
});
