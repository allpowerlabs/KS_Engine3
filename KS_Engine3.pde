// KS_Engine3
// Library used to run APL Power Pallet
// Developed for the APL GCU/PCU: http://gekgasifier.pbworks.com/Gasifier-Control-Unit

#include <EEPROM.h>         // included with Arduino, can read/writes to non-volatile memory
#include <Servo.h>          // Arduino's native servo library
#include <PID_Beta6.h>      // http://www.arduino.cc/playground/Code/PIDLibrary, http://en.wikipedia.org/wiki/PID_controller
#include <adc.h>            // part of KSlibs, for reading analog inputs
#include <display.h>        // part of KSlibs, write to display
#include <fet.h>            // part of KSlibs, control FETs (field effect transitor) to drive motors, solenoids, etc
#include <keypad.h>         // part of KSlibs, read buttons and keypad
#include <pressure.h>       // part of KSlibs, read pressure sensors
#include <servos.h>         // part of KSlibs, not implemented
#include <temp.h>           // part of KSlibs, read thermocouples
#include <timer.h>          // part of KSlibs, not implemented
#include <ui.h>             // part of KSlibs, menu
#include <util.h>           // part of KSlibs, utility functions, GCU_Setup
#include <avr/io.h>         // advanced: provides port definitions for the microcontroller (ATmega1280, http://www.atmel.com/dyn/resources/prod_documents/doc2549.PDF)   
//#include <SdFat.h>
//#include <SdFatUtil.h> 
//#include <ctype.h>

//constant definitions
#define ABSENT -500

#define CODE_VERSION "v1.00"

// Analog Input Mapping
#define ANA_LAMBDA ANA0
#define ANA_FUEL_SWITCH ANA1
#define ANA_ENGINE_SWITCH ANA2
#define ANA_BLOWER_DIAL ABSENT
#define ANA_AUGER_CURRENT ABSENT  //sense current in auger motor
#define ANA_BATT_V ABSENT
#define ANA_OIL_PRESSURE ANA3

// FET Mapping
#define FET_AUGER FET0
#define FET_GRATE FET1
#define FET_IGNITION FET2
#define FET_STARTER FET3
#define FET_FLARE_IGNITOR FET4
#define FET_O2_RESET FET5
#define FET_ALARM FET6
#define FET_BLOWER ABSENT

//Servo Mapping
//TODO: Use these define
#define SERVO_MIXTURE SERVO0
#define SERVO_CALIB SERVO1
#define SERVO_THROTTLE SERVO2

Servo Servo_Mixture;
Servo Servo_Calib;
Servo Servo_Throttle;

//Thermocouple Mappings
#define T_BRED 1
#define T_TRED 0
#define T_PYRO_IN ABSENT
#define T_PYRO_OUT ABSENT
#define T_COMB ABSENT
#define T_REACTOR_GAS_OUT 3
#define T_DRYING_GAS_OUT ABSENT
#define T_FILTER ABSENT
#define T_ENG_COOLANT 2
#define T_LOW_FUEL ABSENT

//Pressure Mapping
#define P_REACTOR 0
#define P_COMB 2
#define P_FILTER 1
#define P_Q_AIR_ENG ABSENT
#define P_Q_AIR_RCT 4
#define P_Q_GAS_ENG 5

//Interrupt Mapping
// 2 - pin 21 - PD0
// 3 - pin 20 - PD1
// 4 - pin 19 - PD2
// 5 - pin 18 - PD3
#define INT_HERTZ 5 //interrupt number (not pin number)
#define INT_ENERGY_PULSE 4

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
//TODO: Use these for auto-start/shutdown sequence (e.g. equivalent to a backup generator command)
#define CONTROL_OFF 0
#define CONTROL_START 1
#define CONTROL_ON 2

//Engine States
#define ENGINE_OFF 0
#define ENGINE_ON 1
#define ENGINE_STARTING 2
#define ENGINE_GOV_TUNING 3

//Lambda
#define LAMBDA_SIGNAL_CHECK TRUE

//Flare States
#define FLARE_OFF 0
#define FLARE_USER_SET 1
#define FLARE_LOW 2
#define FLARE_HIGH 3
#define FLARE_MAX 4

//Lambda States
#define LAMBDA_CLOSEDLOOP 0
#define LAMBDA_SEALED 1
#define LAMBDA_STEPTEST 2
#define LAMBDA_SPSTEPTEST 3

