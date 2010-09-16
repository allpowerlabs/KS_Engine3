#include <EEPROM.h>
#include <PID_Beta6.h>
#include <adc.h>
#include <display.h>
#include <fet.h>
#include <keypad.h>
#include <pressure.h>
#include <servo.h>
#include <temp.h>
#include <timer.h>
#include <ui.h>
#include <util.h>
#include <avr/io.h>    

#define ANA_LAMBDA 0
#define ANA_V 1
#define ANA_CT_LEG1 2
#define ANA_CT_LEG2 3

//engine mode
#define ENGINE_OFF 0
#define ENGINE_ON 1
#define ENGINE_STARTING 2

#define GRATE_OFF 0
#define GRATE_ON 1
#define GRATE_PRATIO 2

#define ALARM_FET FET6

//Dataloggin variables
int lineCount = 0;

// Grate turning variables
int GRATE_SOLENOID = FET5;
//int GRATE_MOTOR_0 = FET7;
//int GRATE_MOTOR_1 = FET6;
unsigned long gratePeriod = 300000;
int gratePulseLength = 30000;
int grateMode = GRATE_PRATIO;
unsigned long nextGrate;
float pRatio, pRatioSmooth;
boolean pRatioHigh;
boolean grateOn;

// Flow variables
float CfA0_air_rct =0.42123;
float CfA0_air_eng = 0.6555;
float CfA0_gas_eng = 0.81046;
double air_eng_flow;
double air_rct_flow;
double gas_eng_flow;

int loopPeriod0 = 5000;
unsigned long nextTime0;
int loopPeriod1 = 1000;
unsigned long nextTime1;
int loopPeriod2 = 100;
unsigned long nextTime2;
int loopPeriod3 = 10;
unsigned long nextTime3;

//Hertz
int hertz = 0;

// Lambda variables
// Servo Valve Calibration - will vary depending on the servo valve
//PP #6
double premix_valve_open = 120; //calibrated angle for servo valve open
double premix_valve_closed = 0; //calibrated angle for servo valve closed
double premix_valve_range = 50;
double premix_valve_center = 50;
//PP #2
//double premix_valve_open = 20; //calibrated angle for servo valve open
//double premix_valve_closed = -120; //calibrated angle for servo valve closed
//double premix_valve_range = 50;
//double premix_valve_center = -75;
double lambda_setpoint;
double lambda_input;
double lambda_output;
double lambda_value;
double lambda_setpoint_mode[3] = {1.0, 1.0, 1.0};
double lambda_P[3] = {0.6,0.6,1}; //engine on values can be updated from EEPROM
double lambda_I[3] = {1.0,1.0,1.0};
double lambda_D[3] = {0,0,0};
PID lambda_PID(&lambda_input, &lambda_output, &lambda_setpoint,0.6,1.0,0);
unsigned long lamba_updated_time;
boolean write_lambda = false;
boolean lambda_closed_loop = false;

// Pressure variables
int Press_Calib[6];
int Press[6]; //values corrected for sensor offset (calibration)
int P_air_in;
int P_gas_out;
int P_comb;
float P_comb_smooth;
int P_reactor;

//Servo 
int servo_alt = 0; //used to pulse every other time through loop (~20 ms)

//Servo0
float servo0_pos = 0;
float servo0_db = 0; // used to deadband the servo movement

//Servo1
float servo1_pos;
float servo1_db = 0; // used to deadband the servo movement

//Open Energy Monitoring Variables
//Setup variables
int numberOfSamples = 0;
//Calibration coeficients (ref/calculated * calib. coefficient)
double VCAL = 0.52;
double ICAL1 = 0.151630734;
double ICAL2 = 0.14774915;
double PHASECAL = 2.3; //add two for I1 and I2. found by matching w/ code. shifting value and hitting calibrated power factor.

//Sample variables
int lastSampleV,sampleV;
int lastSampleI1,sampleI1;
int lastSampleI2,sampleI2;
//Filter variables
double lastFilteredV,filteredV;
double lastFilteredI1, filteredI1;
double lastFilteredI2, filteredI2;
//Stores the phase calibrated instantaneous voltage.
double calibratedV;
//Power calculation variables
double sqV,sumV;
double sqI1,instP1,sumI1,sumP1;
double sqI2,instP2,sumI2,sumP2;
//Useful value variables
double realPower1,
       apparentPower1,
       powerFactor1,
       Vrms,
       Irms1;
