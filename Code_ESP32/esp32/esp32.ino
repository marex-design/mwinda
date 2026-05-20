#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define BUZZER_PIN 18// Broche pour le buzzer
#define RELAY_PIN 19// Broche pour le relais
#define PIR_PIN 27 // Broche pour le capteur de mouvement
#define SOUND_PIN 26   // broche pour le KY-037 (D0)

#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// Variable pour stocker le mode actuel
String currentMode = "MODE_NONE";

// Variables globales pour le mode sonore (globales = réinitialisables depuis onWrite)
unsigned long lastSoundTime = 0;
int clapCount = 0;
bool soundRelayState = false;
unsigned long soundModeStartTime = 0; // Pour ignorer le bip d'activation

// Fonction pour faire biper le buzzer deux fois
void beepTwice() {
    for(int i = 0; i < 2; i++) {
        digitalWrite(BUZZER_PIN, HIGH);
        delay(100);
        digitalWrite(BUZZER_PIN, LOW);
        delay(100);
    }
}
// Callbacks pour gérer les connexions Bluetooth
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Smartphone connecté !");
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      currentMode = "MODE_NONE"; // Sécurité : on désactive tout si déconnecté
      digitalWrite(RELAY_PIN, LOW);
      Serial.println("Smartphone déconnecté.");
      BLEDevice::startAdvertising();
    }
};

// Callbacks pour gérer les écritures sur la caractéristique Bluetooth
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();
      if (rxValue.length() > 0) {
        Serial.print("Commande reçue : ");
        Serial.println(rxValue);
        
        // Bip de confirmation pour les changements de mode uniquement
        // (pas pour MANUAL_ON/OFF ni pour les claps du mode sonore)
        bool isMode = (rxValue == "MODE_MANUAL" || rxValue == "MODE_MOTION" ||
                       rxValue == "MODE_SOUND" || rxValue == "MODE_NONE");
        if (isMode) beepTwice();

        // Gestion des changements de MODE
        if (rxValue == "MODE_MANUAL") {
          currentMode = "MODE_MANUAL";
          digitalWrite(RELAY_PIN, LOW); // On éteint par défaut en entrant dans le mode
        } 
        else if (rxValue == "MODE_MOTION") {
          currentMode = "MODE_MOTION";
          digitalWrite(RELAY_PIN, LOW);
        }
        else if (rxValue == "MODE_SOUND") { // MODE SONORE
          currentMode = "MODE_SOUND";
          digitalWrite(RELAY_PIN, LOW);
          // Réinitialiser l'état et démarrer le délai d'ignorance
          lastSoundTime = 0;
          clapCount = 0;
          soundRelayState = false;
          soundModeStartTime = millis(); // Le son du bip sera ignoré pendant 1.5 sec
        }
        else if (rxValue == "MODE_NONE") {
          currentMode = "MODE_NONE";
          digitalWrite(RELAY_PIN, LOW);
        }
        
        // Gestion des actions du MODE MANUEL
        else if (rxValue == "MANUAL_ON" && currentMode == "MODE_MANUAL") {
          digitalWrite(RELAY_PIN, HIGH);
        } 
        else if (rxValue == "MANUAL_OFF" && currentMode == "MODE_MANUAL") {
          digitalWrite(RELAY_PIN, LOW);
        }
      }
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(BUZZER_PIN, OUTPUT);
    pinMode(RELAY_PIN, OUTPUT);
    pinMode(PIR_PIN, INPUT); // Configuration du PIR en entrée
    pinMode(SOUND_PIN, INPUT); // Configuration du capteur de son
    
    BLEDevice::init("MWINDA_ESP32");// Nom Bluetooth de l'ESP32
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
    // Si le mode mouvement est activé, on écoute le capteur PIR
    if (currentMode == "MODE_MOTION") {
        static unsigned long lastMotionTime = 0;
        static bool wasOn = false;

        if (digitalRead(PIR_PIN) == HIGH) {
            if (!wasOn) {
                // Front montant : mouvement vient d'être détecté → bip + allumage
                beepTwice();
                wasOn = true;
            }
            lastMotionTime = currentMillis;
            digitalWrite(RELAY_PIN, HIGH);
        } else if (currentMillis - lastMotionTime > 5000) {
            // Plus de mouvement depuis 5 sec → extinction
            digitalWrite(RELAY_PIN, LOW);
            wasOn = false;
        }
        delay(200);
    }
    // ----------------------------------------------------
    // MODE SONORE (Claquement / Clap)
    // ----------------------------------------------------
    else if (currentMode == "MODE_SOUND") {
        // Ignorer tous les sons pendant 1.5 sec après activation
        // (évite que le bip de confirmation BLE soit détecté comme un clap)
        if (currentMillis - soundModeStartTime < 1500) {
            delay(50);
        } else {
            int soundDetected = digitalRead(SOUND_PIN);

            if (soundDetected == HIGH) {
                // Anti-rebond : ignorer les bruits < 200ms
                if (currentMillis - lastSoundTime > 200) {
                    // Si > 1 sec depuis le dernier clap → recommencer le compteur
                    if (currentMillis - lastSoundTime > 1000) {
                        clapCount = 1;
                    } else {
                        clapCount++;
                    }
                    lastSoundTime = currentMillis;

                    if (clapCount >= 2) {
                        soundRelayState = !soundRelayState;
                        digitalWrite(RELAY_PIN, soundRelayState ? HIGH : LOW);
                        // Pas de beep ici : le buzzer serait re-détecté par le capteur
                        clapCount = 0;
                    }
                }
            }
            delay(10);
        }
    }
}
