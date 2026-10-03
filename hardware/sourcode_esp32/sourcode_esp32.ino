#define BLYNK_TEMPLATE_ID "BLYNK_TEMPLATE_ID"
#define BLYNK_TEMPLATE_NAME "BLYNK_TEMPLATE_NAME"
#define BLYNK_AUTH_TOKEN "BLYNK_AUTH_TOKEN"
#define BLYNK_PRINT Serial

#include <WiFi.h>
#include <WiFiClient.h>
#include <BlynkSimpleEsp32.h>

// Firebase
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h" // included with Firebase_ESP_Client
#include "time.h"   // NTP Time

// ---------- WiFi ----------
char ssid[] = "";
char pass[] = "";

// ---------- FIREBASE CONFIG - FILL THESE ----------
const String API_KEY       = "API_KEY";
const String DATABASE_URL  = "DATABASE_URL";
const String USER_EMAIL    = "USER_EMAIL";
const String USER_PASSWORD = "USER_PASSWORD";

// Device metadata
const char* DEVICE_ID = "DEVICE_ID";
const char* FIRMWARE_VERSION = "FIRMWARE_VERSION";

// Nama device/path di database
const String DEVICE_NAME   = "Smart_room_iot";
const String DATABASE_PATH = "/devices/" + DEVICE_NAME;

// ---------- PINS & VPINS ----------
#define LED_PIN_R1 26
#define BUTTON_PIN_R1 14
#define PIR_PIN_R1 34
#define VPIN_MODE_R1 V2
#define VPIN_STATUS_R1 V3

#define LED_PIN_R2 27
#define BUTTON_PIN_R2 12
#define PIR_PIN_R2 35
#define VPIN_MODE_R2 V4
#define VPIN_STATUS_R2 V5

#define LED_PIN_R3 22
#define BUTTON_PIN_R3 13
#define PIR_PIN_R3 32
#define VPIN_MODE_R3 V6
#define VPIN_STATUS_R3 V7

#define LED_PIN_SL 21
#define BUTTON_PIN_SL 19
#define VPIN_STREET_MODE V8
#define VPIN_STREET_STATUS V9

// Structures
struct Room {
  byte ledPin;
  byte buttonPin;
  byte pirPin;
  int vpinMode;
  int vpinStatus;
  byte ledState;
  byte lastButtonState;
  int currentMode;
  bool isOccupied;
  bool adminForced;
  unsigned long lastTimeButtonStateChanged;
  unsigned long lastMotionTime;
  int pwmTarget;
  int pwmCurrent;
  String name;
};

struct StreetLight {
  byte ledPin;
  byte buttonPin;
  int vpinMode;
  int vpinStatus;
  byte ledState;
  byte lastButtonState;
  int currentMode;
  bool adminForced;
  unsigned long lastTimeButtonStateChanged;
  int pwmTarget;
  int pwmCurrent;
  String name;
};

// Constants
#define DEBOUNCE_DURATION 300
#define PIR_STAY_ON_MS 5000

// PWM
const int PWM_FREQ = 5000;
const int PWM_RES = 8;
const int PWM_BRIGHTNESS = 200;
int pwmChannel[4] = {0,1,2,3};
const int PWM_STEP = 8;
const unsigned long PWM_STEP_MS = 20;

// Instances
Room rooms[3];
StreetLight sl;

// Firebase globals
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
bool firebaseReady = false;

// Timing for polling controls
unsigned long lastControlsPoll = 0;
const unsigned long CONTROLS_POLL_MS = 2000; // every 2 seconds

// ===============================================================
// TIME helpers (same as before)
String getFormattedTime() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return "Unknown";
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%Y-%m-%d_%H-%M-%S", &timeinfo);
  return String(buffer);
}
long getEpochTime() {
  time_t now;
  time(&now);
  return (long)now;
}
void setupTime() {
  configTime(25200, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("Syncing time...");
  delay(1500);
  Serial.println(" done!");
}

// ===============================================================
// WiFi & Firebase setup (slightly adapted)
void setupWiFi() {
  Serial.print("Connecting to WiFi");
  WiFi.begin(ssid, pass);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ WiFi Connected!");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n❌ WiFi Connection Failed!");
  }
}

