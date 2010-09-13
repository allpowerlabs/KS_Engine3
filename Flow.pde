// Flow

void DoFlow() {
  air_eng_flow = CalcFlowmeter(CfA0_air_eng, -Press[3], 1.2);
  air_rct_flow = CalcFlowmeter(CfA0_air_rct, -Press[4], 1.2);
  gas_eng_flow = CalcFlowmeter(CfA0_gas_eng, -Press[5], 0.95);
}
//Correct flowmeter equation
double CalcFlowmeter(double CfA0, double dP, double density) {
  return CfA0*sqrt(((dP)*2)/density);
}

