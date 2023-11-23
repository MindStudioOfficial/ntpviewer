import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';

class NTPProvider extends ChangeNotifier {
  final Map<String, (InternetAddress ip, int? offset)> _ntpServers = {};

  Map<String, (InternetAddress ip, int? offset)> get ntpServers => _ntpServers;

  Future<bool> addNTPServer(String host) async {
    InternetAddress? ip;
    try {
      ip = InternetAddress(host);
    } catch (e) {
      try {
        final addresses = await InternetAddress.lookup(host);
        ip = addresses.isNotEmpty ? addresses.first : null;
      } on SocketException {
        ip = null;
      }
    }
    if (ip == null) return false;

    _ntpServers[host] = (ip, null);
    notifyListeners();
    return true;
  }

  Future<void> removeNTPServer(String host) async {
    _ntpServers.remove(host);
    notifyListeners();
  }

  Future<void> refreshServers() async {
    for (var i = 0; i < _ntpServers.length; i++) {
      final host = _ntpServers.keys.elementAt(i);
      final ip = _ntpServers[host]?.$1;
      if (ip != null) {
        final offset = await NTP.getNtpOffset(
          lookUpAddress: ip.address,
        );
        _ntpServers[host] = (ip, offset);
      }
    }
    notifyListeners();
  }
}