void setupFirebase() {
  Serial.println("Setting up Firebase...");
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;
  Firebase.reconnectWiFi(true);
  fbdo.setResponseSize(8192);
  Firebase.begin(&config, &auth);
  int attempts = 0;
  while (!Firebase.ready() && attempts < 15) {
    delay(1000);
    Serial.print(".");
    attempts++;
  }
  firebaseReady = Firebase.ready();
  if (firebaseReady) Serial.println("\n✅ Firebase Ready!");
  else Serial.println("\n❌ Firebase Connection Failed!");
}

// ===============================================================
void pushRoomEventToFirebase(Room &room, const String &eventDesc, const String &source) {
  if (!firebaseReady) return;
  String timestampStr = getFormattedTime();
  long epoch = getEpochTime();
  if (timestampStr == "Unknown" || epoch <= 0) return;
  String path = DATABASE_PATH + "/history/" + timestampStr;
  FirebaseJson json;
  json.set("type", "room_event");
  json.set("room", room.name);
  json.set("event", eventDesc);
  json.set("source", source);
  json.set("ledState", room.ledState == HIGH ? "ON" : "OFF");
  json.set("isOccupied", room.isOccupied);
  json.set("adminForced", room.adminForced);
  json.set("updatedAt", timestampStr);
  json.set("timestampEpoch", epoch);
  json.set("deviceId", DEVICE_ID);
  json.set("firmware", FIRMWARE_VERSION);
  Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json);
}

void pushRoomCurrentToFirebase(Room &room) {
  if (!firebaseReady) return;
  String timestampStr = getFormattedTime();
  long epoch = getEpochTime();
  if (timestampStr == "Unknown" || epoch <= 0) return;
  FirebaseJson json;
  String ledStatus = room.ledState == HIGH ? "ON" : "OFF";
  json.set("name", room.name);
  json.set("ledState", ledStatus);
  json.set("currentMode", room.currentMode);
  json.set("isOccupied", room.isOccupied);
  json.set("adminForced", room.adminForced);
  json.set("pwmTarget", room.pwmTarget);
  json.set("pwmCurrent", room.pwmCurrent);
  json.set("updatedAt", timestampStr);
  json.set("timestampEpoch", epoch);
  json.set("deviceId", DEVICE_ID);
  json.set("firmware", FIRMWARE_VERSION);
  String path = DATABASE_PATH + "/current_status/rooms/" + room.name;
  Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json);
}

void pushStreetEventToFirebase(StreetLight &s, const String &eventDesc, const String &source) {
  if (!firebaseReady) return;
  String timestampStr = getFormattedTime();
  long epoch = getEpochTime();
  if (timestampStr == "Unknown" || epoch <= 0) return;
  String path = DATABASE_PATH + "/streetlight/history/" + timestampStr;
  FirebaseJson json;
  json.set("type", "street_event");
  json.set("name", s.name);
  json.set("event", eventDesc);
  json.set("source", source);
  json.set("ledState", s.ledState == HIGH ? "ON" : "OFF");
  json.set("adminForced", s.adminForced);
  json.set("currentMode", s.currentMode);
  json.set("updatedAt", timestampStr);
  json.set("timestampEpoch", epoch);
  json.set("deviceId", DEVICE_ID);
  json.set("firmware", FIRMWARE_VERSION);
  Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json);
}

