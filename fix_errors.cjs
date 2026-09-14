const fs = require('fs');
const p = 'C:/Users/natso/OneDrive/Desktop/Sirvya/Fitlek/lib/screens/ENG/workout_webview.dart';
let c = fs.readFileSync(p, 'utf8');
c = c.replace("'HTTP ' + res.statusCode", "'HTTP ' + res.statusCode.toString()");
fs.writeFileSync(p, c);
console.log('Fixed:', c.includes('statusCode.toString()'));