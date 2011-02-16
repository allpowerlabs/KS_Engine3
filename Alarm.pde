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
  if (pRatioReactorLevel == BAD) {
    pressureRatioAccumulator += 1;
  } else {
    pressureRatioAccumulator -= 2;
  }
  pressureRatioAccumulator = max(0,pressureRatioAccumulator);
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
    if (pressureRatioAccumulator > 300) {
      Serial.println("# Pressure Ratio is bad");
      alarm = ALARM_BAD_REACTOR;
    }
    if (filter_pratio_accumulator > 300) {
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
  if ((Temp_Data[T_TRED] < 800) && engine_state == ENGINE_ON) {
      Serial.println("# T_tred too low for running engine");
      alarm = ALARM_HIGH_TRED;
  }
  if ((Temp_Data[T_BRED] > 900) && engine_state == ENGINE_ON) {
      Serial.println("# T_bred too high for running engine");
      alarm = ALARM_HIGH_BRED;
  }
  if (alarm != ALARM_NONE) {
    digitalWrite(FET_ALARM, HIGH);
  } else {
    digitalWrite(FET_ALARM,LOW);
  }
}
