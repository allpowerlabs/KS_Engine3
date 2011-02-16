void DoControlInputs() {
  int control_input = analogRead(ANA_ENGINE_SWITCH);
  //Two switches have been connected with a resistor ladder. The analog values has been read and used to change states. The state is only changed if the value is close to the known value to provide hysteresis.
//  if (abs(control_input-5)<20) { //"engine off"
//    control_state = CONTROL_OFF;
//  }
//  if (abs(control_input-1023)<20) { //"engine off"
//    control_state = CONTROL_OFF;
//  }
//  if (abs(control_input-467)<20) { //"engine on" and starter button pressed
//    control_state = CONTROL_START;
//  }
//  if (abs(control_input-781)<20) { //"engine on"
//    control_state = CONTROL_ON;
//  }
  if (abs(control_input-10)<20) { //"engine off"
    control_state = CONTROL_OFF;
  }
  if (abs(control_input-1023)<20) { //"engine off"
    control_state = CONTROL_OFF;
  }
  if (abs(control_input-683)<20) { //"engine on" and starter button pressed
    control_state = CONTROL_START;
  }
  if (abs(control_input-515)<20) { //"engine on"
    control_state = CONTROL_ON;
  }
}


