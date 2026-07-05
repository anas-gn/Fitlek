const bcrypt = require('bcrypt');
const hash = bcrypt.hashSync('Test123!', 12);
console.log(hash);