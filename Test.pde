void DoTesting() {
  while (testing_state != TESTING_OFF) {
    //run seperate closed loop while in testing mode, taking all processor cycles
    DoDisplay();
    DoKeyInput();
    DoHeartBeat();
  }
}

void TransitionTesting(int new_state) {
  testing_state_entered = millis();
  Serial.print("#Switching to testing state:");
  Serial.println(TestingStateName[new_state]);
  switch (new_state) {
  case TESTING_OFF:
    break;
  case TESTING_FUEL_AUGER:
    analogWrite(FET_AUGER,255);
    analogWrite(FET_GRATE,0);
    analogWrite(FET_IGNITION,0);
    analogWrite(FET_STARTER,0);
    analogWrite(FET_FLARE_IGNITOR,0);
    analogWrite(FET_O2_RESET,0);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_GRATE:
    analogWrite(FET_AUGER,0); 
    analogWrite(FET_GRATE,255);
    analogWrite(FET_IGNITION,0);
    analogWrite(FET_STARTER,0);
    analogWrite(FET_FLARE_IGNITOR,0);
    analogWrite(FET_O2_RESET,0);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_ENGINE_IGNITION:
    analogWrite(FET_AUGER,0);
    analogWrite(FET_GRATE,0);
    analogWrite(FET_IGNITION,255);
    analogWrite(FET_STARTER,0);
    analogWrite(FET_FLARE_IGNITOR,0);
    analogWrite(FET_O2_RESET,0);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_STARTER:
    analogWrite(FET_AUGER,0);
    analogWrite(FET_GRATE,0);
    analogWrite(FET_IGNITION,0);
    analogWrite(FET_STARTER,255);
    analogWrite(FET_FLARE_IGNITOR,0);
    analogWrite(FET_O2_RESET,0);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;	
  case TESTING_FLARE_IGNITOR:
    analogWrite(FET_AUGER,0);
    analogWrite(FET_GRATE,0);
    analogWrite(FET_IGNITION,0);
    analogWrite(FET_STARTER,0);
    analogWrite(FET_FLARE_IGNITOR,255);
    analogWrite(FET_O2_RESET,0);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_O2_RESET:
    analogWrite(FET_AUGER,0);
    analogWrite(FET_GRATE,0);
    analogWrite(FET_IGNITION,0);
    analogWrite(FET_STARTER,0);
    analogWrite(FET_FLARE_IGNITOR,0);
    analogWrite(FET_O2_RESET,255);
    digitalWrite(FET_ALARM,LOW); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_ALARM:
    analogWrite(FET_AUGER,0);
    analogWrite(FET_GRATE,0);
    analogWrite(FET_IGNITION,0);
    analogWrite(FET_STARTER,0);
    analogWrite(FET_FLARE_IGNITOR,0);
    analogWrite(FET_O2_RESET,0);
    digitalWrite(FET_ALARM,HIGH); // FET6 can't generate PWM due to Servo library using the related timer
    break;
  case TESTING_ANA_LAMBDA:
    break;
  case TESTING_ANA_ENGINE_SWITCH:
    break;
  case TESTING_ANA_FUEL_SWITCH:
    break;
  case TESTING_ANA_OIL_PRESSURE:
    break;
  }
  testing_state=new_state;
}

void GoToNextTestingState() {
  switch (testing_state) {
  case TESTING_OFF:
    TransitionTesting(TESTING_FUEL_AUGER);
    DoTesting();
    break;
  case TESTING_FUEL_AUGER:
    TransitionTesting(TESTING_GRATE);
    break;
  case TESTING_GRATE:
    TransitionTesting(TESTING_ENGINE_IGNITION);
    break;
  case TESTING_ENGINE_IGNITION:
    TransitionTesting(TESTING_STARTER);
    break;
  case TESTING_STARTER:
    TransitionTesting(TESTING_FLARE_IGNITOR);
    break;	
  case TESTING_FLARE_IGNITOR:
    TransitionTesting(TESTING_O2_RESET);
    break;
  case TESTING_O2_RESET:
    TransitionTesting(TESTING_ALARM);
    break;
  case TESTING_ALARM:
    digitalWrite(FET_ALARM,LOW);
    TransitionTesting(TESTING_ANA_LAMBDA);
    break;
  case TESTING_ANA_LAMBDA:
    TransitionTesting(TESTING_ANA_ENGINE_SWITCH);
    break;
  case TESTING_ANA_ENGINE_SWITCH:
    TransitionTesting(TESTING_ANA_FUEL_SWITCH);
    break;
  case TESTING_ANA_FUEL_SWITCH:
    TransitionTesting(TESTING_ANA_OIL_PRESSURE);
    break;
  case TESTING_ANA_OIL_PRESSURE:
    TransitionTesting(TESTING_OFF);
    break;
  }
}







