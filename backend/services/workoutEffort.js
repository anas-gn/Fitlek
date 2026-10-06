import {isWorkSet} from './workoutDomain.js';

// One scale for aggregation; stored ratings retain their original RPE/RIR.
export function buildEffortStats(sessions,sets,{timeZone='UTC'}={}) {
  const dateFormat=new Intl.DateTimeFormat('en-CA',{timeZone,year:'numeric',month:'2-digit',day:'2-digit'});
  const dates=new Map(sessions.map(s=>[Number(s.id),dateFormat.format(new Date(s.startedAt))]));
  const weeks=new Map(),histogram=Array(5).fill(0),exercisePoints=new Map();
  let done=0,rated=0,hard=0,sum=0,rpe=0,rir=0;
  for(const set of sets){
    const date=dates.get(Number(set.workoutSessionID));
    if(!date||!isWorkSet(set))continue;
    done++;
    const day=new Date(`${date}T12:00:00Z`);day.setUTCDate(day.getUTCDate()-(day.getUTCDay()+6)%7);
    const weekKey=day.toISOString().slice(0,10),week=weeks.get(weekKey)??{date:weekKey,sets:0,rated:0,sum:0};
    week.sets++;weeks.set(weekKey,week);
    const value=set.rir!=null?Number(set.rir):set.rpe!=null?10-Number(set.rpe):null;
    if(value==null||!Number.isFinite(value))continue;
    set.rir!=null?rir++:rpe++;
    rated++;sum+=value;if(value<=3)hard++;
    histogram[Math.min(4,Math.max(0,Math.floor(value)))]++;
    week.rated++;week.sum+=value;
    const key=`${set.workoutSessionID}:${set.exerciseID}`;
    const point=exercisePoints.get(key)??{date,sessionID:set.workoutSessionID,exerciseID:set.exerciseID,rated:0,sum:0};
    point.rated++;point.sum+=value;exercisePoints.set(key,point);
  }
  return {done,rated,hard,averageRir:rated>=5?sum/rated:null,hardPercent:rated>=5?Math.round(hard/rated*100):null,
    preferredScale:rpe>rir?'rpe':'rir',histogram:histogram.map((count,i)=>({rir:i,tail:i===4,count,percent:rated?Math.round(count/rated*100):0})),
    weeks:[...weeks.values()].filter(w=>w.rated>=2).sort((a,b)=>a.date.localeCompare(b.date)).map(({sum,...w})=>({...w,rir:sum/w.rated})),
    exercisePoints:[...exercisePoints.values()].map(({sum,...p})=>({...p,rir:sum/p.rated}))};
}
