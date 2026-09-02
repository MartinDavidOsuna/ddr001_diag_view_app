/// Productive measurement methods. Visual reading is deliberately not a pulse
/// source: it provides confirmed meter readings through a later acquisition
/// layer, while the other methods provide pulse events.
enum MeasurementMethod { visual, manual, led, ble, simulation }

extension MeasurementMethodType on MeasurementMethod {
  bool get isPulseEventSource => this != MeasurementMethod.visual;
}
