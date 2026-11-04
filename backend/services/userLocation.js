export const USER_LOCATION_SCHEMA = `CREATE TABLE IF NOT EXISTS user_locations (
  userID BIGINT UNSIGNED PRIMARY KEY, city VARCHAR(150) NOT NULL,
  latitude DECIMAL(10,7) NULL, longitude DECIMAL(10,7) NULL,
  fullAddress VARCHAR(1000) NOT NULL DEFAULT '', country VARCHAR(150) NOT NULL DEFAULT '',
  accuracy DOUBLE NULL, source VARCHAR(10) NOT NULL, autoRefresh TINYINT NOT NULL DEFAULT 0,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
)`;

export function normalizeLocation(input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Choose your city or use your current location.');
  const city=String(input.city || '').trim();
  if (!city || city.length>150 || /[\r\n]/.test(city)) throw new Error('Enter a valid city name.');
  const latitude=input.latitude==null?null:Number(input.latitude);
  const longitude=input.longitude==null?null:Number(input.longitude);
  if ((latitude===null)!==(longitude===null) || (latitude!==null && (!Number.isFinite(latitude)||!Number.isFinite(longitude)||Math.abs(latitude)>90||Math.abs(longitude)>180))) throw new Error('Invalid location coordinates.');
  if (latitude===null || longitude===null || String(input.latitude).trim()==='' || String(input.longitude).trim()==='') throw new Error('Use the location button to detect your location.');
  const fullAddress=String(input.fullAddress || '').trim();
  const country=String(input.country || '').trim();
  if(fullAddress.length>1000||country.length>150)throw new Error('Location details are too long.');
  const accuracy=input.accuracy==null?null:Number(input.accuracy);
  if(accuracy!==null&&(!Number.isFinite(accuracy)||accuracy<0))throw new Error('Invalid location accuracy.');
  return {city,latitude,longitude,fullAddress,country,accuracy,
    source:latitude===null?'manual':'gps',autoRefresh:latitude!==null&&input.autoRefresh===true};
}
export async function saveUserLocation(db,userID,role,input) {
  const location=normalizeLocation(input);
  await db.query(`INSERT INTO user_locations (userID,city,latitude,longitude,fullAddress,country,accuracy,source,autoRefresh)
    VALUES (?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE city=VALUES(city),latitude=VALUES(latitude),longitude=VALUES(longitude),
    fullAddress=VALUES(fullAddress),country=VALUES(country),accuracy=VALUES(accuracy),source=VALUES(source),autoRefresh=VALUES(autoRefresh),updatedAt=CURRENT_TIMESTAMP`,
    [userID,location.city,location.latitude,location.longitude,location.fullAddress,location.country,location.accuracy,location.source,location.autoRefresh?1:0]);
  await db.query('UPDATE users SET ville=? WHERE id=?',[location.city,userID]);
  if(role==='coach')await db.query('UPDATE coachprofiles SET ville=? WHERE userID=?',[location.city,userID]);
  return location;
}
