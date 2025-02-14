// lib/src/bridge.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_offline_first/src/ffi_functions.dart';


import 'local_db_model.dart';


final class AppDbState extends Opaque {}


class RustLib {
  static late final DynamicLibrary _lib;
  static late final Pointer<AppDbState> _dbInstance;

  static Future<void> initialize(String databaseName) async{
    _lib = await _loadLibrary();
    _bindFunctions();
    _init(databaseName);
  }

  static Future<DynamicLibrary>  _loadLibrary() async{
    try {
      if (Platform.isAndroid) {
        return DynamicLibrary.open('liboffline_first_core.so');
      } else if (Platform.isIOS) {
        return DynamicLibrary.open('ios/liboffline_first_core.a');
      } else if (Platform.isMacOS) {
        return DynamicLibrary.open('macos/liboffline_first_core.dylib');
      } else {
        throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
      }
    } catch (e) {
      print('Error loading library: $e');
      rethrow;
    }
  }

  static late final Pointer<AppDbState> Function(Pointer<Utf8>) _createDatabase;
  static late final Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>) _push;
  static late final Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>) _getById;
  static late final Pointer<Utf8> Function(Pointer<AppDbState>) _getAll;
  static late final Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>) _put;
  static late final Pointer<Bool> Function(Pointer<AppDbState>, Pointer<Utf8>) _delete;

  static void _bindFunctions() {
    _createDatabase = _lib.lookupFunction<Pointer<AppDbState> Function(Pointer<Utf8>), Pointer<AppDbState> Function(Pointer<Utf8>)>(FFiFunctions.createDb.cName);
    _push = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>), Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>)>(FFiFunctions.pushData.cName);
    _getById = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>), Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>)>(FFiFunctions.getById.cName);
    _getAll = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<AppDbState>), Pointer<Utf8> Function(Pointer<AppDbState>)>(FFiFunctions.getAll.cName);
    _put = _lib.lookupFunction<Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>),Pointer<Utf8> Function(Pointer<AppDbState>, Pointer<Utf8>)>(FFiFunctions.updateData.cName);
    _delete = _lib.lookupFunction<Pointer<Bool> Function(Pointer<AppDbState>, Pointer<Utf8>), Pointer<Bool> Function(Pointer<AppDbState>, Pointer<Utf8>)>(FFiFunctions.delete.cName);
  }

  static Future<void> _init(String databaseName) async{
    try {
      final dbNamePtr = databaseName.toNativeUtf8();

      _dbInstance = _createDatabase(dbNamePtr);
      calloc.free(dbNamePtr);
    } catch (error, stackTrace) {
      log('Error initializing database: $error');
      log(stackTrace.toString());
      rethrow; // Es importante relanzar el error para manejarlo en la capa superior
    }
  }

  static LocalDbModel push(LocalDbModel model) {
    try {
      final jsonString = jsonEncode(model.toJson());
      final jsonPointer = jsonString.toNativeUtf8();

      final resultPtr = _push(_dbInstance, jsonPointer);
      final result = resultPtr.cast<Utf8>().toDartString();

      calloc.free(jsonPointer);
      malloc.free(resultPtr); // Importante liberar la memoria del resultado

      return LocalDbModel.fromJson(jsonDecode(result));
    } catch (error, stackTrace) {
      log('Error in push operation: $error');
      log(stackTrace.toString());
      rethrow;
    }
  }

  static LocalDbModel? getById(String id) {  // Nota el ? porque puede retornar null
    try {
      final idPtr = id.toNativeUtf8();
      final resultFfi = _getById(_dbInstance, idPtr);

      // Liberar memoria del id
      calloc.free(idPtr);

      // Verificar si hay resultado
      if (resultFfi == nullptr) {
        return null;  // No se encontró el registro
      }

      // Procesar el resultado
      final resultTransformed = resultFfi.cast<Utf8>().toDartString();
      malloc.free(resultFfi);

      return LocalDbModel.fromJson(jsonDecode(resultTransformed));

    } catch(error, stackTrace) {
      log(error.toString());
      log(stackTrace.toString());
      rethrow;
    }
  }

  static List<LocalDbModel> getAll() {
    try {
      log("Iniciando getAll");
      final resultFfi = _getAll(_dbInstance);
      log("Resultado FFI obtenido");

      if (resultFfi == nullptr) {
        log("resultFfi es nullptr, retornando lista vacía");
        return [];
      }

      final resultString = resultFfi.cast<Utf8>().toDartString();
      log("String recibido de Rust: $resultString");
      malloc.free(resultFfi);

      final List<dynamic> jsonList = jsonDecode(resultString);
      log("JSON decodificado: $jsonList");

      final results = jsonList.map((json) => LocalDbModel.fromJson(json)).toList();
      log("Modelos convertidos: ${results.length}");

      return results;

    } catch(error, stackTrace) {
      log("Error en getAll: $error");
      log("Stack trace: $stackTrace");
      rethrow;
    }
  }

  static LocalDbModel put(LocalDbModel model) {
    try{
      final jsonString = jsonEncode(model.toJson());
      final jsonPointer = jsonString.toNativeUtf8();
      final resultFfi = _put(_dbInstance, jsonPointer);
      final result = resultFfi.cast<Utf8>().toDartString();
      calloc.free(jsonPointer);
      malloc.free(resultFfi);
      return LocalDbModel.fromJson(jsonDecode(result));
    }catch(error, stackTrace){
      log("Error en getAll: $error");
      log("Stack trace: $stackTrace");
      rethrow;
    }
  }

  static bool delete(String id) {
    print("From function delete");

    try {
      final idPtr = id.toNativeUtf8();
      print("Id a eliminar Pointer: address=${idPtr.address}");

      final resultFfi = _delete(_dbInstance, idPtr);
      print("response delete Pointer: address=${resultFfi.address}");

      calloc.free(idPtr);
      print("Space cleaned");

      // Convierte el puntero a un valor booleano
      return resultFfi.address == 1;

    } catch (error, stackTrace) {
      log("Error en delete: $error");
      log("Stack trace: $stackTrace");
      return false;
    }
  }


}
