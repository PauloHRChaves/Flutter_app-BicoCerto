import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

Future<Map<String, dynamic>> getDeviceInfo() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> deviceData;

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
    deviceData = {
      "device_id": androidInfo.id,
      "platform": "Android",
      "model": androidInfo.model,
      "os_version": androidInfo.version.release,
      "app_version": "1.0.0"
    };
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
    deviceData = {
      "device_id": iosInfo.identifierForVendor,
      "platform": "iOS",
      "model": iosInfo.model,
      "os_version": iosInfo.systemVersion,
      "app_version": "1.0.0"
    };
  } else {
    deviceData = {};
  }
  return deviceData;
}
// Dependência device_info_plus - pegar informações do device - ( AINDA NÃO APLICADA )