//Display States
#define DISPLAY_SPLASH 0
#define DISPLAY_REACTOR 1
#define DISPLAY_ENGINE 2
#define DISPLAY_TEST 3
#define DISPLAY_LAMBDA 4
#define DISPLAY_GRATE 5
#define DISPLAY_TESTING 6

//Testing States
#define TESTING_OFF 0
#define TESTING_FUEL_AUGER 1
#define TESTING_GRATE 2
#define TESTING_ENGINE_IGNITION 3
#define TESTING_STARTER 4
#define TESTING_FLARE_IGNITOR 5
#define TESTING_O2_RESET 6
#define TESTING_ALARM 7
#define TESTING_ANA_LAMBDA 8
#define TESTING_ANA_ENGINE_SWITCH 9
#define TESTING_ANA_FUEL_SWITCH 10
#define TESTING_ANA_OIL_PRESSURE 11

//Test Variables
int testing_state = TESTING_OFF;
unsigned long testing_state_entered = 0;
static char *TestingStateName[] = { "Off","Auger","Grate","Engine","Starter","Flare","O2 Reset","Alarm","ANA_Lambda","ANA_Eng_Switch","ANA_Fuel_Switch","ANA_Oil"};
// Datalogging variables
int lineCount = 0;

// Grate turning variables
int grateMode = GRATE_SHAKE_PRATIO; //set default starting state
int grate_motor_state; //changed to indicate state (for datalogging, etc)
int grate_val = GRATE_SHAKE_INIT; //variable that is changed and checked
int grate_pratio_accumulator = 0; // accumulate high pratio to trigger stronger shaking past threshhold
int grate_max_interval = 5*60; //longest total interval in seconds
int grate_min_interval = 60;
int grate_on_interval = 3;
//define these in init, how much to remove from grate_val each cycle [1 second] (slope)
int m_grate_bad; 
int m_grate_good;
int m_grate_on;

// Reactor pressure ratio
float pRatioReactor;
enum pRatioReactorLevels { PR_HIGH = 0, PR_CORRECT = 1, PR_LOW = 2} pRatioReactorLevel;
static char *pRatioReactorLevelName[] = { "High", "Correct","Low" };
float pRatioReactorLevelBoundary[3][2] = { { 0.6, 1.0 }, { 0.3, 0.6 }, {0.0, 0.3} };

// Filter pressure ratio
float pRatioFilter;
boolean pRatioFilterHigh;
int filter_pratio_accumulator;

// Temperature Levels
#define TEMP_LEVEL_COUNT 5
enum TempLevels { COLD = 0,COOL = 1,WARM = 2 ,HOT = 3, EXCESSIVE = 4} TempLevel;
TempLevels T_tredLevel;
static char *TempLevelName[] = { "Cold", "Cool", "Warm", "Hot", "Too Hot" };
int T_tredLevelBoundary[TEMP_LEVEL_COUNT][2] = { { 0, 40 }, {50, 80}, {300,790}, {800,950}, {1000,1250} };

TempLevels T_bredLevel;
int T_bredLevelBoundary[TEMP_LEVEL_COUNT][2] = { { 0, 40 }, {50, 80}, {300,740}, {750,900}, {950,1250} };

//Pressure Levels
#define P_REACTOR_LEVEL_COUNT 4
enum P_reactorLevels { OFF = 0, LITE = 1, MEDIUM = 2 , EXTREME = 3} P_reactorLevel;
static char *P_reactorLevelName[] = { "Off", "Low", "Medium", "High"};
int P_reactorLevelBoundary[4][2] = { { -100, 0 }, {-500, -200}, {-2000,-750}, {-4000,-2000} };

//Auger Switch Levels
#if ANA_FUEL_SWITCH != ABSENT
int FuelSwitchValue = 0;
enum FuelSwitchLevels { SWITCH_OFF = 0, SWITCH_ON = 1} FuelSwitchLevel;
static char *FuelSwitchLevelName[] = { "Off","On"};
//int FuelSwitchLevelBoundary[2][2] = {{ 0, 200 }, {800, 1024}}; //not currently used
#endif

//Auger Current Levels
#if ANA_AUGER_CURRENT != ABSENT
int AugerCurrentValue = 0; // current level in mA
enum AugerCurrentLevels { AUGER_OFF = 0, AUGER_ON = 1, AUGER_HIGH = 2} AugerCurrentLevel;
static char *AugerCurrentLevelName[] = { "Off","On", "High"};
int AugerCurrentLevelBoundary[3][2] = { { 0, 1200}, {1200, 5000}, {5000,20000} };
#endif

