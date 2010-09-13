//void CheckEngineState() {
//  engine_mode_value = ADC_ReadChanSync(ANA_ENGINE_MODE);
//  // read premix potentiometer, map (linear interpolate) to servo valve open/closed position
//  premix_pot_value=map(ADC_ReadChanSync(ANA_MANUAL_POT),0,1024,premix_valve_open,premix_valve_closed); //may not want to use map
//  // not mapped
//  manual_pot_value = ADC_ReadChanSync(ANA_MANUAL_POT);
//  manual_switch_value = ADC_ReadChanSync(ANA_MANUAL_SWITCH);
//  //check running 
//  if (mode_control == true) {
//    int dead_band = 20;
//    if (engine_mode_value < (0 + dead_band)) {
//      engine_mode = ENGINE_OFF;
//    }
//    if (engine_mode_value > (331 - dead_band) & engine_mode_value < (331 + dead_band)) {
//      engine_mode = ENGINE_ON;
//    }
//    if (engine_mode_value > (600 - dead_band) & engine_mode_value < (600 + dead_band)) {
//      engine_mode = ENGINE_STARTING;
//    }
//    //check control mode
//    if (ADC_ReadChanSync(ANA_MANUAL_SWITCH) > 100) {
//      control_mode = MANUAL_PREMIX_CONTROL;
//    } else {
//      control_mode = PID_PREMIX_CONTROL;
//    }
//  } else {
//    engine_mode = ENGINE_ON;
//    control_mode = PID_PREMIX_CONTROL;
//  }
//}

//void LogEngineMode() {
//  switch (engine_mode) {
//  case ENGINE_OFF:
//    Serial.print("engine_off");
//    break;
//  case ENGINE_ON:
//    Serial.print("engine_on");
//    break;
//  case ENGINE_STARTING:
//    Serial.print("engine_starting");
//    break;
//  }
//  Serial.print(", ");
//}
