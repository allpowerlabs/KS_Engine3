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
	Disp_PutStr("NEXT            HELP");
	Disp_CursOff();
        if (millis()-display_state_entered>2000) {
          TransitionDisplay(DISPLAY_REACTOR);
        }
      break;
    case DISPLAY_REACTOR:
      char buf[20];
      Disp_RC(0, 0);
      sprintf(buf, "Ttred %3ld  ", Temp_Data[T_TRED]);
      Disp_PutStr(buf);
      sprintf(buf, "Tbred %3ld", Temp_Data[T_BRED]);
      Disp_PutStr(buf);
      Disp_RC(1, 0);
      sprintf(buf, "Preac %3ld  ", Press_Data[P_REACTOR] / 25);
      Disp_PutStr(buf);
      sprintf(buf, "Pcomb %3ld", Press_Data[P_COMB] / 25);
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
