void DoFlare() {
  switch (flare_state) {
    case FLARE_OFF:
      break;
    case FLARE_USER_SET:
     if (Press[P_REACTOR] < -200 && engine_state != ENGINE_ON) {
        ignitor_on = true;
      } 
      if (Press[P_REACTOR] > -100) {
        ignitor_on = false;
      }
      if (ignitor_on) {
        analogWrite(FET_FLARE_IGNITOR,255);
      } else {
        analogWrite(FET_FLARE_IGNITOR,0);
      }
      break;
  }
  #if FET_BLOWER != ABSENT
  blower_dial = analogRead(ANA_BLOWER_DIAL);
  analogWrite(FET_BLOWER,blower_dial/4);
  #endif
}

void DoReactor() {
  //TODO:Refactor
  //Define reactor condition levels
  for(int i = 0; i < TEMP_LEVEL_COUNT; i++) {
    if (Temp_Data[T_TRED] > T_tredLevelBoundary[i][0] && Temp_Data[T_TRED] < T_tredLevelBoundary[i][1]) {
      T_tredLevel = (TempLevels) i;
    }
  }
  for(int i = 0; i < TEMP_LEVEL_COUNT; i++) {
    if (Temp_Data[T_BRED] > T_bredLevelBoundary[i][0] && Temp_Data[T_BRED] < T_bredLevelBoundary[i][1]) {
      T_bredLevel = (TempLevels) i;
    }
  }
  for(int i = 0; i < P_REACTOR_LEVEL_COUNT; i++) {
    if (Press[P_REACTOR] > P_reactorLevelBoundary[i][0] && Press[P_REACTOR] < P_reactorLevelBoundary[i][1]) {
      P_reactorLevel = (P_reactorLevels) i;
    }
  }
//  switch (reactor_state) {
//    case REACTOR_OFF:
//      break;
//    case REACTOR_IGNITING:
//      break;
//    case REACTOR_WARMING:
//      break;
//    case REACTOR_COOLING:
//      break;
//    case REACTOR_WARM:
//      break;
//  }
}
  

