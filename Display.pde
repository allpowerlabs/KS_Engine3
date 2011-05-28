void DoDisplay() {
  boolean disp_alt; // Var for alternating value display
  char buf[20];
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
	Disp_PutStr("       APL 2011     ");
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
      Disp_CursOff();
      //Row 0
      Disp_RC(0, 0);
      if (millis()-transition_entered<2000) {
        transition_message.toCharArray(buf,21);
        Disp_PutStr(buf);
      } else {
        if (disp_alt) {
          sprintf(buf, "Ttred%4i  ", Temp_Data[T_TRED]);
        } else {
          sprintf(buf, "Ttred%s", T_tredLevel[TempLevelName]);
        }
        Disp_PutStr(buf);
        Disp_RC(0, 11);
        sprintf(buf, "Pcomb%4i", Press[P_COMB] / 25);
        Disp_PutStr(buf);
      }
      
      //Row 1
      Disp_RC(1, 0);
      if (disp_alt) {
        sprintf(buf, "Tbred%4i  ", Temp_Data[T_BRED]);
      } else {
        sprintf(buf, "Tbred%s", T_bredLevel[TempLevelName]);
      }
      Disp_PutStr(buf);
      Disp_RC(1, 11);
      sprintf(buf, "Preac%4i", Press[P_REACTOR] / 25);
      Disp_PutStr(buf);
      
      //Row 2
      Disp_RC(2,0);
      if (P_reactorLevel != OFF) {
        //the value only means anything if the pressures are high enough, otherwise it is just noise
        sprintf(buf, "Prati%4i  ", int(pRatioReactor*100)); //pressure ratio
        Disp_PutStr(buf);
      } else {
        Disp_PutStr("Prati  --  ");
      }
      Disp_RC(2, 11);
      if (true) {
        sprintf(buf, "Pfilt%4i", Press[P_FILTER] / 25);
      } else {
        //TO DO: Implement filter warning
        if (pRatioFilterHigh) {
          sprintf(buf, "Pfilt Bad");
        } else {
          sprintf(buf, "PfiltGood");
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
      Disp_CursOff();
      Disp_RC(0,0);
      #if T_ENG_COOLANT != ABSENT
        sprintf(buf, "Tcool%4i  ", Temp_Data[T_ENG_COOLANT]);
      #else
        sprintf(buf, "Tcool  NA  ");
      #endif
      Disp_PutStr(buf);
      Disp_RC(0,11); 
      Disp_PutStr("           ");
      //Row 1
      Disp_RC(1,0); 
      Disp_PutStr("                    ");
      //Row 2
      Disp_RC(2,0); 
      Disp_PutStr("                    ");
      //Row 3
      Disp_RC(3,0);
      Disp_PutStr("                    ");
      Disp_CursOff();
      break;
    case DISPLAY_LAMBDA:
      double P,I;
      item_count = 4;
      P=lambda_PID.GetP_Param();
      I=lambda_PID.GetI_Param();
      Disp_RC(0,0);
      sprintf(buf, "LamSet%3i  ", int(ceil(lambda_setpoint*100.0)));
      Disp_PutStr(buf);
      Disp_RC(0,11);
      sprintf(buf, "Lambda%3i", int(lambda_input*100.0));
      Disp_PutStr(buf);
      //Row 1
      Disp_RC(1,0);
      sprintf(buf, "P     %3i  ", int(ceil(lambda_PID.GetP_Param()*100.0)));
      Disp_PutStr(buf);
      Disp_RC(1,11);
      sprintf(buf, "I     %3i", int(ceil(lambda_PID.GetI_Param()*100.0)));
      Disp_PutStr(buf);
      Disp_RC(2,0);
      Disp_PutStr("                    ");
      switch (cur_item) {
        case 1: // Lambda setpoint
          if (key == 2) {
            lambda_setpoint += 0.01;
            WriteLambda();
          }
          if (key == 3) {
            lambda_setpoint -= 0.01;
            WriteLambda();
          }          
          Disp_RC(0,0);
          Disp_CursOn();
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV   +    -  ");
          break;
        case 2: //Lambda reading
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV           ");
          Disp_RC(0,11);
          Disp_CursOn();
          break;
        case 3: //Lambda P
          if (key == 2) {
            P += 0.01;
            WriteLambda();
          }
          if (key == 3) {
            P -= 0.01;
            WriteLambda();
          }
          lambda_PID.SetTunings(P,I,0);
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV   +    -  ");
          Disp_RC(1,0);
          Disp_CursOn();
          break;
        case 4: //Lambda I
          if (key == 2) {
            I += 0.1;
            WriteLambda();
          }
          if (key == 3) {
            I -= 0.1;
            WriteLambda();
          }
          lambda_PID.SetTunings(P,I,0);
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV   +    -  ");
          Disp_RC(1,11);
          Disp_CursOn();
          break;
      }
      break;
    case DISPLAY_GRATE:
      int vmin,vmax;
      item_count = 4;
      Disp_RC(0,0);
      sprintf(buf, "GraMin%3i  ", grate_min_interval);
      Disp_PutStr(buf);
      Disp_RC(0,11);
      sprintf(buf, "GraMax%3i", grate_max_interval);
      Disp_PutStr(buf);
      //Row 1
      Disp_RC(1,0);
      sprintf(buf, "GraLen%3i  ", grate_on_interval);
      Disp_PutStr(buf);
      Disp_RC(1,11);
      if (grate_motor_state == GRATE_MOTOR_OFF) {
        Disp_PutStr("Grate Off");
      } else {
        Disp_PutStr("Grate  On");
      }
      Disp_RC(2,0);
      Disp_PutStr("                    ");
      switch (cur_item) {
        case 1: // Grate Min Interval
          vmin = max(0,grate_on_interval);
          vmax = grate_max_interval;
          if (key == 2) {
            
            grate_min_interval += 3;
            grate_min_interval = constrain(grate_min_interval,vmin,vmax);
            CalculateGrate();
            WriteGrate();
          }
          if (key == 3) {
            grate_min_interval -= 3;
            grate_min_interval = constrain(grate_min_interval,vmin,vmax);
            CalculateGrate();
            WriteGrate();
          }
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV   +    -  ");
          Disp_RC(0,0);
          Disp_CursOn();
          break;
        case 2: //Grate Max Interval
          vmin = max(grate_on_interval,grate_min_interval);
          vmax = 255*3;
          if (key == 2) {
            grate_max_interval += 3;
            grate_max_interval = constrain(grate_max_interval,vmin,vmax);
            CalculateGrate();
            WriteGrate();
          }
          if (key == 3) {
            grate_max_interval -= 3;
            grate_max_interval = constrain(grate_max_interval,vmin,vmax);
            CalculateGrate();
            WriteGrate();
          }
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV   +    -  ");
          Disp_RC(0,11);
          Disp_CursOn();
          break;
        case 3: //Grate On Interval
          vmin = 0;
          vmax = min(grate_min_interval,255);
          if (key == 2) {
            grate_on_interval += 1;
            grate_on_interval = constrain(grate_on_interval,vmin,vmax);
            CalculateGrate();
            WriteGrate();
          }
          if (key == 3) {
            grate_on_interval -= 1;
            grate_on_interval = constrain(grate_on_interval,vmin,vmax);
            CalculateGrate();
            WriteGrate();
          }
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV   +    -  ");
          Disp_RC(1,0);
          Disp_CursOn();
          break;
        case 4: //Grate
          if (key == 2) {
            grate_motor_state = GRATE_MOTOR_OFF;
          }
          if (key == 3) {
            grate_motor_state = GRATE_MOTOR_LOW;
          }
          if (grate_motor_state == GRATE_MOTOR_OFF) {
            digitalWrite(FET_GRATE,LOW);
          } else {
            digitalWrite(FET_GRATE,HIGH);
          }
          Disp_RC(3,0);
          Disp_PutStr("NEXT  ADV  OFF   ON ");
          Disp_RC(1,11);
          Disp_CursOn();
          break;
      }
      break;
//    case DISPLAY_TEMP2:
//      break;
//    case DISPLAY_FETS:
//      break;
  }
  key = -1; //important, must clear key to read new input
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
    case DISPLAY_LAMBDA:
      cur_item = 1;
      break;
   case DISPLAY_GRATE:
       cur_item = 1;
       break;
  }
  display_state=new_state;
}

void DoKeyInput() {
  int k;
  k =  Kpd_GetKeyAsync();
  if (key == -1) { //only update key if it has been cleared
    key = k;
  }
  if (key == 0) {
    switch (display_state) {
      case DISPLAY_SPLASH:
        TransitionDisplay(DISPLAY_REACTOR);
        break;
      case DISPLAY_REACTOR:
        TransitionDisplay(DISPLAY_LAMBDA);
        break;
      case DISPLAY_ENGINE:
        TransitionDisplay(DISPLAY_REACTOR);
        break;
      case DISPLAY_LAMBDA:
        TransitionDisplay(DISPLAY_GRATE);
        break;
      case DISPLAY_GRATE:
        TransitionDisplay(DISPLAY_REACTOR);
        break;
    }
    key = -1; //key caught
  }
  if (key == 1) {
    cur_item++;
    if (cur_item>item_count) {
      cur_item = 1;
    }
    key = -1; //key caught
  }
}

void DoHeartBeat() {
  PORTJ ^= 0x80;    // toggle the heartbeat LED
}

void TransitionMessage(String t_message) {
  transition_message = t_message;
  transition_entered = millis();
}
