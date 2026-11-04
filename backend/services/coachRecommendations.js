export function specialties(value) {
  try {value=typeof value==='string'&&value.trim().startsWith('[')?JSON.parse(value):value;}catch{value=[];}
  return (Array.isArray(value)?value:String(value||'').split(/[,•/]/)).map(v=>String(v).trim().toLowerCase()).filter(Boolean);
}
const cityKey=value=>String(value||'').split(',')[0].trim().normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase();
const coachSpecs=c=>[...new Set([...specialties(c.specialties),...specialties(c.specialty||c.speciality)])];
export function distance(a,b) {
  if([a.latitude,a.longitude,b.latitude,b.longitude].some(v=>v==null || String(v).trim()==='' || !Number.isFinite(Number(v))))return null;
  if(Math.abs(Number(a.latitude))>90 || Math.abs(Number(b.latitude))>90 || Math.abs(Number(a.longitude))>180 || Math.abs(Number(b.longitude))>180)return null;
  const rad=v=>Number(v)*Math.PI/180;
  const dlat=rad(b.latitude)-rad(a.latitude),dlon=rad(b.longitude)-rad(a.longitude);
  const h=Math.sin(dlat/2)**2+Math.cos(rad(a.latitude))*Math.cos(rad(b.latitude))*Math.sin(dlon/2)**2;
  return 6371*2*Math.asin(Math.sqrt(Math.min(1,h)));
}
export function rankCoaches(rows,client,{interests=[],explicitInterests=[],selectedSpecialty,now=Date.now()}={}) {
  const preferred=new Set(interests.map(v=>String(v).toLowerCase()));
  const chosen=new Set(explicitInterests.map(v=>String(v).toLowerCase()));
  return rows.filter(c=>!selectedSpecialty || selectedSpecialty==='All'||coachSpecs(c).includes(selectedSpecialty.toLowerCase())).map(c=>{
    let score=0;const reasons=[];
    const fresh=location=>location.locationUpdatedAt && now-new Date(location.locationUpdatedAt).getTime()<30*86400000;
    const km=fresh(client)&&fresh(c)?distance(client,c):null;
    if(km!==null){score+=30*Math.exp(-km/25);if(km<25)reasons.push('Near you');}
    else if(cityKey(client.city)&&cityKey(client.city)===cityKey(c.ville)){score+=24;reasons.push('In your city');}
    const count=Math.max(0,Number(c.reviewCount)||0),rating=Math.min(5,Math.max(0,Number(c.rating)||0));
    // A prior prevents one five-star review from outranking an established record.
    score+=24*((rating*count+4*5)/(count+5))/5;
    if(count>=3&&rating>=4.5)reasons.push('Highly rated');
    if(c.isApproved===true||Number(c.isApproved)===1){score+=12;reasons.push('Verified coach');}
    const specs=coachSpecs(c);
    if(specs.some(s=>chosen.has(s))){score+=20;reasons.push('Matches your chosen interests');}
    else if(specs.some(s=>preferred.has(s))){score+=10;reasons.push('Matches your interests');}
    if(Number(c.packageCount)>0)score+=4;
    if(c.avatarUrl)score+=3;if(String(c.bio||'').trim().length>=40)score+=3;
    if(specialties(c.certifications).length>0)score+=3;
    score+=Math.min(3,Math.log1p(Number(c.completedSessions)||0));
    const {latitude,longitude,locationUpdatedAt,...publicCoach}=c;
    return {...publicCoach,distanceKm:distance(client,c),recommendationScore:Math.round(score*100)/100,recommendationReasons:reasons};
  }).sort((a,b)=>b.recommendationScore-a.recommendationScore||Number(a.id)-Number(b.id));
}
