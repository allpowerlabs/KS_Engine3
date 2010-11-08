// Flow
void InitFlow() {
  if (P_Q_AIR_ENG != NULL | P_Q_AIR_RCT != NULL | P_Q_GAS_ENG != NULL) {
    flow_active = true;
  } else {
    flow_active = false;
  }
}

void DoFlow() {
  if (flow_active) {
    air_eng_flow = CalcFlowmeter(CfA0_air_eng, -Press[P_Q_AIR_ENG], 1.2);
    air_rct_flow = CalcFlowmeter(CfA0_air_rct, -Press[P_Q_AIR_RCT], 1.2);
    gas_eng_flow = CalcFlowmeter(CfA0_gas_eng, -Press[P_Q_GAS_ENG], 0.95);
  }
}

//Correct flowmeter equation
double CalcFlowmeter(double CfA0, double dP, double density) {
  return CfA0*sqrt(((dP)*2)/density);
}

