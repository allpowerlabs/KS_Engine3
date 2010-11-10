//
void InitPeriodHertz() {
  attachInterrupt(INT_HERTZ,DoPeriodHertz,RISING); //Interrupt #5 - Arduino Pin 18 = PD5
}

void DoPeriodHertz() {
  hertz_period = micros() - hertz_last_interrupt;
  hertz_last_interrupt = micros();
}

double CalculatePeriodHertz() {
    //if (micros() - hertz_last_interrupt < 50000) { // if period is longer than 50k µs, Hz is less than 20 Hz or getting no signal
      return 1.0/(hertz_period/1000000.0); //frequency = 1/period in seconds (hertz_period is in microseconds)
    //} else {
    //  return 0;  // less than 20 Hz or no signal, so print 0
    //}
}

//Timer Code (Hertz Measurement)
void DoHertz() {
  hertz = int(Timer2_Read());
  Timer2_Reset();
}

//Timer
void Timer2_Init() {
  unsigned long time;
  // assumptions:
  //  TC2 is in mode 0 ("normal mode")  (this is true at processor reset)
  //  TC2 prescaler is set to "stopped" (CS2, CS1, CS0 are all zero)
  //  TC2 interrupts are all disabled
  // set external clock input
  ASSR |= 1 << 6;
  // switch to asynchronous operation
  ASSR |= 1 << 5;
  // clear counter
  TCNT2 = 0;
  // reset TCCR2A to default state (may have been trashed by switching to asynch)
  TCCR2A = 0x00;
  // engage prescaler at 1x:
  TCCR2B &= B11111000; //make sure last three bits are set to zero
  TCCR2B |= 0x01;
  // wait for all "update busy" flags to clear
  // WARNING:  THIS WILL HANG THE PROCESSOR IF NO EXTERNAL PULSE INPUT IS PRESENT!
  // I suggest trying without this at first, and seeing if we get acceptable results
  //time = microseconds();
  //while (ASSR & 0x1f & microseconds()-time < 1000) ;
  // clear interrupts
  TIFR2 = 0x00;
}

void Timer2_Reset() {
  TCNT2 = 0x00;
  // while (ASSR & 0x10) ;    // see warning above
  //while (ASSR & 0x1f & microseconds()-time < 1000);
}

unsigned char Timer2_Read() {
  return TCNT2;
}
