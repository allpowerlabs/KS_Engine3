// KS_Engine3
// Library to use as basis for testing
// Developed for the APL GCU/PCU: http://gekgasifier.pbworks.com/Gasifier-Control-Unit

#include <EEPROM.h>         // included with Arduino, can read/writes to non-volatile memory
#include <PID_Beta6.h>      // http://www.arduino.cc/playground/Code/PIDLibrary, http://en.wikipedia.org/wiki/PID_controller
#include <adc.h>            // part of KSlibs, for reading analog inputs
#include <display.h>        // part of KSlibs, write to display
#include <fet.h>            // part of KSlibs, control FETs (field effect transitor) to drive motors, solenoids, etc
#include <keypad.h>         // part of KSlibs, read buttons and keypad
#include <pressure.h>       // part of KSlibs, read pressure sensors
#include <servo.h>          // part of KSlibs, not implemented
#include <temp.h>           // part of KSlibs, read thermocouples
#include <timer.h>          // part of KSlibs, not implemented
#include <ui.h>             // part of KSlibs, menu
#include <util.h>           // part of KSlibs, utility functions, GCU_Setup
#include <avr/io.h>         // advanced: provides port definitions for the microcontroller (ATmega1280, http://www.atmel.com/dyn/resources/prod_documents/doc2549.PDF)   

// Analog Input Mapping
#define ANA_LAMBDA ANA0
#define ANA_AUGER ANA1
#define ANA_SWITCH ANA2
#define ANA_V NULL
#define ANA_CT_LEG1 NULL
#define ANA_CT_LEG2 NULL

// FET Mapping
#define FET_IGNITION FET7
#define FET_STARTER FET5

#define FET_GRATE FET6

#define FET_ALARM FET0

//Servo Mapping
#define SERVO_MIXTURE SERVO0
#define SERVO_CALIB SERVO1

//Thermocouple Mapping
#define T_BRED 0
#define T_TRED 1
#define T_PYRO_IN 2
#define T_PYRO_OUT 3
#define T_COMB NULL
#define T_REACTOR_GAS_OUT NULL
#define T_DRYING_GAS_OUT NULL
#define T_FILTER NULL

//Pressure Mapping
#define P_REACTOR 0
#define P_COMB 4
#define P_FILTER 2

// Grate Shaking States
#define GRATE_SHAKE_OFF 0
#define GRATE_SHAKE_ON 1
#define GRATE_SHAKE_PRATIO 2

// Grate Motor States
#define GRATE_MOTOR_OFF 0
#define GRATE_MOTOR_LOW 1
#define GRATE_MOTOR_HIGH 2
#define GRATE_PRATIO_THRESHOLD 180 //number of seconds until we use high shaking mode

// Grate Shaking
#define GRATE_SHAKE_CROSS 5000
#define GRATE_SHAKE_INIT 32000

//Control States
#define CONTROL_OFF 0
#define CONTROL_START 1
#define CONTROL_ON 2

//Engine States
#define ENGINE_OFF 0
#define ENGINE_ON 1
#define ENGINE_STARTING 2

// Datalogging variables
int lineCount = 0;

// Grate turning variables
int grateMode = GRATE_SHAKE_PRATIO; //set default starting state
int grate_motor_state; //changed to indicate state (for datalogging, etc)
int grate_val = GRATE_SHAKE_INIT; //variable that is changed and checked
int grate_pratio_accumulator = 0; // accumulate high pratio to trigger stronger shaking past threshhold
int grate_max_interval = 15*60; //longest total interval in seconds
int grate_min_interval = 15;
int grate_on_interval = 2;
//define these in setup, how much to remove from grate_val each cycle [1 second] (slope)
int m_grate_low; 
int m_grate_high;
int m_grate_on;

// Reactor pressure ratio
float pRatioReactor;
boolean pRatioReactorHigh;

// Filter pressure ratio
float pRatioFilter;
boolean pRatioFilterHigh;
int filter_pratio_accumulator;

// Flow variables
float CfA0_air_rct =0.42123;
float CfA0_air_eng = 0.6555;
float CfA0_gas_eng = 0.81046;
double air_eng_flow;
double air_rct_flow;
double gas_eng_flow;

// Loop variables - 0 is longest, 3 is most frequent, place code at different levels in loop() to execute more or less frequently
//TO DO: move loops to hardware timer and interrupt based control, figure out interrupt prioritization
int loopPeriod0 = 5000;
unsigned long nextTime0;
int loopPeriod1 = 1000;
unsigned long nextTime1;
int loopPeriod2 = 100;
unsigned long nextTime2;
int loopPeriod3 = 10;
unsigned long nextTime3;

//Control
int control_state = CONTROL_OFF;

//Engine
int engine_state = ENGINE_OFF;
unsigned long engine_end_cranking;
int engine_crank_period = 10000; //length of time to crank engine before stopping (milliseconds)

//Hertz
int hertz = 0;

// Lambda variables
// Servo Valve Calibration - will vary depending on the servo valve
//PP #2 (now upgraded to #7)
double premix_valve_open = 20; //calibrated angle for servo valve open
double premix_valve_closed = -120; //calibrated angle for servo valve closed
double premix_valve_range = 50;
double premix_valve_center = -100;
double lambda_setpoint;
double lambda_input;
double lambda_output;
double lambda_value;
double lambda_setpoint_mode[1] = {1.0};
double lambda_P[1] = {0.8}; //engine on values can be updated from EEPROM
double lambda_I[1] = {1.0};
double lambda_D[1] = {0.1};
PID lambda_PID(&lambda_input, &lambda_output, &lambda_setpoint,0.8,1.0,0.1);
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
int P_filter;

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

//Sampling variables
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
int pressureRatioAccumulator = 0;

void setup() {
  GCU_Setup(V3,FULLFILL,P777222);
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
  
  //setup grate slopes
  m_grate_low = (GRATE_SHAKE_INIT-GRATE_SHAKE_CROSS)/grate_max_interval;
  m_grate_high = (GRATE_SHAKE_INIT-GRATE_SHAKE_CROSS)/grate_min_interval;
  m_grate_on = GRATE_SHAKE_CROSS/grate_on_interval;
  Serial.print("#");
  Serial.println(m_grate_low);
  TransitionEngine(ENGINE_ON); //default to engine on. if PCU resets, don't shut a running engine off. in the ENGINE_ON state, should detect and transition out of engine on.
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
      MeasureElectricalPower();
      accumulateEnergyValues();
      if (millis() >= nextTime1) {
        nextTime1 += loopPeriod1;
        averageEnergyValues();
        //DoHertz();
        DoGrate();
        DoFilter();
        DoDatalogging();
        DoAlarmUpdate();
        if (alarm == true) {
          analogWrite(FET_ALARM, 255);
        } else {
          analogWrite(FET_ALARM,0);
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

