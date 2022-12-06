import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

// To prevent race conditions, the class is a singleton.
class LocalStorage {
  // Storage-side (Serialized)
  final _storage = const FlutterSecureStorage();

  // // PRIVATE CONSTRUCTOR
  // LocalStorage._internalConstructor();
  // static final LocalStorage _LocalStorage = LocalStorage._internalConstructor();
  // // Merely return refernce to the one and only.
  // factory LocalStorage() => _LocalStorage;

  // Storage -> UI
  // Query data from storage and return decoded instance
  Future<dynamic> queryFromStorage(String storageKey) async {
    String? serializedData = await _storage.read(key: storageKey);
    if (serializedData != null){
      return json.decode(serializedData);
    }else{
      throw Exception('DATA DNE');
    }
  }

  // UI -> Storage
  // Update storage for the given key with the object
  Future<void> updateStorageSide(String storageKey, dynamic object) async {
    await _storage.write(key: storageKey, value: jsonEncode(object));
  }

  // CLEAR
  // Remove data saved in storage for the given key
  Future<void> clearStorage(String storageKey) async {
    await _storage.delete(key: storageKey);
  }
}

// To prevent race conditions, the class is a singleton.
class LoginStorage with LocalStorage {
  final String storageServerKey = 'ip';
  final String storageCredentialsKey = 'credentials';
  final int storageSize = 5;

  // UI-side (deserialized)
  static List<String> _servers = [];
  static List<Map<String, String>> _credentials = [];

  // PRIVATE CONSTRUCTOR
  LoginStorage._internalConstructor();
  static final LoginStorage _loginStorage = LoginStorage._internalConstructor();
  // Merely return refernce to the one and only.
  factory LoginStorage() => _loginStorage;

  // Storage -> UI
  Future<void> updateUISideServer() async {
    try {
      List<dynamic> temp = await queryFromStorage(storageServerKey);
      _servers = List.from(temp.map((e) => e as String));
    } catch (e) {
      _servers.clear();
    }
  }

  Future<void> updateUISideCredential() async {
    try {
      List<dynamic> temp = await queryFromStorage(storageCredentialsKey);
      _credentials = List.from(temp.map((e) => Map<String, String>.from(e)));
    } catch (e) {
      _credentials.clear();
    }
  }

  Future<void> updateUISideInstances() async {
    await updateUISideServer();
    await updateUISideCredential();
  }

  // UI -> Storage
  Future<void> updateStorageSideServer() async {
    await updateStorageSide(storageServerKey, _servers);
  }

  Future<void> updateStorageSideCredential() async {
    await updateStorageSide(storageCredentialsKey, _credentials);
  }

  Future<void> updateStorageSideData() async {
    await updateStorageSideServer();
    await updateStorageSideCredential();
  }

  // CLEAR
  Future<void> deleteServerList() async {
    _servers.clear();
    await clearStorage(storageServerKey);
  }

  Future<void> deleteCredentialsList() async {
    _credentials.clear();
    await clearStorage(storageCredentialsKey);
  }

  Future<void> deleteAll() async {
    await deleteServerList();
    await deleteCredentialsList();
  }

  // ADD & EDIT (UI SIDE)
  void addServer(String newServer) {
    if (!_servers.contains(newServer)){
      if (_servers.length == storageSize){
        _servers.removeAt(0);
      }
      _servers.add(newServer);
    }else{
      // SWAP ORDER
      _servers.remove(newServer);
      _servers.add(newServer);
    }
  }

  void addCredential(String username, String password){
    if (_credentials.any((element) => element['username'] == username)){
      // SWAP ORDER
      _credentials.removeWhere((element) => element['username'] == username);
      _credentials.add({'username': username, 'password': password});
    }else{
      if (_credentials.length == storageSize){
        _credentials.removeAt(0);
      }
      _credentials.add({'username': username, 'password': password});
    }
  }

  // GET
  List<String> getServers() => _servers;
  List<String> getUsernames() => _credentials.map<String>((e) => e['username']!).toList();
  // {username: password, ...}
  Map<String, String> getCredentials() => Map.fromIterable(_credentials.map((e) => {e['username']: e['password']}));
  String getMostRecentServer() => (_servers.isNotEmpty) ? _servers.last : '';
  String getMostRecentUsername() => (_credentials.isNotEmpty) ? _credentials.last['username']! : '';
  String getPasswordGivenUsername(String username) => (_credentials.isNotEmpty) ? _credentials.firstWhere((element) => element['username'] == username, orElse: () => {'password': ''})['password']! : '';
}
