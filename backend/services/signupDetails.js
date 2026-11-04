import {cleanNutritionPlan} from './nutritionGoals.js';
export function signupDetails(body) {
  const height = body.height == null || body.height === '' ? null : Number(body.height);
  if (height !== null && (!Number.isFinite(height) || height <= 0 || height > 300)) throw new Error('Enter a valid height in centimetres.');
  const weight = body.weight == null || body.weight === '' ? null : Number(String(body.weight).replace(',', '.'));
  if (weight !== null && (!Number.isFinite(weight) || weight <= 0 || weight > 500)) throw new Error('Enter a valid weight in kilograms.');
  const values = body.specialties ?? [];
  if (!Array.isArray(values) || values.length > 5 || values.some(v => typeof v !== 'string' || !v.trim() || v.trim().length > 80)) throw new Error('Choose up to 5 valid specialties.');
  const specialties = [...new Set(values.map(v => v.trim()))];
  const interests = body.interests ?? [];
  if (!Array.isArray(interests) || interests.length > 5 || interests.some(v => typeof v !== 'string' || !v.trim() || v.trim().length > 80)) throw new Error('Choose up to 5 valid interests.');
  return {height, weight, specialties, nutritionPlan: body.nutritionPlan == null ? null : cleanNutritionPlan(body.nutritionPlan), interests:[...new Set(interests.map(v=>v.trim()))]};
}
