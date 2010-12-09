// Datalogging
void LogTime(boolean header = false) {
  if (header) {
    PrintColumn("Time");
  } else {
    PrintColumnInt(millis()/100.0); // time since restart in deciseconds
  }
}

void LogFlows(boolean header = false) {
  if (flow_active) {
    if (header) {
      if (P_Q_AIR_ENG != NULL) { PrintColumn("Q_air_eng,"); }
      if (P_Q_AIR_RCT != NULL) { PrintColumn("Q_air_rct,"); }
      if (P_Q_GAS_ENG != NULL) { PrintColumn("Q_gas_eng,"); }
    } else {
      if (P_Q_AIR_ENG != NULL) {
        PrintColumn(air_eng_flow);
      }
      if (P_Q_AIR_RCT != NULL) {
        PrintColumn(air_rct_flow);
      }
      if (P_Q_GAS_ENG != NULL) {
        PrintColumn(gas_eng_flow);
      }
    }
  }
}

void LogPID(boolean header = false) {
  if (header) {
    PrintColumn("Lambda_In");
    PrintColumn("Lambda_Out");
    PrintColumn("Lambda_Setpoint");
    PrintColumn("Lambda_P");
    PrintColumn("Lambda_I");
    PrintColumn("Lambda_D");
  } else {
    PrintColumn(lambda_input);
    PrintColumn(lambda_output);
    PrintColumn(lambda_setpoint);
    PrintColumn(lambda_PID.GetP_Param());
    PrintColumn(lambda_PID.GetI_Param());
    PrintColumn(lambda_PID.GetD_Param());
  }
}

void LogAnalogInputs(boolean header = false) {
  if (header) {
    PrintColumn("ANA0");
    PrintColumn("ANA1");
    PrintColumn("ANA2");
    PrintColumn("ANA3");
    PrintColumn("ANA4");
    PrintColumn("ANA5");
  } else {
    PrintColumnInt(analogRead(ANA0));
    PrintColumnInt(analogRead(ANA1));
    PrintColumnInt(analogRead(ANA2));
    PrintColumnInt(analogRead(ANA3));
    PrintColumnInt(analogRead(ANA4));
    PrintColumnInt(analogRead(ANA5));
  }
}

void LogGrate(boolean header = false) {
  if (header) {
    PrintColumn("grateMode");
    PrintColumn("Grate");
    PrintColumn("P_ratio_reactor");
    PrintColumn("P_ratio_state_reactor");
    PrintColumn("Grate_Val");
  } else {
    PrintColumnInt(grateMode);
    PrintColumnInt(grate_motor_state);
    PrintColumn(pRatioReactor);
    PrintColumn(pRatioReactorLevel[pRatioReactorLevelName]);
    PrintColumn(grate_val);
  }
}

void LogFilter(boolean header = false) {
   if (header) {
    PrintColumn("P_ratio_filter");
    PrintColumn("P_ratio_filter_state");
  } else {
    PrintColumn(pRatioFilter);
    if (pRatioFilterHigh) {
      PrintColumnInt(1);
    } else {
      PrintColumnInt(0);
    }
  }
}

void LogPressures(boolean header = false) {
  if (header) {
    if (GCU_fill == FULLFILL) {
      PrintColumn("P0");
      PrintColumn("P1");
      PrintColumn("P2");
      PrintColumn("P3");
      PrintColumn("P4");
      PrintColumn("P5");
    } else {
      PrintColumn("P0");
      PrintColumn("P4");
    }
  } else {
    if (GCU_fill == FULLFILL) {
      PrintColumnInt(Press[0]);
      PrintColumnInt(Press[1]);
      PrintColumnInt(Press[2]);
      PrintColumnInt(Press[3]);
      PrintColumnInt(Press[4]);
      PrintColumnInt(Press[5]);
    } else {
      PrintColumnInt(Press[0]);
      PrintColumnInt(Press[4]);
    }
  }
}

