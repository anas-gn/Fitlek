import {readFileSync} from 'node:fs';
import {hasHostedWorkoutMedia,hostedWorkoutSources} from './hostedWorkoutMedia.js';

// Backend deployments do not need the Flutter media bundle. The reviewed
// identity map is packaged with the API; the asset audit checks both catalogs.
const sources=[
  ...JSON.parse(readFileSync(new URL('../data/workoutVideoSources.json',import.meta.url),'utf8')),
  ...JSON.parse(readFileSync(new URL('../data/workoutMediaSources.json',import.meta.url),'utf8')),
];
const identities=new Set(sources.flatMap(video=>video.targets.map(([source,id])=>`${source}:${id}`)));
const playable=location=>typeof location==='string' &&
  /^(https?:\/\/[^/]+\/|\/(?!\/)|assets\/workout\/)/i.test(location.trim()) &&
  /\.(mp4|webm|mov|gif)(?:[?#].*)?$/i.test(location.trim());
export const hasWorkoutVideo=exercise=>playable(exercise.videoUrl) || identities.has(`${exercise.externalSource}:${exercise.externalId}`) || hasHostedWorkoutMedia(exercise);
export function workoutVideoFilter(){
  const groups=new Map();
  for(const video of [...sources,...hostedWorkoutSources()])for(const [source,id] of video.targets){
    if(!groups.has(source))groups.set(source,new Set());groups.get(source).add(id);
  }
  const direct="(LOWER(TRIM(e.videoUrl)) REGEXP '^(https?://[^/]+/|/[^/]|assets/workout/)' AND LOWER(TRIM(e.videoUrl)) REGEXP '[.](mp4|webm|mov|gif)([?#].*)?$')";
  return {sql:'('+[...groups].map(()=>'(e.externalSource=? AND e.externalId IN (?))').concat(direct).join(' OR ')+')',
    params:[...groups].flatMap(([source,ids])=>[source,[...ids]])};
}
