import {distance} from './coachRecommendations.js';

// Calculate on the server; never expose either person's coordinates.
export async function withCoachDistances(db, coaches, requester) {
  if (requester?.role !== 'client' || !coaches.length) return coaches;
  const ids = [requester.id, ...coaches.map(c => c.id)];
  const [locations] = await db.query(
    `SELECT userID, latitude, longitude FROM user_locations WHERE userID IN (${ids.map(() => '?').join(',')})`, ids);
  const byId = new Map(locations.map(l => [Number(l.userID), l]));
  const client = byId.get(Number(requester.id));
  return coaches.map(coach => ({...coach,
    distanceKm: client && byId.has(Number(coach.id))
      ? distance(client, byId.get(Number(coach.id))) : null,
  }));
}