void pushStreetCurrentToFirebase(StreetLight &s) {
  if (!firebaseReady) return;
  String timestampStr = getFormattedTime();
  long epoch = getEpochTime();
  if (timestampStr == "Unknown" || epoch <= 0) return;
  FirebaseJson json;
  String ledStatus = s.ledState == HIGH ? "ON" : "OFF";
  json.set("name", s.name);
  json.set("ledState", ledStatus);
  json.set("currentMode", s.currentMode);
  json.set("adminForced", s.adminForced);
  json.set("pwmTarget", s.pwmTarget);
  json.set("pwmCurrent", s.pwmCurrent);
  json.set("updatedAt", timestampStr);
  json.set("timestampEpoch", epoch);
  json.set("deviceId", DEVICE_ID);
  json.set("firmware", FIRMWARE_VERSION);
  String path = DATABASE_PATH + "/streetlight/current_status";
  Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json);
}

// ===============================================================
// OUTPUT CONTROL
void setOutput(Room &room, byte state) {
  room.ledState = state;
  room.pwmTarget = (state == HIGH) ? PWM_BRIGHTNESS : 0;
  Serial.print("["); Serial.print(room.name); Serial.print("] OUTPUT: ");
  Serial.println(state == HIGH ? "ON" : "OFF");
  pushRoomEventToFirebase(room, String("Output ") + (state == HIGH ? "ON" : "OFF"), "system");
  pushRoomCurrentToFirebase(room);
  Blynk.virtualWrite(room.vpinStatus, room.isOccupied ? 1 : 0);
  Blynk.virtualWrite(room.vpinMode, room.currentMode);
}

void setOutputStreet(StreetLight &s, byte state) {
  s.ledState = state;
  s.pwmTarget = (state == HIGH) ? PWM_BRIGHTNESS : 0;
  Serial.print("["); Serial.print(s.name); Serial.print("] OUTPUT: ");
  Serial.println(state == HIGH ? "ON" : "OFF");
  pushStreetEventToFirebase(s, String("Output ") + (state == HIGH ? "ON" : "OFF"), "system");
  pushStreetCurrentToFirebase(s);
  Blynk.virtualWrite(s.vpinStatus, s.ledState == HIGH ? 1 : 0);
}

// ===============================================================
// pwmFadeStep
void pwmFadeStep() {
  static unsigned long lastPwmStepTime = 0;
  unsigned long now = millis();
  if (now - lastPwmStepTime < PWM_STEP_MS) return;
  lastPwmStepTime = now;
  for (int i = 0; i < 3; i++) {
    int cur = rooms[i].pwmCurrent;
    int tgt = rooms[i].pwmTarget;
    if (cur == tgt) continue;
    if (cur < tgt) cur = min(cur + PWM_STEP, tgt);
    else cur = max(cur - PWM_STEP, tgt);
    rooms[i].pwmCurrent = cur;
    ledcWrite(pwmChannel[i], cur);
  }
  int curS = sl.pwmCurrent;
  int tgtS = sl.pwmTarget;
  if (curS != tgtS) {
    if (curS < tgtS) curS = min(curS + PWM_STEP, tgtS);
    else curS = max(curS - PWM_STEP, tgtS);
    sl.pwmCurrent = curS;
    ledcWrite(pwmChannel[3], curS);
  }
}

// ===============================================================
// Occupancy update
void updateOccupancyFromPIR(Room &room) {
  unsigned long now = millis();
  bool prevOccupied = room.isOccupied;
  int pirVal = digitalRead(room.pirPin);
  if (pirVal == HIGH) {
    room.isOccupied = true;
    room.lastMotionTime = now;
  } else {
    if (now - room.lastMotionTime >= PIR_STAY_ON_MS) {
      room.isOccupied = false;
    }
  }
  if (room.isOccupied != prevOccupied) {
    Blynk.virtualWrite(room.vpinStatus, room.isOccupied ? 1 : 0);
    pushRoomEventToFirebase(room, room.isOccupied ? "PIR: Motion detected" : "PIR: Motion timeout", "PIR");
    pushRoomCurrentToFirebase(room);
  }
}

