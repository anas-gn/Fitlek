import db from '../../config/db.js';
import {createWeightHistoryRouter} from '../../services/weightHistoryRoutes.js';
export default createWeightHistoryRouter(db);
