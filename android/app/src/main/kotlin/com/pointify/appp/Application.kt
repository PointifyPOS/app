package com.pointify.appp

import android.app.Application
import io.flutter.embedding.engine.loader.FlutterLoader

class Application : Application() {
    override fun onCreate() {
        super.onCreate()

        val flutterLoader = FlutterLoader()
        flutterLoader.startInitialization(this)
        flutterLoader.ensureInitializationComplete(
            this,
            arrayOf("--no-enable-impeller")
        )
    }
}