// ===============================================================
// Mode handling & button handling
void handleAuto(Room &room) {
  if (room.currentMode != 0) return;
  if (room.adminForced) return;
  if (room.isOccupied && room.ledState == LOW) {
    setOutput(room, HIGH);
    pushRoomEventToFirebase(room, "Auto: turn ON (motion)", "system");
  } else if (!room.isOccupied && room.ledState == HIGH) {
    setOutput(room, LOW);
    pushRoomEventToFirebase(room, "Auto: turn OFF (no motion)", "system");
  }
}

void handleManualButton(Room &room) {
  if (room.currentMode != 1) return;
  byte buttonState = digitalRead(room.buttonPin);
  if (millis() - room.lastTimeButtonStateChanged >= DEBOUNCE_DURATION) {
    if (buttonState != room.lastButtonState) {
      if (buttonState == LOW) {
        bool newState = (room.ledState == LOW);
        setOutput(room, newState ? HIGH : LOW);
        room.isOccupied = newState;
        Blynk.virtualWrite(room.vpinStatus, room.isOccupied ? 1 : 0);
        Serial.print("["); Serial.print(room.name); Serial.println("] Button Toggle executed.");
        Blynk.virtualWrite(room.vpinMode, room.currentMode);
        pushRoomEventToFirebase(room, "Button toggle (manual)", "button");
        pushRoomCurrentToFirebase(room);
      }
      room.lastTimeButtonStateChanged = millis();
      room.lastButtonState = buttonState;
    }
  }
}

void handleModeChange(Room &room, int newMode) {
  room.currentMode = newMode;
  Serial.print("["); Serial.print(room.name); Serial.print("] Mode: "); Serial.println(newMode);
  if (newMode == 2) {
    room.adminForced = true;
    setOutput(room, HIGH);
    pushRoomEventToFirebase(room, "Mode Force ON (admin)", "admin");
  } else if (newMode == 3) {
    room.adminForced = true;
    setOutput(room, LOW);
    pushRoomEventToFirebase(room, "Mode Force OFF (admin)", "admin");
  } else {
    room.adminForced = false;
    setOutput(room, LOW);
    if (newMode == 0) pushRoomEventToFirebase(room, "Mode Auto set", "blynk");
    if (newMode == 1) pushRoomEventToFirebase(room, "Mode Manual set", "blynk");
  }
  Blynk.virtualWrite(room.vpinMode, room.currentMode);
  pushRoomCurrentToFirebase(room);
}

// Blynk handlers (same mapping)
BLYNK_WRITE(V2) { handleModeChange(rooms[0], param.asInt()); }
BLYNK_WRITE(V4) { handleModeChange(rooms[1], param.asInt()); }
BLYNK_WRITE(V6) { handleModeChange(rooms[2], param.asInt()); }

// Streetlight handlers (same as before)
void handleStreetManualButton(StreetLight &s) {
  if (s.currentMode != 1) return;
  byte buttonState = digitalRead(s.buttonPin);
  if (millis() - s.lastTimeButtonStateChanged >= DEBOUNCE_DURATION) {
    if (buttonState != s.lastButtonState) {
      if (buttonState == LOW) {
        bool newState = (s.ledState == LOW);
        setOutputStreet(s, newState ? HIGH : LOW);
        Serial.print("["); Serial.print(s.name); Serial.println("] Street manual button toggled.");
        pushStreetEventToFirebase(s, "Button toggle (manual)", "button");
        pushStreetCurrentToFirebase(s);
        Blynk.virtualWrite(s.vpinStatus, s.ledState == HIGH ? 1 : 0);
      }
      s.lastTimeButtonStateChanged = millis();
      s.lastButtonState = buttonState;
    }
  }
}

