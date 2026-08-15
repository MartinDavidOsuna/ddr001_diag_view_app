#include <Arduino.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#ifndef DDR001_PULSE_PIN
#define DDR001_PULSE_PIN 27
#endif
#ifndef DDR001_LED_PIN
#define DDR001_LED_PIN 2
#endif
#ifndef DDR001_LED_ACTIVE_LEVEL
#define DDR001_LED_ACTIVE_LEVEL HIGH
#endif
#ifndef DDR001_LED_ON_MS
#define DDR001_LED_ON_MS 120
#endif
#ifndef DDR001_DEBOUNCE_MS
#define DDR001_DEBOUNCE_MS 40
#endif

namespace {
constexpr char kServiceUuid[] = "7b3a0001-6d5f-4f3c-9a21-4d4452303031";
constexpr char kCounterUuid[] = "7b3a0002-6d5f-4f3c-9a21-4d4452303031";
constexpr char kStatusUuid[] = "7b3a0003-6d5f-4f3c-9a21-4d4452303031";
constexpr uint8_t kProtocolVersion = 1;

volatile bool pulseEdge = false;
volatile uint32_t lastInterruptMs = 0;
uint32_t pulseCounter = 0;
uint32_t ledOffAt = 0;
BLECharacteristic* counterCharacteristic = nullptr;
BLECharacteristic* statusCharacteristic = nullptr;

constexpr uint8_t kLedInactiveLevel =
    DDR001_LED_ACTIVE_LEVEL == HIGH ? LOW : HIGH;

void IRAM_ATTR onPulseEdge() {
  const uint32_t now = millis();
  if (now - lastInterruptMs >= DDR001_DEBOUNCE_MS) {
    lastInterruptMs = now;
    pulseEdge = true;
  }
}

void encodeCounter(uint32_t value, uint8_t (&payload)[5]) {
  payload[0] = kProtocolVersion;
  payload[1] = static_cast<uint8_t>(value);
  payload[2] = static_cast<uint8_t>(value >> 8);
  payload[3] = static_cast<uint8_t>(value >> 16);
  payload[4] = static_cast<uint8_t>(value >> 24);
}

void publishCounter(bool notify = true) {
  uint8_t payload[5];
  encodeCounter(pulseCounter, payload);
  counterCharacteristic->setValue(payload, sizeof(payload));
  if (notify) counterCharacteristic->notify();
}

void acceptPulse(const char* source) {
  ++pulseCounter;
  digitalWrite(DDR001_LED_PIN, DDR001_LED_ACTIVE_LEVEL);
  ledOffAt = millis() + DDR001_LED_ON_MS;
  publishCounter();
  Serial.printf("pulse source=%s counter=%lu\n", source,
                static_cast<unsigned long>(pulseCounter));
}

class ServerCallbacks final : public BLEServerCallbacks {
  void onConnect(BLEServer*) override { Serial.println("ble connected"); }
  void onDisconnect(BLEServer* server) override {
    Serial.println("ble disconnected; advertising");
    server->getAdvertising()->start();
  }
};
}  // namespace

void setup() {
  Serial.begin(115200);
  pinMode(DDR001_PULSE_PIN, INPUT_PULLUP);
  pinMode(DDR001_LED_PIN, OUTPUT);
  digitalWrite(DDR001_LED_PIN, kLedInactiveLevel);
  attachInterrupt(digitalPinToInterrupt(DDR001_PULSE_PIN), onPulseEdge, FALLING);

  const uint64_t mac = ESP.getEfuseMac();
  char name[24];
  snprintf(name, sizeof(name), "DDR001-PULSE-%04X",
           static_cast<unsigned int>(mac & 0xffff));
  BLEDevice::init(name);
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService* service = server->createService(kServiceUuid);
  counterCharacteristic = service->createCharacteristic(
      kCounterUuid, BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY);
  counterCharacteristic->addDescriptor(new BLE2902());
  statusCharacteristic = service->createCharacteristic(
      kStatusUuid, BLECharacteristic::PROPERTY_READ);
  statusCharacteristic->setValue("DDR001:PULSE:V1");
  publishCounter(false);
  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(kServiceUuid);
  advertising->setScanResponse(true);
  advertising->start();

  Serial.printf(
      "boot device=%s pulsePin=%d ledPin=%d ledActive=%s ledOnMs=%d\n",
      name, DDR001_PULSE_PIN, DDR001_LED_PIN,
      DDR001_LED_ACTIVE_LEVEL == HIGH ? "HIGH" : "LOW", DDR001_LED_ON_MS);
  Serial.println("ble ready protocol=v1 counter=0; serial test command: p");
}

void loop() {
  if (pulseEdge) {
    noInterrupts();
    pulseEdge = false;
    interrupts();
    acceptPulse("gpio");
  }
  if (ledOffAt != 0 && static_cast<int32_t>(millis() - ledOffAt) >= 0) {
    digitalWrite(DDR001_LED_PIN, kLedInactiveLevel);
    ledOffAt = 0;
  }
  if (Serial.available() && Serial.read() == 'p') {
    acceptPulse("serial-test");
  }
  delay(1);
}
