void DoAlarmUpdate() {
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
  alarm = false;
  if (P_reactorLevel != OFF) { //alarm only if reactor is running
    if (auger_on_length >= auger_on_alarm_point) {
      Serial.println("# Auger on too long");
      alarm = true;
    }
    if (auger_off_length >= auger_off_alarm_point) {
      Serial.println("# Auger off too long");
      alarm = true;
    }
    if (pressureRatioAccumulator > 300) {
      Serial.println("# Pressure Ratio is bad");
      alarm = true;
    }
    if (filter_pratio_accumulator > 300) {
      Serial.println("# Filter or gas flow may be blocked");
      alarm = true;
    }
    #ifdef T_LOW_FUEL
    if (Temp_Data[T_LOW_FUEL] > 230) {
      Serial.println("# Reactor fuel may be low");
      alarm = true;
    }
    #endif
  }
  if ((Temp_Data[T_TRED] < 800) && engine_state == ENGINE_ON) {
      Serial.println("# T_tred too low for running engine");
      alarm = true;
  }
  if ((Temp_Data[T_BRED] > 900) && engine_state == ENGINE_ON) {
      Serial.println("# T_bred too high for running engine");
      alarm = true;
  }
}
