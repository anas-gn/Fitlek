export const workoutMuscleNames=['traps','shoulders','chest','upper back','serratus','biceps','triceps','forearms',
  'abs','obliques','lower back','glutes','quads','hamstrings','adductors','hip flexors','calves','shins'];
const aliases={trapezius:'traps','levator scapulae':'traps',deltoids:'shoulders',delts:'shoulders','rear deltoids':'shoulders',
  'rotator cuff':'shoulders',pectorals:'chest','upper chest':'chest',back:'upper back',lats:'upper back',rhomboids:'upper back',
  'latissimus dorsi':'upper back','serratus anterior':'serratus',brachialis:'biceps',forearm:'forearms',wrists:'forearms',
  'wrist flexors':'forearms','wrist extensors':'forearms','grip muscles':'forearms',core:'abs',abdominals:'abs','lower abs':'abs',
  spine:'lower back',gluteal:'glutes',abductors:'glutes',quadriceps:'quads',legs:'quads',hamstring:'hamstrings',
  groin:'adductors','inner thighs':'adductors',soleus:'calves',tibialis:'shins'};
const bodyParts={chest:{chest:1},back:{'upper back':.75,'lower back':.25},shoulders:{shoulders:1},
  'upper arms':{biceps:.5,triceps:.5},'lower arms':{forearms:1},waist:{abs:.7,obliques:.3},
  'upper legs':{quads:.4,hamstrings:.35,glutes:.25},'lower legs':{calves:.8,shins:.2},neck:{traps:1}};
export function workoutMuscleWeights(exercise){
  const weights={};
  const add=(raw,weight)=>{const name=String(raw??'').trim().toLowerCase(),muscle=aliases[name]??name;
    if(workoutMuscleNames.includes(muscle))weights[muscle]=Math.max(weights[muscle]??0,weight);};
  if(exercise.externalSource!=='sirvya-custom')add(exercise.muscleGroup,1);
  const secondary=typeof exercise.secondaryMuscles==='string'?JSON.parse(exercise.secondaryMuscles):exercise.secondaryMuscles??[];
  secondary.forEach(m=>add(m,.4));
  if(!Object.keys(weights).length)Object.assign(weights,bodyParts[exercise.bodyPart??exercise.muscleGroup]??{});
  return weights;
}