#if ANA_OIL_PRESSURE != ABSENT
int EngineOilPressureValue;
enum EngineOilPressureLevels { OIL_P_LOW = 0, OIL_P_HIGH = 1} EngineOilPressureLevel;
int EngineOilPressureLevelBoundary[2][2] = { { 0, 500}, {600, 1024} };
#endif

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
unsigned long control_state_entered;

//Flare
int flare_state = FLARE_USER_SET;
boolean ignitor_on;
int blower_dial = 0;
double blower_setpoint;
double blower_input;
double blower_output;
double blower_value;
double blower_P[1] = {2}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
double blower_I[1] = {.2}; //Make I_Param about the same as your manual response time (in Seconds)/4 
double blower_D[1] = {0.0}; //Unless you know what it's for, don't use D
PID blower_PID(&blower_input, &blower_output, &blower_setpoint,blower_P[0],blower_I[0],blower_D[0]);

//Engine
int engine_state = ENGINE_OFF;
unsigned long engine_state_entered;
unsigned long engine_end_cranking;
int engine_crank_period = 10000; //length of time to crank engine before stopping (milliseconds)
double battery_voltage;

//Display 
int display_state = DISPLAY_SPLASH;
unsigned long display_state_entered;
unsigned long transition_entered;
String transition_message;
int item_count,cur_item;

//Keypad
int key = -1;

//Hertz
double hertz = 0;
volatile unsigned long hertz_last_interrupt;
volatile int hertz_period;

//Counter Hertz
int counter_hertz = 0;

//Energy Pulse
double power = 0;
volatile int energy_pulse_count;
volatile unsigned long energy_last_interrupt;
volatile int energy_period;

// Lambda variables
// Servo Valve Calibration - will vary depending on the servo valve
//PP #2 (now upgraded to #7)
//TO DO: Move to % based on open/closed instead of degrees
//double premix_valve_open = 180; //calibrated angle for servo valve open
//double premix_valve_closed = 105; //calibrated angle for servo valve closed (must be smaller value than open)
//New batch of throttle bodies from Jewen

//double premix_valve_open = 153; //calibrated angle for servo valve open
//double premix_valve_closed = 53; //calibrated angle for servo valve closed (must be smaller value than open)
//PP20 Jewen Throttle - apparent variation in throttle angle to servo angle in this batch, need to add calibration/storage in EEPROM...
double premix_valve_open = 133; 
double premix_valve_closed = 68;
//Jewen Throttle
//double premix_valve_open = 110; //calibrated angle for servo valve open
//double premix_valve_closed = 30; //calibrated angle for servo valve closed (must be smaller value than open)

double premix_valve_max = 1.0;  //minimum of range for closed loop operation (percent open)
double premix_valve_min = 0.00; //maximum of range for closed loop operation (percent open)
double premix_valve_center = 0.00; //initial value when entering closed loop operation (percent open)
double lambda_setpoint;
double lambda_input;
double lambda_output;
double lambda_value;
double lambda_setpoint_mode[1] = {1.05};
double lambda_P[1] = {0.13}; //Adjust P_Param to get more aggressive or conservative control, change sign if moving in the wrong direction
double lambda_I[1] = {1.0}; //Make I_Param about the same as your manual response time (in Seconds)/4 
double lambda_D[1] = {0.0}; //Unless you know what it's for, don't use D
PID lambda_PID(&lambda_input, &lambda_output, &lambda_setpoint,lambda_P[0],lambda_I[0],lambda_D[0]);
unsigned long lamba_updated_time;
boolean write_lambda = false;
String lambda_state_name;
int lambda_state;
unsigned long lambda_state_entered;

//Governor
//throttle open - 83¬∞
//closed - 0¬∞
double throttle_valve_open = 123; //calibrated angle for servo valve open
double throttle_valve_closed = 48; //calibrated angle for servo valve closed (must be smaller value than open)
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
float CfA0_air_rct = 0.6555;
float CfA0_air_eng = 0.6555;
float CfA0_gas_eng = 4.13698;
double air_eng_flow;
double air_rct_flow;
double gas_eng_flow;
boolean flow_active; // are any flowmeters hooked up?

//Servos
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

//Serial
char serial_last_input = '\0'; // \0 is the ABSENT character

