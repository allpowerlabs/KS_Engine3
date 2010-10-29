void DoAlarmUpdate() {
  if (analogRead(ANA1) > 256) {
    // auger on
    auger_on_length++;
    auger_off_length = max(0,auger_off_length*0.8-10);
  } else {
    // auger off
    auger_off_length++;
    auger_on_length = max(0,auger_on_length*.8-10);
  }
  if (pRatioReactorHigh) {
    pressureRatioAccumulator += 1;
  } else {
    pressureRatioAccumulator -= 2;
  }
  pressureRatioAccumulator = max(0,pressureRatioAccumulator);
}

void DoAlarm() {
  alarm = false;
  if (P_reactor < -500) { //alarm only if reactor is running
    if (auger_on_length >= auger_on_alarm_point) {
      Serial.println("# Auger on too long");
      alarm = true;
    }
    if (auger_off_length >= auger_off_alarm_point) {
      Serial.println("# Auger off too long");
      alarm = true;
    }
    if (Temp_Data[T_TRED] < 830 || Temp_Data[T_BRED] < 830) {
      Serial.println("# Temperatures too low for running engine");
      alarm = true;
    }
  }
  if (pressureRatioAccumulator > 300) {
      Serial.println("# Pressure Ratio is bad");
      alarm = true;
  }
//  if (Temp_Data[LOW_FUEL_TC] > 230) {
//    Serial.println("# Reactor fuel may be low");
//    alarm = true;
//  }
//  if (Vrmsave > 50 & (Temp_Data[T_TRED]<790 || Temp_Data[T_BRED]<790)) {
//    Serial.println("# T_tred and/or T_bred below 790°C while engine is running");
//    alarm = true;
//  }
}
