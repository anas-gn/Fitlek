export function coachMapPoint(row) {
  if (row.latitude == null || row.longitude == null || String(row.latitude).trim()==='' || String(row.longitude).trim()==='') return null;
  const latitude = Number(row.latitude), longitude = Number(row.longitude);
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || Math.abs(latitude) > 90 || Math.abs(longitude) > 180) return null;
  // Show the neighborhood, not a coach's exact private address or GPS position.
  return {id: row.id, mapLatitude: Number(latitude.toFixed(2)), mapLongitude: Number(longitude.toFixed(2))};
}
