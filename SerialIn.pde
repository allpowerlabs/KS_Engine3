// SerialIn
void DoSerialIn() {
  int incomingByte = 0;
  double p,i,d;
  double p_d =0.02;
  double i_d = 0.02;
  double d_d = 0.02;
  // Serial input
  if (Serial.available() > 0) {
    p=lambda_P[0];
    i=lambda_I[0];
    d=lambda_D[0];
    serial_last_input = Serial.read();
    switch (serial_last_input) {
    case 'p':
      PrintLambdaUpdate(p,i,d,p+p_d,i,d);
      p=p+p_d;
      lambda_P[0]=p;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'P':
      PrintLambdaUpdate(p,i,d,p-p_d,i,d);
      p=p-p_d;
      lambda_P[0]=p;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'i':
      PrintLambdaUpdate(p,i,d,p,i+i_d,d);
      i=i+i_d;
      lambda_I[0]=i;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'I':
      PrintLambdaUpdate(p,i,d,p,i-i_d,d);
      i=i-i_d;
      lambda_I[0]=i;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'd':
      PrintLambdaUpdate(p,i,d,p,i,d+d_d);
      d=d+d_d;
      lambda_D[0]=d;
      lamba_updated_time = millis();
      write_lambda = true;
      break;
    case 'D':
      PrintLambdaUpdate(p,i,d,p,i,d-d_d);
      d=d-d_d;
      lambda_D[0]=d;
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
      grate_val = GRATE_SHAKE_CROSS; //set grate val to shake for grate_on_interval
      Serial.println("#Grate Shaken");
      break;
    case 'G':  
      switch (grateMode) {
      case GRATE_SHAKE_OFF:
        grateMode = GRATE_SHAKE_ON;
        Serial.println("#Grate Mode: On");
        break;
      case GRATE_SHAKE_ON:
        grateMode = GRATE_SHAKE_PRATIO;
        Serial.println("#Grate Mode: Pressure Ratio");
        break;
      case GRATE_SHAKE_PRATIO:
        grateMode = GRATE_SHAKE_OFF;
        Serial.println("#Grate Mode: Off");
        break;
      }
      break;  
    case 'm':
      grate_max_interval += 5;
      grate_min_interval = grate_max_interval*0.5;
      Serial.print("#Grate Max Interval now:");
      Serial.println(grate_max_interval);
      Serial.print("#Grate Min Interval now:");
      Serial.println(grate_min_interval);
      break;
    case 'M':
      grate_max_interval -= 5;
      grate_min_interval = grate_max_interval*0.5;
      Serial.print("#Grate Max Interval now:");
      Serial.println(grate_max_interval);
      Serial.print("#Grate Min Interval now:");
      Serial.println(grate_min_interval);
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

