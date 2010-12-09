// Datalogging
void LogTime(boolean header = false) {
  if (header) {
    PrintColumn("Time");
  } else {
    PrintColumn(millis()/100); // time since restart in deciseconds
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
  } else {
    PrintColumn(ADC_ReadChanSync(0));
    PrintColumn(ADC_ReadChanSync(1));
    PrintColumn(ADC_ReadChanSync(2));
    PrintColumn(ADC_ReadChanSync(3));
  }
}

void LogGrate(boolean header = false) {
  if (header) {
    PrintColumn("Grate");
    PrintColumn("P_ratio_reactor");
    PrintColumn("P_ratio_state_reactor");
    PrintColumn("Grate_Val");
  } else {
    PrintColumn(grate_motor_state);
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
      PrintColumn(1);
    } else {
      PrintColumn(0);
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
      PrintColumn(Press[0]);
      PrintColumn(Press[1]);
      PrintColumn(Press[2]);
      PrintColumn(Press[3]);
      PrintColumn(Press[4]);
      PrintColumn(Press[5]);
    } else {
      PrintColumn(Press[0]);
      PrintColumn(Press[4]);
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
    PrintColumn(Temp_Data[0]);
    PrintColumn(Temp_Data[1]);
    PrintColumn(Temp_Data[2]);
    PrintColumn(Temp_Data[3]);
    PrintColumn(Temp_Data[4]);
    PrintColumn(Temp_Data[5]);
    PrintColumn(Temp_Data[6]);
    PrintColumn(Temp_Data[7]);
    PrintColumn(Temp_Data[8]);
    PrintColumn(Temp_Data[9]);
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
    PrintColumn(realPower1ave);
    PrintColumn(realPower2ave);
    PrintColumn(apparentPower1ave);
    PrintColumn(apparentPower2ave);
  }
}

void LogPulseEnergy(boolean header = false) {
  if (header) {
    PrintColumn("Power");
    PrintColumn("Energy");
  } else {
    PrintColumn(CalculatePulsePower());
    PrintColumn(CalculatePulseEnergy());
  }
}

void LogHertz(boolean header = false) {
  if (header) {
    PrintColumn("Hz");
  } else {
    CalculatePeriodHertz();
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
  LogFlows(header);
  LogGrate(header);
  LogFilter(header);
  LogPID(header);
  //LogEnergy(header);
  LogPulseEnergy(header);
  LogAuger(header);
  LogHertz(header);
  LogGovernor(header);
  Serial.println();
  lineCount++;
}
