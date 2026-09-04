export const SPECIAL_USE_LABEL="Uso automático del crédito especial";

const number=value=>Number(value)||0;

export function actualEntryMinutes(entry){
  return number(entry?.minutos_trabajados);
}

export function creditedEntryMinutes(entry){
  const actual=actualEntryMinutes(entry);
  if(entry?.estado_dia==="feriado_completo")return 480;
  if(entry?.estado_dia==="feriado_parcial")return Math.max(480,actual);
  return actual;
}

export function holidayRecognitionMinutes(entry){
  return Math.max(0,creditedEntryMinutes(entry)-actualEntryMinutes(entry));
}

export function movementReferenceMinutes(movement){
  return number(movement?.minutos_referencia)||Math.abs(number(movement?.minutos));
}

export function calculateWeek({entries=[],movements=[],expectedMinutes=0,ignoreEmpty=true}={}){
  const actualMinutes=entries.reduce((sum,entry)=>sum+actualEntryMinutes(entry),0);
  const holidayMinutes=entries.reduce((sum,entry)=>sum+holidayRecognitionMinutes(entry),0);
  const computedMinutes=actualMinutes+holidayMinutes;
  const bankUsedMinutes=movements
    .filter(movement=>movement.tipo==="devolucion")
    .reduce((sum,movement)=>sum+movementReferenceMinutes(movement),0);
  const hasActivity=entries.length>0||movements.length>0;
  const effectiveExpectedMinutes=ignoreEmpty&&!hasActivity?0:number(expectedMinutes);
  const recognizedMinutes=computedMinutes+bankUsedMinutes;
  const resultMinutes=recognizedMinutes-effectiveExpectedMinutes;
  return{
    actualMinutes,
    holidayMinutes,
    computedMinutes,
    bankUsedMinutes,
    expectedMinutes:effectiveExpectedMinutes,
    recognizedMinutes,
    resultMinutes,
    definedDays:entries.length,
    hasActivity
  };
}

export function calculateBalance(movements=[]){
  return movements.reduce((sum,movement)=>sum+number(movement.minutos),0);
}

export function calculateAccumulated({priorBalanceMinutes=0,periodMovements=[]}={}){
  const periodResultMinutes=calculateBalance(periodMovements);
  return{
    priorBalanceMinutes:number(priorBalanceMinutes),
    periodResultMinutes,
    finalBalanceMinutes:number(priorBalanceMinutes)+periodResultMinutes
  };
}

