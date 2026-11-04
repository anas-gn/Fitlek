// Shared MySQL setting; both servers read the same production database.
export async function coachingCompaniesEnabled(db) {
  try {
    const [rows] = await db.execute(
      "SELECT enabled FROM app_feature_flags WHERE name = ?", ["coachingCompanies"]);
    return rows.length === 0 || Number(rows[0].enabled) === 1;
  } catch (error) {
    // Preserve the current app behavior until the additive migration is applied.
    if (error.code === "ER_NO_SUCH_TABLE") return true;
    throw error;
  }
}

export async function saveCoachingCompaniesEnabled(db, enabled) {
  if (typeof enabled !== "boolean") throw new TypeError("coachingCompanies must be a boolean");
  await db.execute(
    "INSERT INTO app_feature_flags (name, enabled) VALUES (?, ?) ON DUPLICATE KEY UPDATE enabled = VALUES(enabled)",
    ["coachingCompanies", enabled ? 1 : 0]);
}
