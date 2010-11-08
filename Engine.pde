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
      if (CalculatePeriodHertz() < 40) { // Engine is not on
        TransitionEngine(ENGINE_OFF);
      }
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF) {
        TransitionEngine(ENGINE_OFF);
      }
      #ifdef INT_HERTZ
        // Use RPM detection to stop cranking automatically
        if (CalculatePeriodHertz() > 40) { //if engine is caught, stop cranking
          TransitionEngine(ENGINE_ON);
        }
        if (engine_end_cranking < millis()) { //if engine still has not caught, stop cranking
          TransitionEngine(ENGINE_OFF);
        }
      #else
        // Use starter button in the standard manual control configuration (push button to start, release to stop cranking)
        if (control_state == CONTROL_ON) {
          TransitionEngine(ENGINE_ON);
        }
      #endif
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
