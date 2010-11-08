
// Lambda
void DoLambda() {
    switch(lambda_state) {
      case LAMBDA_CLOSEDLOOP:
        lambda_input = ADC_ReadChanSync(ANA_LAMBDA)/1024.0+0.5; //0-5V = 0.5 - 1.5 L;
        lambda_PID.SetTunings(lambda_P[0], lambda_I[0], lambda_D[0]);
        lambda_PID.Compute();
        servo0_pos = lambda_output;
        if (engine_state == ENGINE_OFF) {
          TransitionLambda(LAMBDA_SEALED);
        }
        break;
      case LAMBDA_SEALED:
        lambda_input = ADC_ReadChanSync(ANA_LAMBDA)/1024.0+0.5; //0-5V = 0.5 - 1.5 L;
        if (engine_state == ENGINE_STARTING) {
          TransitionLambda(LAMBDA_CLOSEDLOOP);
        }
        break;
    }
}

void TransitionLambda(int new_state) {
  switch (new_state) {
    case LAMBDA_CLOSEDLOOP:
      lambda_setpoint = 1.0;
      lambda_PID.SetMode(AUTO);
      lambda_PID.SetSampleTime(20);
      lambda_PID.SetInputLimits(0.5,1.5);
      lambda_PID.SetOutputLimits(max(float(premix_valve_center-(premix_valve_range/2.0)),premix_valve_closed),min(float(premix_valve_center+(premix_valve_range/2.0)),premix_valve_open));
      //lambda_PID.SetOutputLimits(0,120);
      Serial.print("#Min:");
      Serial.print(max(premix_valve_center-(premix_valve_range/2),premix_valve_closed));
      Serial.print("->");
      Serial.println(lambda_PID.GetOUTMin());
      Serial.print("#Max:");
      Serial.print(min(premix_valve_center+(premix_valve_range/2),premix_valve_open));
      Serial.print("->");
      Serial.println(lambda_PID.GetOUTMax());
      lambda_output = premix_valve_center;
      Serial.println("# New Lambda State: Closed Loop");
      break;
    case LAMBDA_SEALED:
      lambda_output = premix_valve_closed;
      servo0_pos = lambda_output;
      lambda_PID.SetMode(MANUAL);
      Serial.println("# New Lambda State: Sealed");
      break;
  }
  lambda_state=new_state;
}

    //this doesn't need to be checked that often.....
    //if (millis() - lamba_updated_time > 60000 & write_lambda) {
    //  WriteLambda(); //values for engine on stored in flash
    //  write_lambda = false;
    //  Serial.print("Lambda PID values saved");
    //}

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
