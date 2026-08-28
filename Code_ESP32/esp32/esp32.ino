#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define BUZZER_PIN 18
#define RELAY_PIN 19    // Broche pour le relais (Active Low)
#define PIR_PIN 27
#define SOUND_PIN 26
#define LDR_PIN 32

#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

String currentMode = "MODE_NONE";

// Variables globales pour le mode sonore
unsigned long lastSoundTime = 0;
int clapCount = 0;
bool soundRelayState = false; // false signifiera éteint (donc HIGH sur la broche)
unsigned long soundModeStartTime = 0;

void beepTwice() {
    for(int i = 0; i < 2; i++) {
        digitalWrite(BUZZER_PIN, HIGH);
        delay(100);
        digitalWrite(BUZZER_PIN, LOW);
        delay(100);
    }
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Smartphone connecté !");
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      currentMode = "MODE_NONE"; 
      digitalWrite(RELAY_PIN, HIGH); // ÉTEINT le relais (Active Low)
      Serial.println("Smartphone déconnecté.");
      BLEDevice::startAdvertising();
    }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();
      if (rxValue.length() > 0) {
        Serial.print("Commande reçue : ");
        Serial.println(rxValue);
        
        bool isMode = (rxValue == "MODE_MANUAL" || rxValue == "MODE_MOTION" ||
                       rxValue == "MODE_SOUND" || rxValue == "MODE_LIGHT" || rxValue == "MODE_NONE");
        if (isMode) beepTwice();

        // Lors d'un changement de mode, on éteint la lampe par défaut (HIGH pour Active Low)
        if (rxValue == "MODE_MANUAL") {
          currentMode = "MODE_MANUAL";
          digitalWrite(RELAY_PIN, HIGH); 
        } 
        else if (rxValue == "MODE_MOTION") {
          currentMode = "MODE_MOTION";
          digitalWrite(RELAY_PIN, HIGH);
        }
        else if (rxValue == "MODE_SOUND") { 
          currentMode = "MODE_SOUND";
          digitalWrite(RELAY_PIN, HIGH);
          lastSoundTime = 0;
          clapCount = 0;
          soundRelayState = false;
          soundModeStartTime = millis(); 
        }
        else if (rxValue == "MODE_LIGHT") { 
          currentMode = "MODE_LIGHT";
          digitalWrite(RELAY_PIN, HIGH);
        }
        else if (rxValue == "MODE_NONE") {
          currentMode = "MODE_NONE";
          digitalWrite(RELAY_PIN, HIGH);
        }
        
        // Mode Manuel : LOW pour allumer, HIGH pour éteindre
        else if (rxValue == "MANUAL_ON" && currentMode == "MODE_MANUAL") {
          digitalWrite(RELAY_PIN, LOW);
        } 
        else if (rxValue == "MANUAL_OFF" && currentMode == "MODE_MANUAL") {
          digitalWrite(RELAY_PIN, HIGH);
        }
      }
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(BUZZER_PIN, OUTPUT);
    
    // CORRECTION ICI : On déclare d'abord en OUTPUT, puis on met sur HIGH direct
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, HIGH); // Éteint le relais immédiatement
    
    pinMode(PIR_PIN, INPUT); 
    pinMode(SOUND_PIN, INPUT); 
    pinMode(LDR_PIN, INPUT); 
    
    BLEDevice::init("MWINDA_ESP32");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_WRITE |
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
    pCharacteristic->setCallbacks(new MyCallbacks());
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();
}

void loop() {
    unsigned long currentMillis = millis();

    // 1. MODE MOUVEMENT
    if (currentMode == "MODE_MOTION") {
        static unsigned long lastMotionTime = 0;
        static bool wasOn = false;

        if (digitalRead(PIR_PIN) == HIGH) {
            if (!wasOn) {
                beepTwice();
                wasOn = true;
            }
            lastMotionTime = currentMillis;
            digitalWrite(RELAY_PIN, LOW); // LOW pour allumer
        } else if (currentMillis - lastMotionTime > 5000) {
            digitalWrite(RELAY_PIN, HIGH); // HIGH pour éteindre
            wasOn = false;
        }
        delay(200);
    }
    
    // 2. MODE SONORE
    else if (currentMode == "MODE_SOUND") {
        if (currentMillis - soundModeStartTime < 1500) {
            delay(50);
        } else {
            int soundDetected = digitalRead(SOUND_PIN);
            if (soundDetected == HIGH) {
                if (currentMillis - lastSoundTime > 200) {
                    if (currentMillis - lastSoundTime > 1000) {
                        clapCount = 1;
                    } else {
                        clapCount++;
                    }
                    lastSoundTime = currentMillis;

                    if (clapCount >= 2) {
                        soundRelayState = !soundRelayState;
                        // Si l'état est vrai (allumé), on envoie LOW. Sinon on envoie HIGH.
                        digitalWrite(RELAY_PIN, soundRelayState ? LOW : HIGH);
                        clapCount = 0;
                    }
                }
            }
            delay(10);
        }
    }

    // 3. MODE LUMIÈRE (LDR)
    else if (currentMode == "MODE_LIGHT") {
        int ldrValue = analogRead(LDR_PIN);
        
        if (ldrValue > 3100) { 
            digitalWrite(RELAY_PIN, LOW); // Fait nuit : on allume (LOW)
        } else if (ldrValue < 2900) { 
            digitalWrite(RELAY_PIN, HIGH); // Fait jour : on éteint (HIGH)
        }
        
        delay(500);
    }
}
