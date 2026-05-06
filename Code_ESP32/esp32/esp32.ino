#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Définition des broches
#define BUZZER_PIN 18// Broche du  buzzer
#define RELAY_PIN 19// Broche du relais
// UUIDs générés pour MWINDA (à copier à l'identique dans Flutter)
#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;

// Fonction pour le double bip du buzzer
void beepTwice() {
    for(int i = 0; i < 2; i++) {
        digitalWrite(BUZZER_PIN, HIGH);
        delay(100); // Bip pendant 100ms
        digitalWrite(BUZZER_PIN, LOW);
        delay(100); // Silence pendant 100ms
    }
}

// Callbacks pour gérer la connexion/déconnexion
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Smartphone connecté !");
    };
    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Smartphone déconnecté. Redémarrage de l'Advertising...");
      BLEDevice::startAdvertising(); // Relancer la visibilité si on perd la connexion
    }
};

// Callbacks pour la réception des commandes depuis Flutter
class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      String rxValue = pCharacteristic->getValue();
      if (rxValue.length() > 0) {
        Serial.print("Commande reçue : ");
        Serial.println(rxValue);
        
        beepTwice(); // Signal sonore de confirmation

        if (rxValue == "MANUAL_ON") {
          digitalWrite(RELAY_PIN, HIGH);
          Serial.println("Lampe : ALLUMÉE");
        } 
        else if (rxValue == "MANUAL_OFF") {
          digitalWrite(RELAY_PIN, LOW);
          Serial.println("Lampe : ÉTEINTE");
        }
      }
    }
};

void setup() {
    Serial.begin(115200);
    pinMode(BUZZER_PIN, OUTPUT);
    pinMode(RELAY_PIN, OUTPUT);
    Serial.println("Initialisation du BLE...");
    BLEDevice::init("MWINDA_ESP32"); // Nom visible lors du scan
    
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());
    
    BLEService *pService = pServer->createService(SERVICE_UUID);
    
    // Création de la caractéristique en mode Écriture (pour recevoir) et Notification (pour envoyer un statut plus tard)
    pCharacteristic = pService->createCharacteristic(
                        CHARACTERISTIC_UUID,
                        BLECharacteristic::PROPERTY_WRITE |
                        BLECharacteristic::PROPERTY_NOTIFY
                      );
                      
    pCharacteristic->setCallbacks(new MyCallbacks());
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();
    
    // Configuration de l'Advertising
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
    
    Serial.println("MWINDA prêt. En attente d'une connexion BLE...");
}

void loop() {
    // La boucle principale est vide pour l'instant.
    delay(2000);
}