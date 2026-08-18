#include <Arduino.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>

#ifndef DDR001_CONTROL_FLOW_PIN
#define DDR001_CONTROL_FLOW_PIN 27
#endif
#ifndef DDR001_METER_UNDER_TEST_PIN
#define DDR001_METER_UNDER_TEST_PIN 25
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
constexpr uint8_t kProtocolVersion = 2;

volatile bool controlPulseEdge = false;
volatile bool meterPulseEdge = false;
volatile uint32_t lastControlInterruptMs = 0;
volatile uint32_t lastMeterInterruptMs = 0;
uint32_t controlPulseCounter = 0;
uint32_t meterPulseCounter = 0;
uint32_t ledOffAt = 0;
BLECharacteristic* counterCharacteristic = nullptr;
BLECharacteristic* statusCharacteristic = nullptr;

constexpr uint8_t kLedInactiveLevel =
    DDR001_LED_ACTIVE_LEVEL == HIGH ? LOW : HIGH;

void IRAM_ATTR onControlPulseEdge() {
  const uint32_t now = millis();
  if (now - lastControlInterruptMs >= DDR001_DEBOUNCE_MS) {
    lastControlInterruptMs = now;
    controlPulseEdge = true;
  }
}

void IRAM_ATTR onMeterPulseEdge() {
  const uint32_t now = millis();
  if (now - lastMeterInterruptMs >= DDR001_DEBOUNCE_MS) {
    lastMeterInterruptMs = now;
    meterPulseEdge = true;
  }
}

void encodeCounters(uint8_t (&payload)[9]) {
  payload[0] = kProtocolVersion;
  for (uint8_t i = 0; i < 4; ++i) {
    payload[1 + i] = static_cast<uint8_t>(controlPulseCounter >> (8 * i));
    payload[5 + i] = static_cast<uint8_t>(meterPulseCounter >> (8 * i));
  }
}

void publishCounter(bool notify = true) {
  uint8_t payload[9];
  encodeCounters(payload);
  counterCharacteristic->setValue(payload, sizeof(payload));
  if (notify) counterCharacteristic->notify();
}

void acceptControlPulse(const char* source) {
  ++controlPulseCounter;
  digitalWrite(DDR001_LED_PIN, DDR001_LED_ACTIVE_LEVEL);
  ledOffAt = millis() + DDR001_LED_ON_MS;
  publishCounter();
  Serial.printf("control source=%s gpio=%d counter=%lu\n", source,
                DDR001_CONTROL_FLOW_PIN,
                static_cast<unsigned long>(controlPulseCounter));
}

void acceptMeterPulse(const char* source) {
  ++meterPulseCounter;
  publishCounter();
  Serial.printf("meter source=%s gpio=%d counter=%lu\n", source,
                DDR001_METER_UNDER_TEST_PIN,
                static_cast<unsigned long>(meterPulseCounter));
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
  pinMode(DDR001_CONTROL_FLOW_PIN, INPUT_PULLUP);
  pinMode(DDR001_METER_UNDER_TEST_PIN, INPUT_PULLUP);
  pinMode(DDR001_LED_PIN, OUTPUT);
  digitalWrite(DDR001_LED_PIN, kLedInactiveLevel);
  attachInterrupt(digitalPinToInterrupt(DDR001_CONTROL_FLOW_PIN),
                  onControlPulseEdge, FALLING);
  attachInterrupt(digitalPinToInterrupt(DDR001_METER_UNDER_TEST_PIN),
                  onMeterPulseEdge, FALLING);

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
  statusCharacteristic->setValue("DDR001:DUAL:V2");
  publishCounter(false);
  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(kServiceUuid);
  advertising->setScanResponse(true);
  advertising->start();

  Serial.printf(
      "boot device=%s controlPin=%d meterPin=%d ledPin=%d ledActive=%s ledOnMs=%d\n",
      name, DDR001_CONTROL_FLOW_PIN, DDR001_METER_UNDER_TEST_PIN, DDR001_LED_PIN,
      DDR001_LED_ACTIVE_LEVEL == HIGH ? "HIGH" : "LOW", DDR001_LED_ON_MS);
  Serial.println("ble ready protocol=v2 control=0 meter=0; serial: p=control m=meter");
}

void loop() {
  if (controlPulseEdge) {
    noInterrupts();
    controlPulseEdge = false;
    interrupts();
    acceptControlPulse("gpio");
  }
  if (meterPulseEdge) {
    noInterrupts();
    meterPulseEdge = false;
    interrupts();
    acceptMeterPulse("gpio");
  }
  if (ledOffAt != 0 && static_cast<int32_t>(millis() - ledOffAt) >= 0) {
    digitalWrite(DDR001_LED_PIN, kLedInactiveLevel);
    ledOffAt = 0;
  }
  if (Serial.available()) {
    const char command = Serial.read();
    if (command == 'p') acceptControlPulse("serial-test");
    if (command == 'm') acceptMeterPulse("serial-test");
  }
  delay(1);
}
