void DoAuger() {
  #if ANA_AUGER_CURRENT != ABSENT
  AugerCurrentValue = -195*(analogRead(ANA_AUGER_CURRENT)-518); //convert current sensor V to mA
  if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_OFF][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_OFF][1]) {
    AugerCurrentLevel = AUGER_OFF;
    auger_on = false;
  }
  if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_ON][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_ON][1]) {
    AugerCurrentLevel = AUGER_ON;
    auger_on = true;
  }
  if (AugerCurrentValue > AugerCurrentLevelBoundary[AUGER_HIGH][0] && AugerCurrentValue < AugerCurrentLevelBoundary[AUGER_HIGH][1]) {
    AugerCurrentLevel = AUGER_HIGH;
    auger_on = true;
  }
  #endif
  
  #if ANA_FUEL_SWITCH != ABSENT
  FuelSwitchValue = analogRead(ANA_FUEL_SWITCH); // switch voltage, 1024 if on, 0 if off
  if (FuelSwitchValue > 512) {
    FuelSwitchLevel = SWITCH_ON;
    auger_on = true;
  } else {
    FuelSwitchLevel = SWITCH_OFF;
    auger_on = false;
  }
//  if (FuelSwitchValue > FuelSwitchLevelBoundary[SWITCH_OFF][0] && FuelSwitchValue < FuelSwitchLevelBoundary[SWITCH_OFF][1]) {
//    FuelSwitchLevel = SWITCH_OFF;
//    auger_on = false;
//  }
//  if (FuelSwitchValue > FuelSwitchLevelBoundary[SWITCH_ON][0] && FuelSwitchValue < FuelSwitchLevelBoundary[SWITCH_ON][1]) {
//    FuelSwitchLevel = SWITCH_ON;
//    auger_on = true;
//  }
  #endif
  
  #if FET_AUGER != ABSENT && ANA_FUEL_SWITCH != ABSENT
  if (auger_on) {
    analogWrite(FET_AUGER,255);
    auger_on = true;
  } else {
    analogWrite(FET_AUGER,0);
    auger_on = false;
  }
  #endif
}


