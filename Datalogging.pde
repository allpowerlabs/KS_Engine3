// Datalogging
void LogTime(boolean header = false) {
  if (header) {
    Serial.print("Time,");
  } else {
    Serial.print(millis()/100); // time since restart in deciseconds
    Serial.print(", ");
  }
}

void LogFlows(boolean header = false) {
  if (header) {
    Serial.print("Q_air_eng,Q_air_rct,Q_gas_eng,");
  } else {
    Serial.print(air_eng_flow);
    Serial.print(", ");
    Serial.print(air_rct_flow);
    Serial.print(", ");
    Serial.print(gas_eng_flow);
    Serial.print(", ");
  }
}

void LogPID(boolean header = false) {
  if (header) {
    Serial.print("Lambda_In,Lambda_Out,Lambda_Setpoint,Lambda_P,Lambda_I,Lambda_D,");
  } else {
    Serial.print(lambda_input);
    Serial.print(", ");
    Serial.print(lambda_output);
    Serial.print(", ");
    Serial.print(lambda_setpoint);
    Serial.print(", ");
    Serial.print(lambda_PID.GetP_Param());
    Serial.print(", ");
    Serial.print(lambda_PID.GetI_Param());
    Serial.print(", ");
    Serial.print(lambda_PID.GetD_Param());
    Serial.print(", ");
  }
}

void LogAnalogInputs(boolean header = false) {
  if (header) {
    Serial.print("ANA0,ANA1,ANA2,ANA3,");
  } else {
    Serial.print(ADC_ReadChanSync(0));
    Serial.print(", ");  
    Serial.print(ADC_ReadChanSync(1));
    Serial.print(", ");
    Serial.print(ADC_ReadChanSync(2));
    Serial.print(", ");
    Serial.print(ADC_ReadChanSync(3));
    Serial.print(", ");
  }
}

void LogGrate(boolean header = false) {
  if (header) {
    Serial.print("Grate,P_ratio_reactor,P_ratio_state_reactor,Grate_Val,");
  } else {
    Serial.print(grate_motor_state);
    Serial.print(", ");
    Serial.print(pRatioReactor);
    Serial.print(", ");
    if (pRatioReactorHigh) {
      Serial.print(1);
    } else {
      Serial.print(0);
    }
    Serial.print(", ");
    Serial.print(grate_val);
    Serial.print(", ");
  }
}

void LogFilter(boolean header = false) {
   if (header) {
     Serial.print("P_ratio_filter,P_ratio_filter_state,");
  } else {
    Serial.print(pRatioFilter);
    Serial.print(", ");
    if (pRatioFilterHigh) {
      Serial.print(1);
    } else {
      Serial.print(0);
    }
    Serial.print(", ");
  }
}

void LogPressures(boolean header = false) {
  if (header) {
    if (GCU_fill == FULLFILL) {
      Serial.print("P0,P1,P2,P3,P4,P5,");
    } else {
      Serial.print("P0,P4,");
    }
  } else {
    if (GCU_fill == FULLFILL) {
      Serial.print(Press[0]);
      Serial.print(", ");
      Serial.print(Press[1]);
      Serial.print(", ");
      Serial.print(Press[2]);
      Serial.print(", ");
      Serial.print(Press[3]);
      Serial.print(", ");
      Serial.print(Press[4]);
      Serial.print(", ");
      Serial.print(Press[5]);
      Serial.print(", ");
    } else {
      Serial.print(Press[0]);
      Serial.print(", ");
      Serial.print(Press[4]);
      Serial.print(", ");
    }
  }
}

void LogTemps(boolean header = false) {
  if (header) {
    if (true) {
      Serial.print("T_tred,T_bred,T_pyro_in,T3,T_pyro_out,T5,T6,T7,T8,T9,");
    } else {
      Serial.print("T0,T1,T2,T3,T4,T5,T6,T7,T8,T9,");
    }
  } else {
    Serial.print(Temp_Data[0]);
    Serial.print(", ");
    Serial.print(Temp_Data[1]);
    Serial.print(", ");
    Serial.print(Temp_Data[2]);
    Serial.print(", ");
    Serial.print(Temp_Data[3]);
    Serial.print(", ");
    Serial.print(Temp_Data[4]);
    Serial.print(", ");
    Serial.print(Temp_Data[5]);
    Serial.print(", ");
    Serial.print(Temp_Data[6]);
    Serial.print(", ");
    Serial.print(Temp_Data[7]);
    Serial.print(", ");
    Serial.print(Temp_Data[8]);
    Serial.print(", ");
    Serial.print(Temp_Data[9]);
    Serial.print(", ");
  }
} 

void LogAuger(boolean header = false) {
  if (header) {
    Serial.print("Auger,");
  } else {
    Serial.print(analogRead(ANA1)); //Phidgets "2" - auger sense on APL skid
    Serial.print(", ");
  }
}

void LogEnergy(boolean header = false) {
  if (header) {
    Serial.print("Vrmsave,Irms1ave,Irms2ave,realPower1ave,realPower2ave,apparentPower1ave,apparentPower2ave,");
  } else {
    Serial.print(Vrmsave);
    Serial.print(", ");
    Serial.print(Irms1ave);
    Serial.print(", ");
    Serial.print(Irms2ave);
    Serial.print(", ");
    Serial.print(realPower1ave);
    Serial.print(", ");  
    Serial.print(realPower2ave);
    Serial.print(", ");  
    Serial.print(apparentPower1ave);
    Serial.print(", ");  
    Serial.print(apparentPower2ave);
  }
}

void LogHertz(boolean header = false) {
  if (header) {
    Serial.print("Hz");
    Serial.print(", ");  
  } else {
    Serial.print(CalculatePeriodHertz());
    Serial.print(", ");  
  }
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
  LogAuger(header);
  LogHertz(header);
  Serial.println();
  lineCount++;
}
