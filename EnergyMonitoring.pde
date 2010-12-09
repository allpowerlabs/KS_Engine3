// code adapted from Trystan Lea (OpenEnergyMonitor)
void MeasureElectricalPower() {
  crossCount = 0;
  numberOfSamples = 0;

  //Save initial voltage 
  startV = ADC_ReadChanSync(ANA_V);

  start = millis();

  while ((crossCount < 3) && ((millis()-start)<25)) {
   
     numberOfSamples++;
   
    
   	
     //Used for offset removal
     lastSampleV=sampleV;
     lastSampleI1=sampleI1;
     lastSampleI2=sampleI2;
     
     //Read in voltage and current samples.   
      sampleV = ADC_ReadChanSync(ANA_V);
   
     sampleI1 = ADC_ReadChanSync(ANA_CT_LEG1);
     sampleI2 = ADC_ReadChanSync(ANA_CT_LEG2);
   
     //Find the number of times voltage has crossed the initial voltage
     lastVCross = checkVCross;
     if (startV < sampleV) {
       checkVCross = true;
     } else {
       checkVCross = false;
     }
     if (lastVCross != checkVCross) {
       crossCount++;
     }
   
     //Used for offset removal
     lastFilteredV = filteredV;
     lastFilteredI1 = filteredI1;
     lastFilteredI2 = filteredI2;
   
     //Digital high pass filters to remove 2.5V DC offset (centered on 0V).
     filteredV = 0.996*(lastFilteredV+sampleV-lastSampleV);
     filteredI1 = 0.996*(lastFilteredI1+sampleI1-lastSampleI1);
     filteredI2 = 0.996*(lastFilteredI2+sampleI2-lastSampleI2);
   
     //Phase calibration goes here.
     calibratedV = lastFilteredV + PHASECAL * (filteredV - lastFilteredV);
  
     //Root-mean-square method voltage
     //1) square voltage values
     sqV= calibratedV * calibratedV;
     //2) sum
     sumV += sqV;
   
     //Root-mean-square method current
     //1) square current values
     sqI1 = filteredI1 * filteredI1;
     //2) sum 
     sumI1 += sqI1;
   
     //Root-mean-square method current
     //1) square current values
     sqI2 = filteredI2 * filteredI2;
     //2) sum 
     sumI2 += sqI2;

     //Instantaneous Power
     instP1 = calibratedV * filteredI1;
     //Sum
     sumP1 +=instP1;
   
     //Instantaneous Power
     instP2 = calibratedV * filteredI2;
     //Sum
     sumP2 +=instP2;
  }

  tlength = millis()-start;

  if (numberOfSamples>15){
  
  frequency = 1.0 / (tlength/1000.0);

  //Calculation of the root of the mean of the voltage and current squared (rms)
  //Calibration coeficients applied. 
  Vrms = VCAL*sqrt(sumV / numberOfSamples); 
  Irms1 = ICAL1*sqrt(sumI1 / numberOfSamples); 
  Irms2 = ICAL2*sqrt(sumI2 / numberOfSamples); 

  //Calculate power values
  realPower1 = VCAL*ICAL1*sumP1 / numberOfSamples;
  realPower2 = VCAL*ICAL2*sumP2 / numberOfSamples;

  apparentPower1 = Vrms * Irms1;
  apparentPower2 = Vrms * Irms2;

  powerFactor1 = realPower1 / apparentPower1;
  powerFactor2 = realPower2 / apparentPower2;
  }
  //Reset accumulators
  sumV = 0;
  sumI1 = 0;
  sumP1 = 0;
  
  //Reset accumulators
  sumI2 = 0;
  sumP2 = 0;
}

void accumulateEnergyValues() {
  power_ave_i++;
  realPower1sum += realPower1;
  apparentPower1sum += apparentPower1;
  powerFactor1sum += powerFactor1;
  Irms1sum += Irms1;
  realPower2sum += realPower2;
  apparentPower2sum += apparentPower2;
  powerFactor2sum += powerFactor2;
  Irms2sum += Irms2;
  Vrmssum += Vrms;
}

void averageEnergyValues() {
  realPower1ave = realPower1sum/power_ave_i;
  apparentPower1ave = apparentPower1sum/power_ave_i;
  powerFactor1ave = powerFactor1sum/power_ave_i;
  Irms1ave = Irms1sum/power_ave_i;
  realPower2ave = realPower2sum/power_ave_i;
  apparentPower2ave = apparentPower2sum/power_ave_i;
  powerFactor2ave = powerFactor2sum/power_ave_i;
  Irms2ave = Irms2sum/power_ave_i;
  Vrmsave = Vrmssum/power_ave_i;
  power_ave_i = 0;
  realPower1sum = 0;
  apparentPower1sum = 0;
  powerFactor1sum = 0;
  Irms1sum = 0;
  realPower2sum = 0;
  apparentPower2sum = 0;
  powerFactor2sum = 0;
  Irms2sum = 0;
  Vrmssum = 0;
}

void InitPulseEnergyMonitoring() {
  pinMode(19, INPUT); //PD2
  attachInterrupt(INT_ENERGY_PULSE,DoPulseEnergyMonitoring,RISING);
  energy_last_interrupt = micros();
}

void DoPulseEnergyMonitoring() {
  energy_period = micros() - energy_last_interrupt;
  energy_pulse_count++;
  energy_last_interrupt = micros();
}

double CalculatePulsePower() { //in Watts
    if (micros() - energy_last_interrupt < 10000000) { // if period is longer than 10 seconds, assume no power
      return 1.75 * 3600 * 1.0/(energy_period/1000000.0); //frequency = 1/period in seconds (hertz_period is in microseconds)
    } else {
      return 0;  // less than 2 Hz or no signal, so print 0
    }
}

double CalculatePulseEnergy() { // in Wh
  return energy_pulse_count*1.75;
}
