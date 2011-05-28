void DoAlarmUpdate() {
  //TODO: Move these into their respective object control functions, not alarm
  if (auger_on) {
    // auger on
    auger_on_length++;
    auger_off_length = max(0,auger_off_length*0.8-10);
  } else {
    // auger off
    auger_off_length++;
    auger_on_length = max(0,auger_on_length*.8-10);
  }
  if ((pRatioReactorLevel == PR_LOW || pRatioReactorLevel == PR_HIGH) && P_reactorLevel != OFF) {
    pressureRatioAccumulator += 1;
  } else {
    pressureRatioAccumulator -= 5;
  }
  pressureRatioAccumulator = max(0,pressureRatioAccumulator); //keep value above 0
  pressureRatioAccumulator = min(pressureRatioAccumulator,20); //keep value below 20
}

void DoAlarm() {
  alarm = ALARM_NONE;
  if (P_reactorLevel != OFF) { //alarm only if reactor is running
    if (auger_on_length >= auger_on_alarm_point) {
      Serial.println("# Auger on too long");
      alarm = ALARM_AUGER_ON_LONG;
    }
    if (auger_off_length >= auger_off_alarm_point) {
      Serial.println("# Auger off too long");
      alarm = ALARM_AUGER_OFF_LONG;
    }
    if (pressureRatioAccumulator > 100) {
      Serial.println("# Pressure Ratio is bad");
      alarm = ALARM_BAD_REACTOR;
    }
    if (filter_pratio_accumulator > 100) {
      Serial.println("# Filter or gas flow may be blocked");
      alarm = ALARM_BAD_FILTER;
    }
    #if T_LOW_FUEL != ABSENT
    if (Temp_Data[T_LOW_FUEL] > 230) {
      Serial.println("# Reactor fuel may be low");
      alarm = ALARM_LOW_FUEL_REACTOR;
    }
    #endif
  }
  if (engine_state == ENGINE_ON) {
    if (T_tredLevel != HOT && T_tredLevel != EXCESSIVE) {
      Serial.println("# T_tred too low for running engine");
      alarm = ALARM_LOW_TRED;
    }
    if ((Temp_Data[T_BRED] == EXCESSIVE)) {
      Serial.println("# T_bred too high for running engine");
      alarm = ALARM_HIGH_BRED;
    }
    #if ANA_OIL_PRESSURE != ABSENT
    if (P_reactorLevel == OIL_P_LOW && millis()-engine_state_entered>10000) {
      Serial.println("# Bad oil pressure");
      alarm = ALARM_BAD_OIL_PRESSURE;
    }
    #endif
     #if LAMBDA_SIGNAL_CHECK == TRUE
    if (lambda_input < 0.52) {
      Serial.println("# No O2 Sensor Signal");
      alarm = ALARM_O2_NO_SIG;
    }
    #endif
  }

  if (alarm != ALARM_NONE) {
    digitalWrite(FET_ALARM, HIGH);
  } else { 
    digitalWrite(FET_ALARM,LOW);
  }
}
