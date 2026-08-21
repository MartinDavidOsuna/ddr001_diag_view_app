#include <Arduino.h>
#include <BLE2902.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <driver/pcnt.h>
#include "device_config.h"

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
#ifndef DDR001_PCNT_FILTER_CYCLES
#define DDR001_PCNT_FILTER_CYCLES 1023
#endif
#ifndef DDR001_STABLE_LOW_US
#define DDR001_STABLE_LOW_US 17000
#endif
#ifndef DDR001_STABLE_HIGH_US
#define DDR001_STABLE_HIGH_US 2000
#endif

namespace {
constexpr char kServiceUuid[] = "7b3a0001-6d5f-4f3c-9a21-4d4452303031";
constexpr char kCounterUuid[] = "7b3a0002-6d5f-4f3c-9a21-4d4452303031";
constexpr char kStatusUuid[] = "7b3a0003-6d5f-4f3c-9a21-4d4452303031";
constexpr uint8_t kProtocolVersion = 2;

uint32_t controlPulseCounter = 0;
uint32_t meterPulseCounter = 0;
uint32_t ledOffAt = 0;
BLECharacteristic* counterCharacteristic = nullptr;
BLECharacteristic* statusCharacteristic = nullptr;

struct FilteredInput {
  FilteredInput(gpio_num_t configuredPin, pcnt_unit_t configuredUnit)
      : pin(configuredPin), unit(configuredUnit) {}

  gpio_num_t pin;
  pcnt_unit_t unit;
  uint32_t lastAcceptedMs = 0;
  uint32_t candidateStartedUs = 0;
  uint32_t highStartedUs = 0;
  bool candidate = false;
  bool armed = true;
};

FilteredInput controlInput{static_cast<gpio_num_t>(DDR001_CONTROL_FLOW_PIN),
                           PCNT_UNIT_0};
FilteredInput meterInput{static_cast<gpio_num_t>(DDR001_METER_UNDER_TEST_PIN),
                         PCNT_UNIT_1};

constexpr uint8_t kLedInactiveLevel =
    DDR001_LED_ACTIVE_LEVEL == HIGH ? LOW : HIGH;

void configureFilteredInput(const FilteredInput& input) {
  pcnt_config_t config{};
  config.pulse_gpio_num = input.pin;
  config.ctrl_gpio_num = PCNT_PIN_NOT_USED;
  config.unit = input.unit;
  config.channel = PCNT_CHANNEL_0;
  config.pos_mode = PCNT_COUNT_DIS;
  config.neg_mode = PCNT_COUNT_INC;
  config.lctrl_mode = PCNT_MODE_KEEP;
  config.hctrl_mode = PCNT_MODE_KEEP;
  config.counter_h_lim = 32767;
  config.counter_l_lim = 0;
  ESP_ERROR_CHECK(pcnt_unit_config(&config));
  ESP_ERROR_CHECK(pcnt_set_filter_value(input.unit, DDR001_PCNT_FILTER_CYCLES));
  ESP_ERROR_CHECK(pcnt_filter_enable(input.unit));
  ESP_ERROR_CHECK(pcnt_counter_pause(input.unit));
  ESP_ERROR_CHECK(pcnt_counter_clear(input.unit));
  ESP_ERROR_CHECK(pcnt_counter_resume(input.unit));
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

template <typename Callback>
void pollFilteredInput(FilteredInput& input, Callback accept) {
  int16_t edges = 0;
  pcnt_get_counter_value(input.unit, &edges);
  if (edges > 0) {
    pcnt_counter_clear(input.unit);
    if (input.armed &&
        millis() - input.lastAcceptedMs >= DDR001_DEBOUNCE_MS) {
      input.candidate = true;
      input.candidateStartedUs = micros();
    }
  }

  const uint32_t nowUs = micros();
  const bool low = digitalRead(input.pin) == LOW;
  if (input.candidate) {
    if (!low) {
      input.candidate = false;
    } else if (nowUs - input.candidateStartedUs >= DDR001_STABLE_LOW_US) {
      input.candidate = false;
      input.armed = false;
      input.highStartedUs = 0;
      input.lastAcceptedMs = millis();
      accept();
    }
  }

  if (!input.armed) {
    if (!low) {
      if (input.highStartedUs == 0) input.highStartedUs = nowUs;
      if (nowUs - input.highStartedUs >= DDR001_STABLE_HIGH_US) {
        input.armed = true;
        input.highStartedUs = 0;
      }
    } else {
      input.highStartedUs = 0;
    }
  }
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
  configureFilteredInput(controlInput);
  configureFilteredInput(meterInput);

  BLEDevice::init(DDR001_DEVICE_NAME);
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService* service = server->createService(kServiceUuid);
  counterCharacteristic = service->createCharacteristic(
      kCounterUuid, BLECharacteristic::PROPERTY_READ |
                        BLECharacteristic::PROPERTY_NOTIFY);
  counterCharacteristic->addDescriptor(new BLE2902());
  statusCharacteristic = service->createCharacteristic(
      kStatusUuid, BLECharacteristic::PROPERTY_READ);
  String status = String("DDR001:DUAL:V2:") + DDR001_DEVICE_NAME;
  statusCharacteristic->setValue(status.c_str());
  publishCounter(false);
  service->start();
  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(kServiceUuid);
  advertising->setScanResponse(true);
  advertising->start();

  Serial.printf(
      "boot device=%s controlPin=%d meterPin=%d ledPin=%d ledActive=%s ledOnMs=%d\n",
      DDR001_DEVICE_NAME, DDR001_CONTROL_FLOW_PIN, DDR001_METER_UNDER_TEST_PIN, DDR001_LED_PIN,
      DDR001_LED_ACTIVE_LEVEL == HIGH ? "HIGH" : "LOW", DDR001_LED_ON_MS);
  Serial.println("ble ready protocol=v2 control=0 meter=0; serial: p=control m=meter");
}

void loop() {
  pollFilteredInput(controlInput, [] { acceptControlPulse("gpio-filtered"); });
  pollFilteredInput(meterInput, [] { acceptMeterPulse("gpio-filtered"); });
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
