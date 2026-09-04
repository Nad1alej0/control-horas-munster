import assert from "node:assert/strict";
import {calculateWeek,calculateAccumulated} from "./hours-engine.js";

const entry=(minutes,status="trabajo")=>({minutos_trabajados:minutes,estado_dia:status});
const bank=minutes=>({tipo:"devolucion",minutos:-minutes,minutos_referencia:minutes});
const movement=minutes=>({tipo:"diferencia_semanal",minutos:minutes});

const cases=[
  ["Nadia",calculateWeek({entries:[entry(1827),entry(0,"feriado_completo")],movements:[bank(93)],expectedMinutes:2400}).resultMinutes,0],
  ["Tiara",calculateWeek({entries:[entry(1845),entry(250,"feriado_parcial")],movements:[bank(120)],expectedMinutes:2880}).resultMinutes,-435],
  ["Angie",calculateWeek({entries:[entry(2448)],expectedMinutes:2400}).resultMinutes,48],
  ["Cele",calculateWeek({entries:[entry(2849)],expectedMinutes:2880}).resultMinutes,-31],
  ["Semana vacía",calculateWeek({entries:[],movements:[],expectedMinutes:2880}).resultMinutes,0]
];

for(const[name,actual,expected]of cases)assert.equal(actual,expected,name);
assert.equal(calculateAccumulated({priorBalanceMinutes:28,periodMovements:[movement(-31)]}).finalBalanceMinutes,-3,"Acumulado Cele");
assert.equal(calculateAccumulated({priorBalanceMinutes:0,periodMovements:[movement(-435),movement(168)]}).finalBalanceMinutes,-267,"Acumulado Tiara");
console.log("7 pruebas del motor de horas: OK");