void handleStreetModeChange(StreetLight &s, int newMode) {
  s.currentMode = newMode;
  Serial.print("[Streetlight] Mode set: "); Serial.println(newMode);
  if (newMode == 2) {
    s.adminForced = true;
    setOutputStreet(s, HIGH);
    pushStreetEventToFirebase(s, "Mode Force ON (admin)", "admin");
  } else if (newMode == 3) {
    s.adminForced = true;
    setOutputStreet(s, LOW);
    pushStreetEventToFirebase(s, "Mode Force OFF (admin)", "admin");
  } else if (newMode == 1) {
    s.adminForced = false;
    pushStreetEventToFirebase(s, "Mode Manual set", "blynk");
  }
  Blynk.virtualWrite(s.vpinMode, s.currentMode);
  pushStreetCurrentToFirebase(s);
}
BLYNK_WRITE(VPIN_STREET_MODE) { handleStreetModeChange(sl, param.asInt()); }

// ===============================================================
// CONTROLS POLLING
void applyRoomControlIfAny(Room &room) {
  if (!firebaseReady) return;
  String base = DATABASE_PATH + "/controls/rooms/" + room.name;
  String pathMode = base + "/requestedMode";
  String pathOut  = base + "/requestedOutput";
  String pathAckTime = base + "/lastAppliedAt";

  // 1) requestedMode (int)
  if (Firebase.RTDB.getInt(&fbdo, pathMode.c_str())) {
    if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_integer) {
      int reqMode = fbdo.intData();
      // Apply only if different or if adminForced state needs update
      if (reqMode != room.currentMode) {
        Serial.printf("[CTRL] Apply requestedMode %d for %s\n", reqMode, room.name.c_str());
        handleModeChange(room, reqMode);
        // ack: write lastAppliedAt
        long epoch = getEpochTime();
        Firebase.RTDB.setInt(&fbdo, pathAckTime.c_str(), epoch);
        // optionally delete the requestedMode node so it won't reapply
        Firebase.RTDB.deleteNode(&fbdo, pathMode.c_str());
      }
    }
  }

  // 2) requestedOutput (string)
  if (Firebase.RTDB.getString(&fbdo, pathOut.c_str())) {
    if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_string) {
      String reqOut = fbdo.stringData();
      reqOut.toUpperCase();
      if (reqOut == "ON" && room.ledState == LOW) {
        setOutput(room, HIGH);
        Firebase.RTDB.setInt(&fbdo, pathAckTime.c_str(), getEpochTime());
        Firebase.RTDB.deleteNode(&fbdo, pathOut.c_str());
      } else if (reqOut == "OFF" && room.ledState == HIGH) {
        setOutput(room, LOW);
        Firebase.RTDB.setInt(&fbdo, pathAckTime.c_str(), getEpochTime());
        Firebase.RTDB.deleteNode(&fbdo, pathOut.c_str());
      } else {
        // nothing to do, remove stale command
        Firebase.RTDB.deleteNode(&fbdo, pathOut.c_str());
      }
    }
  }
}

void applyStreetControlIfAny(StreetLight &s) {
  if (!firebaseReady) return;
  String base = DATABASE_PATH + "/controls/streetlight";
  String pathMode = base + "/requestedMode";
  String pathOut  = base + "/requestedOutput";
  String pathAckTime = base + "/lastAppliedAt";

  if (Firebase.RTDB.getInt(&fbdo, pathMode.c_str())) {
    if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_integer) {
      int reqMode = fbdo.intData();
      if (reqMode != s.currentMode) {
        Serial.printf("[CTRL] Apply requestedMode %d for Streetlight\n", reqMode);
        handleStreetModeChange(s, reqMode);
        Firebase.RTDB.setInt(&fbdo, pathAckTime.c_str(), getEpochTime());
        Firebase.RTDB.deleteNode(&fbdo, pathMode.c_str());
      }
    }
  }

  if (Firebase.RTDB.getString(&fbdo, pathOut.c_str())) {
    if (fbdo.dataTypeEnum() == fb_esp_rtdb_data_type_string) {
      String reqOut = fbdo.stringData();
      reqOut.toUpperCase();
      if (reqOut == "ON" && s.ledState == LOW) {
        setOutputStreet(s, HIGH);
        Firebase.RTDB.setInt(&fbdo, pathAckTime.c_str(), getEpochTime());
        Firebase.RTDB.deleteNode(&fbdo, pathOut.c_str());
      } else if (reqOut == "OFF" && s.ledState == HIGH) {
        setOutputStreet(s, LOW);
        Firebase.RTDB.setInt(&fbdo, pathAckTime.c_str(), getEpochTime());
        Firebase.RTDB.deleteNode(&fbdo, pathOut.c_str());
      } else {
        Firebase.RTDB.deleteNode(&fbdo, pathOut.c_str());
      }
    }
  }
}

