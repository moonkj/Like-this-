package com.likethis.likethis.camera

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Like This Android 카메라 MethodChannel 핸들러
class CameraEnginePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var cameraChannel: MethodChannel
    private lateinit var filterChannel: MethodChannel
    private lateinit var context: Context
    private var session: MFCameraSession? = null
    private val bwParams = BWRenderParams()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        cameraChannel = MethodChannel(binding.binaryMessenger, "com.likethis/camera_engine")
        cameraChannel.setMethodCallHandler(this)

        filterChannel = MethodChannel(binding.binaryMessenger, "com.likethis/filter_engine")
        filterChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cameraChannel.setMethodCallHandler(null)
        filterChannel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            // ── 카메라 채널 ───────────────────────────────────────────────────────
            "initialize" -> {
                val frontCamera = call.argument<Boolean>("frontCamera") ?: false
                // MFCameraSession 초기화 (CameraX 기반)
                // TODO: 실제 구현 시 FlutterTextureRegistry 연결 필요
                result.success(0L)
            }

            "dispose" -> {
                session?.release()
                session = null
                result.success(null)
            }

            "flipCamera" -> {
                session?.flipCamera()
                result.success(null)
            }

            "pauseSession" -> {
                session?.pause()
                result.success(null)
            }

            "resumeSession" -> {
                session?.resume()
                result.success(null)
            }

            "capturePhoto" -> {
                session?.capturePhoto { path ->
                    result.success(path)
                }
            }

            "setExposure" -> {
                val ev = call.argument<Double>("ev")?.toFloat() ?: 0f
                session?.setExposure(ev)
                result.success(null)
            }

            "setZoom" -> {
                val zoom = call.argument<Double>("zoom")?.toFloat() ?: 1f
                session?.setZoom(zoom)
                result.success(null)
            }

            "setFlash" -> {
                val mode = call.argument<String>("mode") ?: "off"
                session?.setFlash(mode)
                result.success(null)
            }

            "startRecording" -> {
                session?.startRecording()
                result.success(null)
            }

            "stopRecording" -> {
                session?.stopRecording { path -> result.success(path) }
            }

            "setCompareMode" -> {
                val enable = call.argument<Boolean>("enable") ?: false
                session?.setCompareMode(enable)
                result.success(null)
            }

            // ── 필터 채널 ─────────────────────────────────────────────────────────
            "loadLUT" -> {
                val assetPath = call.argument<String>("assetPath") ?: ""
                bwParams.lutAssetPath = assetPath
                result.success(null)
            }

            "updateParams" -> {
                bwParams.lutIntensity = call.argument<Double>("lutIntensity")?.toFloat() ?: 1f
                bwParams.grain        = call.argument<Double>("grain")?.toFloat() ?: 0f
                bwParams.contrast     = call.argument<Double>("contrast")?.toFloat() ?: 0f
                bwParams.exposure     = call.argument<Double>("exposure")?.toFloat() ?: 0f
                bwParams.lightLeak    = call.argument<Double>("lightLeak")?.toFloat() ?: 0f
                bwParams.vignette     = call.argument<Double>("vignette")?.toFloat() ?: 0.15f
                bwParams.dust         = call.argument<Double>("dust")?.toFloat()  ?: 0f
                bwParams.bloom        = call.argument<Double>("bloom")?.toFloat() ?: 0f
                session?.updateRenderParams(bwParams)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}

/// B&W 렌더링 파라미터
data class BWRenderParams(
    var lutAssetPath: String = "",
    var lutIntensity: Float = 1.0f,
    var grain: Float = 0.0f,
    var contrast: Float = 0.0f,
    var exposure: Float = 0.0f,
    var lightLeak: Float = 0.0f,
    var vignette: Float = 0.15f,
    var dust: Float = 0.0f,
    var bloom: Float = 0.0f,
)

/// MFCameraSession stub — CameraX 전체 구현은 별도 파일
class MFCameraSession {
    fun flipCamera() {}
    fun pause() {}
    fun resume() {}
    fun release() {}
    fun setExposure(ev: Float) {}
    fun setZoom(zoom: Float) {}
    fun setFlash(mode: String) {}
    fun startRecording() {}
    fun stopRecording(callback: (String?) -> Unit) { callback(null) }
    fun setCompareMode(enable: Boolean) {}
    fun capturePhoto(callback: (String?) -> Unit) { callback(null) }
    fun updateRenderParams(params: BWRenderParams) {}
}
