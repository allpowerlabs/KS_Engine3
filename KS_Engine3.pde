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
#define ANA_LAMBDA 0
#define ANA_AUGER 1
#define ANA_SWITCH 2
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

//Thermocouple Mappings
#define T_BRED 0
#define T_TRED 1
#define T_PYRO_IN 2
#define T_PYRO_OUT 3
#define T_COMB NULL
#define T_REACTOR_GAS_OUT NULL
#define T_DRYING_GAS_OUT NULL
#define T_FILTER NULL
//#define T_LOW_FUEL NULL

//Pressure Mapping
#define P_REACTOR 0
#define P_COMB 4
#define P_FILTER 1
#define P_Q_AIR_ENG 5
#define P_Q_AIR_RCT NULL
#define P_Q_GAS_ENG NULL

//Interrupt Mapping
#define INT_HERTZ 5 //interrupt number (not pin number)

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

//Lambda States
#define LAMBDA_CLOSEDLOOP 0
#define LAMBDA_SEALED 1
#define LAMBDA_STEPTEST 2
#define LAMBDA_SPSTEPTEST 3

//Display States
#define DISPLAY_SPLASH 0
#define DISPLAY_REACTOR 1
#define DISPLAY_ENGINE 2

// Datalogging variables
int lineCount = 0;

// Grate turning variables
int grateMode = GRATE_SHAKE_PRATIO; //set default starting state
int grate_motor_state; //changed to indicate state (for datalogging, etc)
int grate_val = GRATE_SHAKE_INIT; //variable that is changed and checked
int grate_pratio_accumulator = 0; // accumulate high pratio to trigger stronger shaking past threshhold
int grate_max_interval = 15*60; //longest total interval in seconds
int grate_min_interval = 60;
int grate_on_interval = 2;
//define these in setup, how much to remove from grate_val each cycle [1 second] (slope)
int m_grate_low; 
int m_grate_high;
int m_grate_on;

// Reactor pressure ratio
float pRatioReactor;
enum pRatioReactorLevels { LOWP,HIGHP } pRatioReactorLevel;
static char *pRatioReactorLevelName[] = { "Low", "High" };

// Filter pressure ratio
float pRatioFilter;
boolean pRatioFilterHigh;
int filter_pratio_accumulator;

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

//Display 
int display_state = DISPLAY_SPLASH;
unsigned long display_state_entered;

//Hertz
double hertz = 0;
volatile unsigned long hertz_last_interrupt;
volatile int hertz_period;

// Lambda variables
// Servo Valve Calibration - will vary depending on the servo valve
//PP #2 (now upgraded to #7)
//TO DO: Move to % based on open/closed instead of degrees
double premix_valve_open = 120; //calibrated angle for servo valve open
double premix_valve_closed = 0; //calibrated angle for servo valve closed (must be smaller value than open)
double premix_valve_max = 0.50;  //minimum of range for closed loop operation (percent open)
double premix_valve_min = 0.00; //maximum of range for closed loop operation (percent open)
double premix_valve_center = 0.00; //initial value when entering closed loop operation (percent open)
double lambda_setpoint;
double lambda_input;
double lambda_output;
double lambda_value;
double lambda_setpoint_mode[1] = {1.0};
double lambda_P[1] = {0.1}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
double lambda_I[1] = {0.16}; //Make I_Param about the same as your manual response time (in Seconds)/4 
double lambda_D[1] = {0.0}; //Unless you know what it's for, don't use D
PID lambda_PID(&lambda_input, &lambda_output, &lambda_setpoint,lambda_P[0],lambda_I[0],lambda_D[0]);
unsigned long lamba_updated_time;
boolean write_lambda = false;
String lambda_state_name;
int lambda_state;
unsigned long lambda_state_entered;

//Governor
  //throttle open - 83°
  //closed - 0°
double throttle_valve_open = 83; //calibrated angle for servo valve open
double throttle_valve_closed = 0; //calibrated angle for servo valve closed (must be smaller value than open)
//double throttle_valve_max = 1.00;  //minimum of range for closed loop operation (percent open)
//double throttle_valve_min = 0.00; //maximum of range for closed loop operation (percent open)
double governor_setpoint;
double governor_input;
double governor_output;
double governor_value;
double governor_P[1] = {2}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
double governor_I[1] = {.2}; //Make I_Param about the same as your manual response time (in Seconds)/4 
double governor_D[1] = {0.0}; //Unless you know what it's for, don't use D
PID governor_PID(&governor_input, &governor_output, &governor_setpoint,governor_P[0],governor_I[0],governor_D[0]);

// Pressure variables
int Press_Calib[6];
int Press[6]; //values corrected for sensor offset (calibration)

// Flow variables
float CfA0_air_rct =0.42123;
float CfA0_air_eng = 0.6555;
float CfA0_gas_eng = 0.81046;
double air_eng_flow;
double air_rct_flow;
double gas_eng_flow;
boolean flow_active; // are any flowmeters hooked up?

//Servo 
int servo_alt = 0; //used to pulse every other time through loop (~20 ms)

//Servo0
float servo0_pos = 0;
float servo0_db = 0; // used to deadband the servo movement

//Servo1
float servo1_pos;
float servo1_db = 0; // used to deadband the servo movement

//Servo2
float servo2_pos;
float servo2_db = 0; // used to deadband the servo movement

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

//Serial
char serial_last_input = '\0'; // \0 is the NULL character

// Alarm
boolean auger_on =false;
int auger_on_length = 0;
int auger_off_length = 0;
unsigned int auger_on_alarm_point = 300;
unsigned int auger_off_alarm_point = 900;
boolean alarm;
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
  
  InitGrate();
  InitPeriodHertz(); //attach interrupt
  InitGovernor();
  
  Serial.print("#");
  Serial.println(m_grate_low);
  TransitionEngine(ENGINE_ON); //default to engine on. if PCU resets, don't shut a running engine off. in the ENGINE_ON state, should detect and transition out of engine on.
  TransitionLambda(LAMBDA_CLOSEDLOOP);
  TransitionDisplay(DISPLAY_SPLASH);
  
}

void loop() {
  int key;
  if (millis() >= nextTime3) {
    nextTime3 += loopPeriod3;
    // first, read all KS's sensors
    Temp_ReadAll();  // reads into array Temp_Data[], in deg C
    Press_ReadAll(); // reads into array Press_Data[], in hPa
    Timer_ReadAll(); // reads pulse timer into Timer_Data, in RPM ??? XXX
    DoDisplay();
    DoPressure();
    DoFlow();
    DoSerialIn();
    DoLambda();
    DoGovernor();
    DoControlInputs();
    DoEngine();
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
    //UI_DoScr();       // output the display screen data, 
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

