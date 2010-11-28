void DoEngine() {
  switch (engine_state) {
    case ENGINE_OFF:
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      break;
    case ENGINE_ON:
      if (control_state == CONTROL_OFF) {
        TransitionEngine(ENGINE_OFF);
      }
      if (control_state == CONTROL_START) {
        TransitionEngine(ENGINE_STARTING);
      }
      #ifdef INT_HERTZ
      if (CalculatePeriodHertz() < 20) { // Engine is not on
        TransitionEngine(ENGINE_OFF);
      }
      #endif
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF) {
        TransitionEngine(ENGINE_OFF);
      }
//      #ifdef INT_HERTZ
//        // Use RPM detection to stop cranking automatically
//        if (CalculatePeriodHertz() > 40) { //if engine is caught, stop cranking
//          TransitionEngine(ENGINE_ON);
//        }
//        if (engine_end_cranking < millis()) { //if engine still has not caught, stop cranking
//          TransitionEngine(ENGINE_OFF);
//        }
//      #else
        // Use starter button in the standard manual control configuration (push button to start, release to stop cranking)
        if (control_state == CONTROL_ON) {
          TransitionEngine(ENGINE_ON);
        }
//      #endif
      break;
  }
}

void TransitionEngine(int new_state) {
  //can look at engine_state for "old" state before transitioning at the end of this method
  switch (new_state) {
    case ENGINE_OFF:
      analogWrite(FET_IGNITION,0);
      analogWrite(FET_STARTER,0);
      grateMode = GRATE_SHAKE_OFF;
      Serial.println("# New Engine State: Off");
      break;
    case ENGINE_ON:
      analogWrite(FET_IGNITION,255);
      analogWrite(FET_STARTER,0);
      grateMode = GRATE_SHAKE_PRATIO;
      Serial.println("# New Engine State: On");
      break;
    case ENGINE_STARTING:
      analogWrite(FET_IGNITION,255);
      analogWrite(FET_STARTER,255);
      engine_end_cranking = millis() + engine_crank_period;
      grateMode = GRATE_SHAKE_PRATIO;
      Serial.println("# New Engine State: Starting");
      break;
  }
  engine_state=new_state;
}

void DoGovernor() {
  governor_input = CalculatePeriodHertz();
  governor_PID.SetTunings(governor_P[0], governor_I[0], governor_D[0]);
  governor_PID.Compute();
  SetThrottleAngle(governor_output);
}

void InitGovernor() {
  governor_setpoint = 1.0;
  governor_PID.SetMode(AUTO);
  governor_PID.SetSampleTime(20);
  governor_PID.SetInputLimits(0,60);
  governor_PID.SetOutputLimits(throttle_valve_closed,throttle_valve_open);
  governor_output = 0;
}

void SetThrottleAngle(double percent) {
 //servo2_pos = throttle_valve_closed + percent*(throttle_valve_open-throttle_valve_closed);
 servo2_pos = percent;
}


