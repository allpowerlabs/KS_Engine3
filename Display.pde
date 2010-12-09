void DoDisplay() {
  switch (display_state) {
    case DISPLAY_SPLASH:
	Disp_RC(0,0);
	if (GCU_version == V2) {
	Disp_PutStr("   KS GCU V 2.02    ");
	} else if (GCU_version == V3) {
	Disp_PutStr("    KS PCU V 3.02    ");
	}
	Disp_RC(1,0);
	Disp_PutStr("www.allpowerlabs.org");
	Disp_RC(2,0);
	Disp_PutStr("    (C) APL 2010    ");
	Disp_RC(3,0);
	Disp_PutStr("                    ");
	Disp_CursOff();
        if (millis()-display_state_entered>2000) {
          TransitionDisplay(DISPLAY_REACTOR);
        }
      break;
    case DISPLAY_REACTOR:
      char buf[20];
      Disp_RC(0, 0);
      sprintf(buf, "Ttred%4ld  ", Temp_Data[T_TRED]);
      Disp_PutStr(buf);
      sprintf(buf, "Pcomb%4ld", Press_Data[P_COMB] / 25);
      Disp_PutStr(buf);
      
      Disp_RC(1, 0);
      sprintf(buf, "Tbred%4ld  ", Temp_Data[T_BRED]);
      Disp_PutStr(buf);
      sprintf(buf, "Preac%4ld", Press_Data[P_REACTOR] / 25);
      Disp_PutStr(buf);
      
      Disp_RC(2,0);
      if (Press_Data[P_REACTOR] < -500) {
        sprintf(buf, "Prati%4i  ", int(pRatioReactor*100)); //pressure ratio
        Disp_PutStr(buf);
      } else {
        Disp_PutStr("Prati  --  ");
      }
      sprintf(buf, "Pfilt%4ld", Press_Data[P_FILTER] / 25);
      Disp_PutStr(buf);
      
      Disp_RC(3,0);
      if (auger_on) {
        sprintf(buf, "Aug On%3i  ", auger_on_length);
      } else {  
        sprintf(buf, "AugOff%3i  ", auger_off_length);                                                                                                                                                                                                                                                                                                                                                                                                                           
      }
      Disp_PutStr(buf);
      if (millis() % 2000 > 1000) {
        sprintf(buf, "Hz   %4i", int(CalculatePeriodHertz()));
      } else {
        sprintf(buf, "Batt%5i", int(battery_voltage*10));
        //sprintf(buf, "Pow %5i", int(CalculatePulsePower()));
      }
      Disp_PutStr(buf);
      break;
    case DISPLAY_ENGINE:
      break;
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
