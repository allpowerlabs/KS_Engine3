void DoGrate() {
  pRatio = (float)P_comb/(float)P_reactor;
  pRatioHigh = (pRatio < 0.4 && P_reactor < -200 && P_comb < -50);
  //if (millis() >= nextGrate-gratePulseLength) {
    if (grateMode == GRATE_ON || (pRatioHigh && grateMode == GRATE_PRATIO)) {
      analogWrite(GRATE_SOLENOID, 255);
      grateOn = true;
      //re-do brackets for period based shake
    } else {
      analogWrite(GRATE_SOLENOID,0);
      grateOn = false;
  }
  if (millis() >= nextGrate) {
    nextGrate += gratePeriod;
  }
  }