void pollControls() {
  if (!firebaseReady) return;
  unsigned long now = millis();
  if (now - lastControlsPoll < CONTROLS_POLL_MS) return;
  lastControlsPoll = now;
  for (int i = 0; i < 3; i++) applyRoomControlIfAny(rooms[i]);
  applyStreetControlIfAny(sl);
}

// ===============================================================
// SETUP & LOOP
void setup() {
  Serial.begin(115200);

  rooms[0] = {LED_PIN_R1, BUTTON_PIN_R1, PIR_PIN_R1, V2, VPIN_STATUS_R1, LOW, HIGH, 0, false, false, 0UL, 0UL, 0, 0, "R1"};
  rooms[1] = {LED_PIN_R2, BUTTON_PIN_R2, PIR_PIN_R2, V4, VPIN_STATUS_R2, LOW, HIGH, 0, false, false, 0UL, 0UL, 0, 0, "R2"};
  rooms[2] = {LED_PIN_R3, BUTTON_PIN_R3, PIR_PIN_R3, V6, VPIN_STATUS_R3, LOW, HIGH, 0, false, false, 0UL, 0UL, 0, 0, "R3"};
  sl = {LED_PIN_SL, BUTTON_PIN_SL, VPIN_STREET_MODE, VPIN_STREET_STATUS, LOW, HIGH, 1, false, 0UL, 0, 0, "Streetlight"};

  for (int i = 0; i < 3; i++) {
    pinMode(rooms[i].ledPin, OUTPUT);
    pinMode(rooms[i].buttonPin, INPUT_PULLUP);
    pinMode(rooms[i].pirPin, INPUT);
    ledcSetup(pwmChannel[i], PWM_FREQ, PWM_RES);
    ledcAttachPin(rooms[i].ledPin, pwmChannel[i]);
    ledcWrite(pwmChannel[i], 0);
  }
  pinMode(sl.ledPin, OUTPUT);
  pinMode(sl.buttonPin, INPUT_PULLUP);
  ledcSetup(pwmChannel[3], PWM_FREQ, PWM_RES);
  ledcAttachPin(sl.ledPin, pwmChannel[3]);
  ledcWrite(pwmChannel[3], 0);

  setupWiFi();
  setupTime();
  Blynk.config(BLYNK_AUTH_TOKEN);
  Blynk.connect(5000);
  setupFirebase();

  Serial.println("[SETUP] SmartRoomHybrid - FINAL V2 (with Controls Polling) Ready.");
}

void loop() {
  Blynk.run();

  for (int i = 0; i < 3; i++) {
    updateOccupancyFromPIR(rooms[i]);
    if (rooms[i].currentMode == 2 || rooms[i].currentMode == 3) {
      // forced - skip local auto/manual
    } else if (rooms[i].currentMode == 0) {
      handleAuto(rooms[i]);
    } else if (rooms[i].currentMode == 1) {
      handleManualButton(rooms[i]);
    }
  }

  handleStreetManualButton(sl);
  pwmFadeStep();

  // Poll controls and apply if any
  pollControls();

  // Periodic full status push (every 30s)
  static unsigned long lastPushAll = 0;
  if (firebaseReady && millis() - lastPushAll > 30000) {
    lastPushAll = millis();
    for (int i = 0; i < 3; i++) pushRoomCurrentToFirebase(rooms[i]);
    pushStreetCurrentToFirebase(sl);
  }
}