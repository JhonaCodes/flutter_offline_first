import 'ffi_bridge.dart';
import 'local_db_model.dart';

void main() async{
  RustLib.initialize("rust_db");
  //
  // 1. Intentamos guardar
  LocalDbModel modelToSave = LocalDbModel(
      id: "test1",
      hash: "hash123",
      data: {"test": "value"}
  );
  //
  //
  // print("Intentando guardar: ${modelToSave.toJson()}");
  // final savedModel = RustLib.push(modelToSave);
  // print("Modelo guardado: ${savedModel.toJson()}");

  // final retrieved = RustLib.getById("test1");
  // print("Modelo recuperado: ${retrieved?.toJson()}");


  //
  // print("Obteniendo todos los modelos...");
  // final allModels = RustLib.getAll();
  // print("Total de modelos obtenidos: ${allModels.length}");
  // for (var model in allModels) {
  //   print("Modelo: ${model.toJson()}");
  // }
  //

  // modelToSave = modelToSave.copyWith(
  //   data: {
  //     "name": "Jhonatan",
  //     "age": 12,
  //     "is_admin": true,
  //     "email": "jhonacode@gmail.com",
  //     "phone": "123456789",
  //     "location":34.541,
  //     "house":{
  //       "number":32,
  //       "is_main":true,
  //     }
  //   }
  // );
  //
  //
  // print("Intentando guardar: ${modelToSave.toJson()}");
  // final updateModel = RustLib.push(modelToSave);
  // print("Modelo guardado: ${updateModel.toJson()}");


  // print("Intentando eliminar desde Dart: test1");
  // final deleteModel = RustLib.delete("test1");
  // print("Modelo fue eliminado ${deleteModel}");

  //
  final retrieved = RustLib.getById("test1");
  print("Modelo recuperado: ${retrieved?.toJson()}");


}
