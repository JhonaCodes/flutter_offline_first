# Offline First con ReactiveNotifier y Rust

## Visión General
Este documento describe una implementación de Offline First utilizando ReactiveNotifier para el manejo de estado y Rust para el almacenamiento local y sincronización de datos.

## Arquitectura

### 1. Core Components

#### ReactiveNotifier Middleware
El middleware actúa como interceptor entre las peticiones API y el almacenamiento local:

```dart
mixin OfflineMiddleware {
  static final connectivityState = ReactiveNotifier<ConnectivityStatus>(() => ConnectivityStatus.unknown);
  
  static Future<T> handleRequest<T>({
    required Future<T> Function() onlineRequest,
    required Future<T> Function() offlineData,
  }) async {
    if (connectivityState.notifier == ConnectivityStatus.online) {
      try {
        final result = await onlineRequest();
        await syncToLocal(result);
        return result;
      } catch (e) {
        return await offlineData();
      }
    }
    return await offlineData();
  }
}
```

#### Rust Local Storage
Implementación de base de datos local usando SurrealDB:

```rust
pub struct LocalStorage {
    db: SurrealDB,
    sync_state: Arc<Mutex<SyncState>>,
}

impl LocalStorage {
    pub async fn save_data(&self, collection: &str, data: Value) -> Result<()> {
        let token = self.compute_data_token(&data);
        if self.has_changes(collection, &token) {
            self.db.update(collection, data).await?;
            self.update_sync_state(collection, token);
        }
        Ok(())
    }
}
```

### 2. Queue System

#### Queue State Management
```dart
enum QueuePriority { time, mutation, query }

class QueueItem {
  final String id;
  final DateTime createdAt;
  final HttpMethod method;
  final String endpoint;
  final dynamic data;
  int retryCount = 0;

  QueuePriority get priority {
    if (method == HttpMethod.get) return QueuePriority.query;
    return QueuePriority.mutation;
  }
}

mixin QueueService {
  static final queueState = ReactiveNotifier<Map<String, QueueItem>>(() => {});
  
  static List<QueueItem> get prioritizedQueue {
    final items = queueState.notifier.values.toList();
    return items..sort((a, b) {
      final timeDiff = b.createdAt.difference(a.createdAt).inMinutes;
      if (timeDiff > 30) return timeDiff.sign;
      return b.priority.index.compareTo(a.priority.index);
    });
  }
}
```

#### Queue Configuration
```dart
class QueueConfiguration {
  final Duration timeThreshold;
  final Map<String, QueuePriority> customEndpointPriorities;
  final List<PriorityRule> priorityRules;

  const QueueConfiguration({
    this.timeThreshold = const Duration(minutes: 30),
    this.customEndpointPriorities = const {},
    this.priorityRules = const [],
  });
}

mixin QueueConfig {
  static final queueConfigState = ReactiveNotifier<QueueConfiguration>(() => 
    QueueConfiguration()
  );
}
```

### 3. Sync System

#### Data Sync Management
```dart
mixin SyncMiddleware {
  static final syncState = ReactiveNotifier<SyncState>(() => SyncState());

  static Future<T> handleResponse<T>({
    required T data,
    required String collection,
  }) async {
    final newDataToken = await computeDataToken(data);
    final localDataToken = await getLocalDataToken(collection);
    
    if (newDataToken != localDataToken) {
      await saveToLocal(collection, data);
      syncState.transformState((state) => 
        state.copyWith(
          lastSync: DateTime.now(),
          collection: collection,
          dataToken: newDataToken
        )
      );
    }
    return data;
  }
}
```

## Implementación

### 1. Setup Inicial

1. Agregar dependencias:
```yaml
dependencies:
  reactive_notifier: ^latest
  flutter_rust_bridge: ^latest
  surreal_db: ^latest
```

2. Configurar Rust bridge:
```dart
// Bridge configuration
@FlutterRustBridge(prefix: 'local_storage')
abstract class LocalStorageApi {
  Future<void> saveData(String collection, dynamic data);
  Future<dynamic> getData(String collection, String id);
  Future<String> computeDataToken(dynamic data);
}
```

### 2. Uso Básico

```dart
// Service implementation
class UserService {
  static final userState = ReactiveNotifier<UserState>(() => UserState());
  
  static Future<void> fetchUser() async {
    final result = await OfflineMiddleware.handleRequest(
      onlineRequest: () => api.fetchUser(),
      offlineData: () => LocalStorage.getData('users', userId),
    );
    
    userState.transformState((state) => 
      state.copyWith(userData: result)
    );
  }
}

// UI usage
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ReactiveBuilder(
      notifier: UserService.userState,
      builder: (state, _) => UserProfileWidget(user: state),
    );
  }
}
```

### 3. Manejo de Sincronización

1. Detectar cambios de conectividad:
```dart
void initConnectivity() {
  Connectivity().onConnectivityChanged.listen((result) {
    final isOnline = result != ConnectivityResult.none;
    ConnectivityService.onConnectivityChanged(isOnline);
  });
}
```

2. Procesar queue cuando hay conexión:
```dart
mixin ConnectivityService {
  static void onConnectivityChanged(bool isOnline) {
    if (isOnline) {
      QueueService.processQueue();
    }
  }
}
```

## Consideraciones de Implementación

### Performance
- Usar tokens/hashes para detectar cambios
- Implementar batching para sincronización
- Minimizar escrituras a disco

### Seguridad
- Encriptar datos sensibles en almacenamiento local
- Validar integridad de datos
- Manejar tokens de autenticación

### Edge Cases
- Conflictos de sincronización
- Pérdida de conexión durante sincronización
- Límites de almacenamiento local

## Roadmap

### Fase 1: Core
- [x] Implementación básica de ReactiveNotifier
- [x] Sistema de Queue
- [ ] Integración con Rust/SurrealDB

### Fase 2: Features
- [ ] Sistema de priorización configurable
- [ ] Manejo de conflictos
- [ ] Compresión de datos

### Fase 3: Optimización
- [ ] Batching de operaciones
- [ ] Mejoras de performance
- [ ] Reducción de uso de memoria

## Referencias
- [ReactiveNotifier Documentation](https://pub.dev/packages/reactive_notifier)
- [SurrealDB Documentation](https://surrealdb.com/docs)
- [Flutter Rust Bridge](https://github.com/fzyzcjy/flutter_rust_bridge)
