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
