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
      if (Press[P_REACTOR] > -100) { //placeholder signal for RPM measurement
        TransitionEngine(ENGINE_OFF);
      }
      break;
    case ENGINE_STARTING:
      if (control_state == CONTROL_OFF) {
        TransitionEngine(ENGINE_OFF);
      }
      if (control_state == CONTROL_ON) {
        TransitionEngine(ENGINE_ON);
      }
      //if (engine_end_cranking < millis()) { //stop cranking engine based on time out
      //  TransitionEngine(ENGINE_ON);
      //}
      //if (Press[P_REACTOR] < -100) {
      //  TransitionEngine(ENGINE_ON);
      //}
      //TODO: Detect engine start up and stop cranking when it picks up
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
