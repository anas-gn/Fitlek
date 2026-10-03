// Reports locations/categories only, never matched credential or user values.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../..',import.meta.url));
const files=[...new Set(execFileSync('git',['ls-files','--cached','--others','--exclude-standard','-z'],{cwd:root,encoding:'utf8'}).split('\0').filter(Boolean))];
const findings=[];let scanned=0;
for(const file of files){
  if(!/\.(?:dart|js|mjs|json|sql|yaml|yml|env|ps1|gradle)$/.test(file)||/(?:^|\/)(?:tests|test)\//.test(file)||file.endsWith('.env.example'))continue;
  const absolute=path.join(root,file);if(!fs.existsSync(absolute)||fs.statSync(absolute).size>20*1024*1024)continue;
  const source=fs.readFileSync(absolute,'utf8');scanned++;
  for(const [index,line] of source.split(/\r?\n/).entries()){
    let category;
    if(/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(line))category='private key';
    else if(/\beyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}/.test(line))category='JWT literal';
    else if(/\b(?:password|passwordHash|jwtSecret|clientSecret|apiSecret)\s*[:=]\s*['"][^'"]{8,}['"]/i.test(line))category='possible credential literal';
    else if(/INSERT\s+INTO\s+`?users`?\s*(?:\(|VALUES)/i.test(line)&&/VALUES/i.test(line)&&file.endsWith('.sql'))category='user data in SQL';
    if(category)findings.push({file,line:index+1,category});
  }
}
const publicEnvFile='assets/config.env';
const historyFindings=[];
// Pinned fingerprint of the archive inspected during this audit. Check its
// continued reachability without loading/printing private key material again.
const knownCredentialArchive='e62006f1d9194b7144ad89e832a96d5ac2a70803';
const commits=execFileSync('git',['log','--all','--format=%H','--','backend.tar.gz'],{cwd:root,encoding:'utf8'}).trim().split('\n').filter(Boolean);
for(const commit of commits){try{
  const archivedBlob=execFileSync('git',['rev-parse',`${commit}:backend.tar.gz`],{cwd:root,encoding:'utf8',stdio:['ignore','pipe','ignore']}).trim();
  if(archivedBlob===knownCredentialArchive){historyFindings.push({file:'backend.tar.gz',commit:commit.slice(0,8),category:'Firebase private key / backend environment archive in Git history',remediation:'Rotate archived credentials; coordinate history removal. No secret values are included in this report.'});break;}
}catch{/* The removal commit intentionally has no archive. */}}
const result={scannedFiles:scanned,findings,historyFindings,bundledEnvKeys:fs.readFileSync(path.join(root,publicEnvFile),'utf8').split(/\r?\n/).filter(l=>/^\w+\s*=/.test(l)).map(l=>l.split('=')[0].trim()),trackedEnvFiles:files.filter(f=>/(?:^|\/)\.env(?:\.|$)|\.env$/.test(f)),trackedBackupPaths:files.filter(f=>/\.git_backup|\.tar\.gz$|(?:^|\/).*\.bak$/.test(f)),localBackupLocation:'workout_tmp/local-backups (ignored; existing backups retained)'};
fs.writeFileSync(path.join(root,'docs/verification/workout-repository-audit.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result,null,2));
if(findings.length||historyFindings.length||result.trackedBackupPaths.length)process.exitCode=1;
