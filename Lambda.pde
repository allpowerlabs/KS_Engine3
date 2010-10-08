// Lambda
void Lambda_Init() {
  // lambda initialization
  lambda_setpoint = 1.0;
  lambda_output = premix_valve_closed;
  lambda_PID.SetSampleTime(20);
  lambda_PID.SetInputLimits(0.5,1.5);
  lambda_PID.SetOutputLimits(premix_valve_closed,premix_valve_open);
  lambda_PID.SetMode(AUTO);
}

void DoLambda() {
    lambda_value = ADC_ReadChanSync(ANA_LAMBDA)/1024.0+0.5; //0-5V = 0.5 - 1.5 L;
    if (lambda_value > 1.46) {
      lambda_closed_loop = false;
    } else {
      if (lambda_closed_loop == false) { // (re)entering closed loop
        lambda_output = premix_valve_center;
        lambda_PID.SetOutputLimits(max(premix_valve_center-(premix_valve_range/2),premix_valve_closed),min(premix_valve_center+(premix_valve_range/2),premix_valve_open));
      }
      lambda_closed_loop = true;
    }
    if (lambda_closed_loop) {
      lambda_input = lambda_value;
      //lambda_setpoint = lambda_setpoint_mode[ENGINE_ON];
      lambda_PID.SetTunings(lambda_P[0], lambda_I[0], lambda_D[0]);
      lambda_PID.Compute();
      servo0_pos = lambda_output;
    } else {
      servo0_pos = premix_valve_closed;
    }
    
    //this doesn't need to be checked that often.....
    //if (millis() - lamba_updated_time > 60000 & write_lambda) {
    //  WriteLambda(); //values for engine on stored in flash
    //  write_lambda = false;
    //  Serial.print("Lambda PID values saved");
    //}
}

void WriteLambda() {
  //0-8 for P_calib
  EEPROM.write(9, lambda_P[0]*20+128); // stores -6.4 -> 6.4 at 0.05 resolution
  EEPROM.write(10, lambda_I[0]*20+128);
  EEPROM.write(11, lambda_D[0]*20+128);
}

void LoadLambda() {
  //0-8 for P_calib
  lambda_P[0] = EEPROM.read(9)/20-6.4; // stores -6.4 -> 6.4 at 0.05 resolution
  lambda_I[0] = EEPROM.read(10)/20-6.4;
  lambda_D[0] = EEPROM.read(11)/20-6.4;
}