// Alarm
boolean auger_on = false;
int auger_on_length = 0;
int auger_off_length = 0;
unsigned int auger_on_alarm_point = 300;
unsigned int auger_off_alarm_point = 900;
int alarm;
int alarm_interval = 5; // in seconds
int pressureRatioAccumulator = 0;
#define ALARM_NONE 0 //no alarm
#define ALARM_AUGER_ON_LONG 1
#define ALARM_AUGER_OFF_LONG 2
#define ALARM_BAD_REACTOR 3
#define ALARM_BAD_FILTER 4
#define ALARM_LOW_FUEL_REACTOR 5
#define ALARM_LOW_TRED 6
#define ALARM_HIGH_BRED 7
#define ALARM_BAD_OIL_PRESSURE 8
#define ALARM_O2_NO_SIG 9
char* display_alarm[] = {
  "No alarm           ",
  "Auger on too long  ",
  "Auger off too long ",
  "Bad Reactor P_ratio",
  "Bad Filter P_ratio ",
  "Reactor Fuel Low   ",
  "tred low for eng.  ",
  "bred high for eng. ",
  "Check Oil Pressure ",
  "No O2 Sensor Signal"
}; //20 char message for 4x20 display

// SD Card
//Sd2Card sd_card;
//SdVolume sd_volume;
//SdFile sd_root;
//SdFile sd_file;

char sd_file_name[] = "Test.txt";     //Create an array that contains the name of our file.
char sd_contents[256];           //This will be a data buffer for writing contents to the file.
char sd_in_char=0;
int sd_index=0;  

void setup() {
  GCU_Setup(V3,FULLFILL,P777722);
  //
  DDRJ |= 0x80;      
  PORTJ |= 0x80;
  
  //TODO: Check attached libraries, FET6 seemed to be set to non-OUTPUT mode
  //set all FET pins to output
  pinMode(FET0,OUTPUT);
  pinMode(FET1,OUTPUT);
  pinMode(FET2,OUTPUT);
  pinMode(FET3,OUTPUT);
  pinMode(FET4,OUTPUT);
  pinMode(FET5,OUTPUT);
  pinMode(FET6,OUTPUT);
  pinMode(FET7,OUTPUT);
  
  //pinMode(FET_BLOWER,OUTPUT); //TODO: Move into library (set PE0 to output)
  //digitalWrite(FET_BLOWER,HIGH);
  //delay(50);	
  
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
  //Servo_Init();
  Timer_Init();

  Disp_Reset();
  Kpd_Reset();
  UI_Reset();
  ADC_Reset();
  Temp_Reset();
  Press_Reset();
  Fet_Reset();
  //Servo_Reset();
  Timer_Reset();
  
  InitFlow();
  InitLambda();
  InitServos();
  InitGrate();  
  InitPeriodHertz(); //attach interrupt
  InitCounterHertz();
  //InitGovernor();
  InitPulseEnergyMonitoring();
//  InitSD();
  
  TransitionEngine(ENGINE_ON); //default to engine on. if PCU resets, don't shut a running engine off. in the ENGINE_ON state, should detect and transition out of engine on.
  TransitionLambda(LAMBDA_CLOSEDLOOP);
  TransitionDisplay(DISPLAY_SPLASH);
}

void loop() {
  if (millis() >= nextTime3) {
    nextTime3 += loopPeriod3;
    // first, read all KS's sensors
    Temp_ReadAll();  // reads into array Temp_Data[], in deg C
    Press_ReadAll(); // reads into array Press_Data[], in hPa
    Timer_ReadAll(); // reads pulse timer into Timer_Data, in RPM ??? XXX
    DoPressure();
    DoFlow();
    DoSerialIn();
    DoLambda();
    //DoGovernor();
    DoControlInputs();
    DoEngine();
    //DoServos();
    DoFlare();
    DoReactor();
    DoAuger();
    DoBattery();
    DoKeyInput();
    DoCounterHertz();
    DoHeartBeat(); // blink heartbeat LED
    //TODO: Add OpenEnergyMonitor Library
    if (millis() >= nextTime2) {
      nextTime2 += loopPeriod2;
      DoDisplay();
      if (millis() >= nextTime1) {
        nextTime1 += loopPeriod1;
        DoGrate();
        DoFilter();
        DoOilPressure();
        DoDatalogging();
//      DoDatalogSD();
        DoAlarmUpdate();
        if (millis() >= nextTime0) {
          nextTime0 += loopPeriod0;
          DoAlarm();
        }
      }
    }
  }
}