//Useful value variables
double realPower2,
       apparentPower2,
       powerFactor2,
       Irms2;
// averages
int power_ave_i;
double realPower1sum, apparentPower1sum,powerFactor1sum,Irms1sum;
double realPower2sum, apparentPower2sum,powerFactor2sum,Irms2sum;
double Vrmssum;
double realPower1ave, apparentPower1ave,powerFactor1ave,Irms1ave;
double realPower2ave, apparentPower2ave,powerFactor2ave,Irms2ave;
double Vrmsave;
//Whole phase check variables
int startV;
bool lastVCross, checkVCross;
int crossCount;
unsigned long start,tlength;
double frequency;

// Alarm
int auger_on_length = 0;
int auger_off_length = 0;
unsigned int auger_on_alarm_point = 300;
unsigned int auger_off_alarm_point = 900;
boolean alarm;
int LOW_FUEL_TC = 3;
int alarm_interval = 5; // in seconds

void setup() {
  GCU_Setup(V3,FULLFILL,1);
  //
  DDRJ |= 0x80;      
  PORTJ |= 0x80;   
  delay(1);	
  
  // timer initialization
  nextTime0 = millis() + loopPeriod0;
  nextTime1 = millis() + loopPeriod1;
  nextTime2 = millis() + loopPeriod2;
  nextTime3 = millis() + loopPeriod3;

  Lambda_Init(); // params should be pulled out to here
  LoadPressureSensorCalibration();
  //LoadLambda(); - must save lambda data first?
  Serial.begin(57600);

  Disp_Init();
  Kpd_Init();
  UI_Init();
  ADC_Init();
  Temp_Init();
  Press_Init();
  Fet_Init();
  Servo_Init();
  Timer_Init();
  Timer2_Init();

  Disp_Reset();
  Kpd_Reset();
  UI_Reset();
  ADC_Reset();
  Temp_Reset();
  Press_Reset();
  Fet_Reset();
  Servo_Reset();
  Timer_Reset();
  Timer2_Reset();
}

void loop() {
  int key;
  if (millis() >= nextTime3) {
    nextTime3 += loopPeriod3;
    // first, read all KS's sensors
    Temp_ReadAll();  // reads into array Temp_Data[], in deg C
    Press_ReadAll(); // reads into array Press_Data[], in hPa
    Timer_ReadAll(); // reads pulse timer into Timer_Data, in RPM ??? XXX
    UpdateCalibratedPressure();
    DoPressure();
    //DoFlow();
    DoSerialIn();
    DoLambda();
    DoServos();
    if (millis() >= nextTime2) {
      //MeasureElectricalPower();
      //accumulateEnergyValues();
      if (millis() >= nextTime1) {
        nextTime1 += loopPeriod1;
        //averageEnergyValues();
        //DoHertz();
        DoGrate();
        DoDatalogging();
        DoAlarmUpdate();
        grateOn = false;
        if (alarm == true) {
          analogWrite(ALARM_FET, 255);
        } else {
          analogWrite(ALARM_FET,0);
        }
        if (millis() >= nextTime0) {
          nextTime0 += loopPeriod0;
          DoAlarm();
        }
      }
    }
    // END USER CONTROL CODE
    UI_DoScr();       // output the display screen data, 
    // (default User Interface functions are in library KS/ui.c)
    // XXX should be migrated out of library layer, up to sketch layer                      
     key = Kpd_GetKeyAsync();
    // get key asynnchronous (doesn't wait for a keypress)
    // returns -1 if no key

    UI_HandleKey(key);  // the other two thirds of the UI routines:
    // given the key press (if any), then update the internal
    //   User Interface data structures
    // ALSO: Manipulate the various output data structures
    //   based on the keypad input

    Fet_WriteAll();   // Write the FET output data to the PWM hardware
    Servo_WriteAll(); // Write the Futaba hobby servo data to the PWM hardware

    PORTJ ^= 0x80;    // toggle the heartbeat LED
  }
}

