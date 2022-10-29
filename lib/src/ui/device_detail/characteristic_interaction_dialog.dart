import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_reactive_ble_example/src/ble/ble_device_interactor.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

var id = 0;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class CharacteristicInteractionDialog extends StatelessWidget {
  const CharacteristicInteractionDialog({
    required this.characteristic,
    Key? key,
  }) : super(key: key);
  final QualifiedCharacteristic characteristic;

  @override
  Widget build(BuildContext context) => Consumer<BleDeviceInteractor>(
      builder: (context, interactor, _) => _CharacteristicInteractionDialog(
            characteristic: characteristic,
            readCharacteristic: interactor.readCharacteristic,
            writeWithResponse: interactor.writeCharacterisiticWithResponse,
            writeWithoutResponse:
                interactor.writeCharacterisiticWithoutResponse,
            subscribeToCharacteristic: interactor.subScribeToCharacteristic,
          ));
}

class _CharacteristicInteractionDialog extends StatefulWidget {
  const _CharacteristicInteractionDialog({
    required this.characteristic,
    required this.readCharacteristic,
    required this.writeWithResponse,
    required this.writeWithoutResponse,
    required this.subscribeToCharacteristic,
    Key? key,
  }) : super(key: key);

  final QualifiedCharacteristic characteristic;
  final Future<List<int>> Function(QualifiedCharacteristic characteristic)
      readCharacteristic;
  final Future<void> Function(
          QualifiedCharacteristic characteristic, List<int> value)
      writeWithResponse;

  final Stream<List<int>> Function(QualifiedCharacteristic characteristic)
      subscribeToCharacteristic;

  final Future<void> Function(
          QualifiedCharacteristic characteristic, List<int> value)
      writeWithoutResponse;

  @override
  _CharacteristicInteractionDialogState createState() =>
      _CharacteristicInteractionDialogState();
}

class _CharacteristicInteractionDialogState
    extends State<_CharacteristicInteractionDialog> {
  late String readOutput;
  late String writeOutput;
  late String subscribeOutput;
  late TextEditingController textEditingController;
  late StreamSubscription<List<int>>? subscribeStream;
  bool _notificationsEnabled = false;

  Future<void> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? granted = await androidImplementation?.requestPermission();
      setState(() {
        _notificationsEnabled = granted ?? false;
      });
    }
  }

  //Instancia de la clase FlutterLocalNotifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _isAndroidPermissionGranted() async {
    if (Platform.isAndroid) {
      var granted = await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
      if (granted == false) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>();

        final bool? granted = await androidImplementation?.requestPermission();
      }
    }
  }

  Future<void> _showInsistentNotification({required int id}) async {
    await flutterLocalNotificationsPlugin.show(
        id,
        'Alerta de género',
        'Se ha emitido una alerta de género.',
        NotificationDetails(
            android: AndroidNotificationDetails(
                'your channel id', 'ALERTA DE GENERO',
                channelDescription:
                    'Controlador principal para ALERTA DE GENERO',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                icon: "@mipmap/ic_launcher",
                additionalFlags: Int32List.fromList(<int>[4]))),
        payload: 'item x');
  }

  @override
  void initState() {
    readOutput = '';
    writeOutput = '';
    subscribeOutput = '';
    textEditingController = TextEditingController();
    _isAndroidPermissionGranted();
    super.initState();
  }

  @override
  void dispose() {
    subscribeStream?.cancel();
    super.dispose();
  }

  Future<void> subscribeCharacteristic() async {
    //Escuchador de los eventos
    subscribeStream = widget
        .subscribeToCharacteristic(widget.characteristic)
        .listen((event) async {
      if (utf8.decode(event).toString().contains("ALERTAVG")) {
        await _showInsistentNotification(id: id + 1);
      }
    });
  }

  Future<void> readCharacteristic() async {
    final result = await widget.readCharacteristic(widget.characteristic);
    setState(() {
      readOutput = result.toString();
    });
  }

  List<int> _parseInput() => textEditingController.text
      .split(',')
      .map(
        int.parse,
      )
      .toList();

  Future<void> writeCharacteristicWithResponse() async {
    await widget.writeWithResponse(widget.characteristic, _parseInput());
    setState(() {
      writeOutput = 'Ok';
    });
  }

  Future<void> writeCharacteristicWithoutResponse() async {
    await widget.writeWithoutResponse(widget.characteristic, _parseInput());
    setState(() {
      writeOutput = 'Realizado';
    });
  }

  Widget sectionHeader(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      );

  List<Widget> get writeSection => [
        sectionHeader('Escribir una carácteristica'),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Valor',
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: writeCharacteristicWithResponse,
              child: const Text('Con respuesta'),
            ),
            ElevatedButton(
              onPressed: writeCharacteristicWithoutResponse,
              child: const Text('Sin respuesta'),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 8.0),
          child: Text('Salida: $writeOutput'),
        ),
      ];

  List<Widget> get readSection => [
        sectionHeader('Leer carácteristica'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: readCharacteristic,
              child: const Text('Leer'),
            ),
            Text('Salida: ${readOutput}'),
          ],
        ),
      ];

  List<Widget> get subscribeSection => [
        sectionHeader('Suscribirse / Notificar'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: subscribeCharacteristic,
              child: const Text('Suscribirse'),
            ),
            Text('Salida: $subscribeOutput'),
          ],
        ),
      ];

  Widget get divider => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Divider(thickness: 2.0),
      );

  @override
  Widget build(BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Selecciona una operación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  widget.characteristic.characteristicId.toString(),
                ),
              ),
              divider,
              ...readSection,
              divider,
              ...writeSection,
              divider,
              ...subscribeSection,
              divider,
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar')),
                ),
              )
            ],
          ),
        ),
      );
}
