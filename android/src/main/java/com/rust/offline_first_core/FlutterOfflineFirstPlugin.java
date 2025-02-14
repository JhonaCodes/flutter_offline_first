package com.rust.offline_first_core;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class FlutterOfflineFirstPlugin implements FlutterPlugin {
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        // No necesitamos implementar nada aquí ya que solo usamos FFI
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        // No necesitamos implementar nada aquí
    }
}