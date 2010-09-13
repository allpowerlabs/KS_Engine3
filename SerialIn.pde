// SerialIn
void DoSerialIn() {
  int incomingByte = 0;
  double p,i,d;
  double p_d =0.02;
  double i_d = 0.02;
  double d_d = 0.02;
  // Serial input
  if (Serial.available() > 0) {
    p=lambda_P[ENGINE_ON];
    i=lambda_I[ENGINE_ON];
    d=lambda_D[ENGINE_ON];
    switch (Serial.read()) {
    case 'p':
      PrintLambdaUpdate(p,i,d,p+p_d,i,d);
      p=p+p_d;
      lambda_P[ENGINE_ON]=p;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'P':
      PrintLambdaUpdate(p,i,d,p-p_d,i,d);
      p=p-p_d;
      lambda_P[ENGINE_ON]=p;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'i':
      PrintLambdaUpdate(p,i,d,p,i+i_d,d);
      i=i+i_d;
      lambda_I[ENGINE_ON]=i;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'I':
      PrintLambdaUpdate(p,i,d,p,i-i_d,d);
      i=i-i_d;
      lambda_I[ENGINE_ON]=i;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'd':
      PrintLambdaUpdate(p,i,d,p,i,d+d_d);
      d=d+d_d;
      lambda_D[ENGINE_ON]=d;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'D':
      PrintLambdaUpdate(p,i,d,p,i,d-d_d);
      d=d-d_d;
      lambda_D[ENGINE_ON]=d;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'c':
      CalibratePressureSensors();
      LoadPressureSensorCalibration();
      break;
    case 's':
      servo1_pos += 10;
      Serial.print("#Servo1 (degrees) now:");
      Serial.println(servo1_pos);
      break;
    case 'S':
      servo1_pos -= 10;
      Serial.print("#Servo1 (degrees) now:");
      Serial.println(servo1_pos);
      break;
    case 'l':
      lambda_setpoint += 0.01;
      Serial.print("#Lambda Setpoint now:");
      Serial.println(lambda_setpoint);
      break;
    case 'L':
      lambda_setpoint -= 0.01;
      Serial.print("#Lambda Setpoint now:");
      Serial.println(lambda_setpoint);
      break;
    case 't':
      loopPeriod1 = min(loopPeriod1+100,loopPeriod2);
      Serial.print("#Sample Period now:");
      Serial.println(loopPeriod1);
      break;
    case 'T':
      loopPeriod1 = min(loopPeriod1-100,loopPeriod2);
      Serial.print("#Sample Period now:");
      Serial.println(loopPeriod1);
      break;
    case 'g':  
      analogWrite(GRATE_SOLENOID, 255);
      delay(gratePulseLength);
      analogWrite(GRATE_SOLENOID, 0);
      Serial.println("#Grate Shaken");
      grateOn = true;
      break;
    case 'G':  
      switch (grateMode) {
      case GRATE_OFF:
        grateMode = GRATE_ON;
        Serial.println("#Grate Mode: On");
        break;
      case GRATE_ON:
        grateMode = GRATE_PRATIO;
        Serial.println("#Grate Mode: Pressure Ratio");
        break;
      case GRATE_PRATIO:
        grateMode = GRATE_OFF;
        Serial.println("#Grate Mode: Off");
        break;
      }
      break;  
    case 'm':
      gratePeriod += 500;
      Serial.print("#Grate Interval now:");
      Serial.println(gratePeriod);
      break;
    case 'M':
      gratePeriod -= 500;
      Serial.print("#Grate Interval now:");
      Serial.println(gratePeriod);
      break;   
    }
  }
}

void PrintLambdaUpdate(double P, double I, double D, double nP, double nI, double nD) {
  Serial.print("#Updating Lambda PID from [");
  Serial.print(P);
  Serial.print(",");
  Serial.print(I);
  Serial.print(",");
  Serial.print(D);
  Serial.print("] to [");
  Serial.print(nP);
  Serial.print(",");
  Serial.print(nI);
  Serial.print(",");
  Serial.print(nD);
  Serial.println("]");
}

