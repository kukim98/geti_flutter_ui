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

// To prevent race conditions, the class is a singleton.
class TransferAnnotationStorage with LocalStorage {
  String storageTaId = 'transfer_annotation';
  late String storageTAKey;

  // UI-side (deserialized)
  static Map<String, Map<String, Map<String, bool>>> _transferAnnotationMap = {};

  // PRIVATE CONSTRUCTOR
  TransferAnnotationStorage._internalConstructor();
  static final TransferAnnotationStorage _transferAnnotationStorage = TransferAnnotationStorage._internalConstructor();
  // Merely return refernce to the one and only.
  factory TransferAnnotationStorage() => _transferAnnotationStorage;

  Future<void> updateKeyAndUI(String server, String user) async {
    storageTAKey = '$storageTaId$server$user';
    await updateUI();
  }

  // Storage -> UI
  Future<void> updateUI() async {
    try {
      Map<String, dynamic> temp = await queryFromStorage(storageTAKey);
      // _transferAnnotationMap = Map<String, Map<String, List<String>>>.from(temp);
      // Type casting
      _transferAnnotationMap = Map<String, Map<String, Map<String, bool>>>.from(
        temp.map((key, value) => MapEntry(key, Map<String, Map<String, bool>>.from(
          (value as Map<String, dynamic>).map((key, value) => MapEntry(key, Map<String, bool>.from(
            (value as Map<String, dynamic>).map((key, value) => MapEntry(key, value as bool))
          )))
        )))
      );
    } catch (e) {
      _transferAnnotationMap.clear();
    }
  }

  // UI -> Storage
  Future<void> updateStorage() async => await super.updateStorageSide(storageTAKey, _transferAnnotationMap);

  // CLEAR
  Future<void> deleteAll() async {
    _transferAnnotationMap.clear();
    await clearStorage(storageTAKey);
  }

  bool? imageTAnnotated({required String workspaceId, required String projectId, required String imageId}){
    return (!_transferAnnotationMap.containsKey(workspaceId)) ? null
      : (!_transferAnnotationMap[workspaceId]!.containsKey(projectId)) ? null
        : (!_transferAnnotationMap[workspaceId]![projectId]!.containsKey(imageId)) ? null
          : _transferAnnotationMap[workspaceId]![projectId]![imageId]!;
  }

  // ADD & EDIT (UI SIDE)
  void add({required String workspaceId, required String projectId, required String imageId, required bool taSuccess}) {
    if (!_transferAnnotationMap.containsKey(workspaceId)){
      _transferAnnotationMap[workspaceId] = <String, Map<String, bool>>{};
    }
    if (!_transferAnnotationMap[workspaceId]!.containsKey(projectId)){
      _transferAnnotationMap[workspaceId]![projectId] = <String, bool>{};
    }
    _transferAnnotationMap[workspaceId]![projectId]![imageId] = taSuccess;
    updateStorage();
  }

  void remove({required String workspaceId, required String projectId, required String imageId}) {
    try{
      _transferAnnotationMap[workspaceId]![projectId]!.remove(imageId);
      updateStorage();
    }
    catch (_){
    }
  }
}
