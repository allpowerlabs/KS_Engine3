void DoDisplay() {
  boolean disp_alt; // Var for alternating value display
  if (millis() % 2000 > 1000) {
    disp_alt = false;
  } else {
    disp_alt = true;
  }
  switch (display_state) {
    case DISPLAY_SPLASH:
        //Row 0
	Disp_RC(0,0);
	if (GCU_version == V2) {
	Disp_PutStr("   KS GCU V 2.02    ");
	} else if (GCU_version == V3) {
	Disp_PutStr("    KS PCU V 3.02    ");
	}
        //Row 1
	Disp_RC(1,0);
	Disp_PutStr("www.allpowerlabs.org");
        //Row 2
	Disp_RC(2,0);
	Disp_PutStr("    (C) APL 2010    ");
        //Row 3
	Disp_RC(3,0);
	Disp_PutStr("                    ");
	Disp_CursOff();
        //Transition out after delay
        if (millis()-display_state_entered>2000) {
          TransitionDisplay(DISPLAY_REACTOR);
        }
      break;
    case DISPLAY_REACTOR:
      char buf[20];
      //Row 0
      Disp_RC(0, 0);
      if (disp_alt) {
        sprintf(buf, "Ttred%4ld  ", Temp_Data[T_TRED]);
      } else {
        sprintf(buf, "Ttred%s", T_tredLevel[TempLevelName]);
      }
      Disp_PutStr(buf);
      Disp_RC(0, 11);
      sprintf(buf, "Pcomb%4ld", Press_Data[P_COMB] / 25);
      Disp_PutStr(buf);
      
      //Row 1
      Disp_RC(1, 0);
      if (disp_alt) {
        sprintf(buf, "Tbred%4ld  ", Temp_Data[T_BRED]);
      } else {
        sprintf(buf, "Tbred%s", T_bredLevel[TempLevelName]);
      }
      Disp_PutStr(buf);
      Disp_RC(1, 11);
      sprintf(buf, "Preac%4ld", Press_Data[P_REACTOR] / 25);
      Disp_PutStr(buf);
      
      //Row 2
      Disp_RC(2,0);
      if (Press_Data[P_REACTOR] < -500) {
        //the value only means anything if the pressures are high enough, otherwise it is just noise
        sprintf(buf, "Prati%4i  ", int(pRatioReactor*100)); //pressure ratio
        Disp_PutStr(buf);
      } else {
        Disp_PutStr("Prati  --  ");
      }
      Disp_RC(2, 11);
      if (disp_alt) {
        sprintf(buf, "Pfilt%4ld", Press_Data[P_FILTER] / 25);
      } else {
        if (pRatioFilterHigh) {
          sprintf(buf, "Pfilt  Bad");
        } else {
          sprintf(buf, "Pfilt Good");
        }
      }
      Disp_PutStr(buf);
      
      //Row 3
      if (millis() % 4000 > 2000 & alarm != ALARM_NONE) {
        Disp_RC(3,0);
        Disp_PutStr(display_alarm[alarm]);
      } else {
        Disp_RC(3,0);
        if (auger_on) {
          sprintf(buf, "Aug On%3i  ", auger_on_length);
        } else {  
          sprintf(buf, "AugOff%3i  ", auger_off_length);                                                                                                                                                                                                                                                                                                                                                                                                                           
        }
        Disp_PutStr(buf);
        sprintf(buf, "         ");
        //if (disp_alt) {
        //  sprintf(buf, "Hz   %4i", int(CalculatePeriodHertz()));
        //} else {
        //  sprintf(buf, "Batt%5i", int(battery_voltage*10));
        //  //sprintf(buf, "Pow %5i", int(CalculatePulsePower()));
        //}
        Disp_RC(3, 11);
        Disp_PutStr(buf);
      }
      break;
    case DISPLAY_ENGINE:
      break;
//    case DISPLAY_TEMP1:
//      break;
//    case DISPLAY_TEMP2:
//      break;
//    case DISPLAY_FETS:
//      break;
  }
}

void TransitionDisplay(int new_state) {
  //Enter
  display_state_entered = millis();
  switch (new_state) {
    case DISPLAY_SPLASH:
      break;
    case DISPLAY_REACTOR:
      break;
    case DISPLAY_ENGINE:
      break;
  }
  display_state=new_state;
}

void DoKeyInput() {
  key = Kpd_GetKeyAsync();
}

void DoHeartBeat() {
  PORTJ ^= 0x80;    // toggle the heartbeat LED
}
