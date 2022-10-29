import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleStatusScreen extends StatelessWidget {
  const BleStatusScreen({required this.status, Key? key}) : super(key: key);

  final BleStatus status;

  String determineText(BleStatus status) {
    switch (status) {
      case BleStatus.unsupported:
        return "El dispositivo no soporta la tecnología Bluetooth";
      case BleStatus.unauthorized:
        return "Para usar esta aplicación se requieren los servicios de Bluetooth y localización activados";
      case BleStatus.poweredOff:
        return "Bluetooth esta apagado por favor ¡Activalo!";
      case BleStatus.locationServicesDisabled:
        return "Activa los servicios de localización";
      case BleStatus.ready:
        return "Bluetooth esta encendido y funcionando";
      default:
        return "Procesando servicios del protocolo Bluetooth...  $status";
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Text(determineText(status)),
        ),
      );
}