void LogTemps(boolean header = false) {
  if (header) {
    if (true) {
      PrintColumn("T_tred");
      PrintColumn("T_bred");
      PrintColumn("T_pyro_in");
      PrintColumn("T3");
      PrintColumn("T_pyro_out");
      PrintColumn("T5");
      PrintColumn("T6");
      PrintColumn("T7");
      PrintColumn("T8");
      PrintColumn("T9");
    } else {
      PrintColumn("T0");
      PrintColumn("T1");
      PrintColumn("T2");
      PrintColumn("T3");
      PrintColumn("T4");
      PrintColumn("T5");
      PrintColumn("T6");
      PrintColumn("T7");
      PrintColumn("T8");
      PrintColumn("T9");
    }
  } else {
    PrintColumnInt(Temp_Data[0]);
    PrintColumnInt(Temp_Data[1]);
    PrintColumnInt(Temp_Data[2]);
    PrintColumnInt(Temp_Data[3]);
    PrintColumnInt(Temp_Data[4]);
    PrintColumnInt(Temp_Data[5]);
    PrintColumnInt(Temp_Data[6]);
    PrintColumnInt(Temp_Data[7]);
    PrintColumnInt(Temp_Data[8]);
    PrintColumnInt(Temp_Data[9]);
  }
} 

void LogAuger(boolean header = false) {
  if (header) {
    PrintColumn("AugerCurrent");
    PrintColumn("AugerLevel");
  } else {
    PrintColumnInt(AugerCurrentValue);
    PrintColumn(AugerCurrentLevel[AugerCurrentLevelName]);
  }
}

void LogEnergy(boolean header = false) {
  if (header) {
    PrintColumn("Vrmsave");
    PrintColumn("Irms1ave");
    PrintColumn("Irms2ave");
    PrintColumn("realPower1ave");
    PrintColumn("realPower2ave");
    PrintColumn("apparentPower1ave");
    PrintColumn("apparentPower2ave");
  } else {
    PrintColumn(Vrmsave);
    PrintColumn(Irms1ave);
    PrintColumn(Irms2ave);
    PrintColumnInt(realPower1ave);
    PrintColumnInt(realPower2ave);
    PrintColumnInt(apparentPower1ave);
    PrintColumnInt(apparentPower2ave);
  }
}

void LogPulseEnergy(boolean header = false) {
  if (header) {
    PrintColumn("Power");
    PrintColumn("Energy");
  } else {
    PrintColumnInt(CalculatePulsePower());
    PrintColumnInt(CalculatePulseEnergy());
  }
}

void LogHertz(boolean header = false) {
  if (header) {
    PrintColumn("Hz");
  } else {
    PrintColumnInt(CalculatePeriodHertz());
  }
}

void LogGovernor(boolean header=false) {
    if (header) {
      PrintColumn("ThrottlePercent");
      PrintColumn("ThrottleAngle");
    } else {
      PrintColumn(governor_output);
      PrintColumn(servo2_pos);
    }
}

void PrintColumn(String str) {
   Serial.print(str);
   Serial.print(", ");  
}

void PrintColumn(float str) {
   Serial.print(str);
   Serial.print(", ");  
}

void PrintColumnInt(int str) {
   Serial.print(str);
   Serial.print(", ");  
}

void DoDatalogging() {
  boolean header = false;
  Serial.begin(57600); //reset serial?
  if (lineCount == 0) {
    header = true;
  }
  LogTime(header);
  LogTemps(header);
  LogPressures(header);
  LogAnalogInputs(header);
  //LogFlows(header);
  LogGrate(header);
  LogFilter(header);
  LogPID(header);
  //LogEnergy(header);
  LogAuger(header);
  LogHertz(header);
  //LogGovernor(header);
  LogPulseEnergy(header);
  LogBatteryVoltage(header);
  Serial.println();
  lineCount++;
}
