#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define BUZZER_PIN 18// Broche pour le buzzer
#define RELAY_PIN 19// Broche pour le relais
#define PIR_PIN 27 // Nouvelle broche pour le capteur de mouvement

#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// Variable pour stocker le mode actuel
String currentMode = "MODE_NONE";

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
        
        beepTwice(); // Bip à chaque commande reçue

        // Gestion des changements de MODE
        if (rxValue == "MODE_MANUAL") {
          currentMode = "MODE_MANUAL";
          digitalWrite(RELAY_PIN, LOW); // On éteint par défaut en entrant dans le mode
        } 
        else if (rxValue == "MODE_MOTION") {
          currentMode = "MODE_MOTION";
          digitalWrite(RELAY_PIN, LOW);
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
            lastMotionTime = millis();
            digitalWrite(RELAY_PIN, HIGH);
        } else if (millis() - lastMotionTime > 5000) {
            // Plus de mouvement depuis 5 sec → extinction
            digitalWrite(RELAY_PIN, LOW);
            wasOn = false;
        }
        delay(200);
    }
}
