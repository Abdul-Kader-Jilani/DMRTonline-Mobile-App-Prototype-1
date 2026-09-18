package com.dmrt.dmrt_online

import android.annotation.SuppressLint
import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.view.View
import android.webkit.CookieManager
import android.webkit.WebChromeClient
import android.webkit.PermissionRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.ValueCallback
import androidx.core.content.FileProvider
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File

internal object DmrtWebViewBackBridge {
    private const val FILE_CHOOSER_REQUEST = 7001
    private const val CAMERA_PERMISSION_REQUEST = 7002
    private var currentWebView: WebView? = null
    private var filePathCallback: ValueCallback<Array<Uri>>? = null
    private var cameraImageUri: Uri? = null
    private var pendingPermissionRequest: PermissionRequest? = null

    fun attach(webView: WebView) {
        currentWebView = webView
    }

    fun detach(webView: WebView) {
        if (currentWebView === webView) {
            currentWebView = null
        }
    }

    fun handleBack(fallback: () -> Unit): Boolean {
        val webView = currentWebView ?: return false
        webView.post {
            webView.evaluateJavascript(
                "(function(){return !!(window.dmrtHandleAndroidBack && window.dmrtHandleAndroidBack());})()"
            ) { result ->
                if (result != "true") {
                    fallback()
                }
            }
        }
        return true
    }

    fun openFileChooser(
        activity: Activity,
        callback: ValueCallback<Array<Uri>>,
        params: WebChromeClient.FileChooserParams
    ): Boolean {
        filePathCallback?.onReceiveValue(null)
        filePathCallback = callback

        val acceptImage = params.acceptTypes.any { it.contains("image") } || params.acceptTypes.isEmpty()
        val cameraIntent = if (acceptImage) createCameraIntent(activity) else null

        if (params.isCaptureEnabled && cameraIntent != null) {
            activity.startActivityForResult(cameraIntent, FILE_CHOOSER_REQUEST)
            return true
        }

        val contentIntent = try {
            params.createIntent()
        } catch (_: Exception) {
            Intent(Intent.ACTION_GET_CONTENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "image/*"
            }
        }

        val chooserIntent = Intent(Intent.ACTION_CHOOSER).apply {
            putExtra(Intent.EXTRA_INTENT, contentIntent)
            putExtra(Intent.EXTRA_TITLE, "Select profile photo")
            if (cameraIntent != null) {
                putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(cameraIntent))
            }
        }

        return try {
            activity.startActivityForResult(chooserIntent, FILE_CHOOSER_REQUEST)
            true
        } catch (_: Exception) {
            filePathCallback?.onReceiveValue(null)
            filePathCallback = null
            false
        }
    }

    private fun createCameraIntent(activity: Activity): Intent? {
        val photoFile = File(activity.cacheDir, "dmrt_profile_${System.currentTimeMillis()}.jpg")
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.fileprovider", photoFile)
        cameraImageUri = uri

        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            putExtra(MediaStore.EXTRA_OUTPUT, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }

        activity.packageManager.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY).forEach {
            activity.grantUriPermission(
                it.activityInfo.packageName,
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        }

        return if (intent.resolveActivity(activity.packageManager) != null) intent else null
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != FILE_CHOOSER_REQUEST) return false

        val callback = filePathCallback
        filePathCallback = null

        val results = if (resultCode == Activity.RESULT_OK) {
            when {
                data?.data != null || data?.clipData != null -> WebChromeClient.FileChooserParams.parseResult(resultCode, data)
                cameraImageUri != null -> arrayOf(cameraImageUri!!)
                else -> null
            }
        } else {
            null
        }

        callback?.onReceiveValue(results)
        cameraImageUri = null
        return true
    }

    fun handlePermissionRequest(activity: Activity, request: PermissionRequest) {
        val wantsCamera = request.resources.any { it == PermissionRequest.RESOURCE_VIDEO_CAPTURE }
        if (!wantsCamera || Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            request.grant(request.resources)
            return
        }

        if (activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            request.grant(request.resources)
        } else {
            pendingPermissionRequest = request
            activity.requestPermissions(arrayOf(Manifest.permission.CAMERA), CAMERA_PERMISSION_REQUEST)
        }
    }

    fun onRequestPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != CAMERA_PERMISSION_REQUEST) return false

        val request = pendingPermissionRequest
        pendingPermissionRequest = null

        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            request?.grant(request.resources)
        } else {
            request?.deny()
        }
        return true
    }
}

class DmrtWebViewFactory(private val activity: Activity) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return DmrtWebView(context, activity)
    }
}

private class DmrtWebView(context: Context, private val activity: Activity) : PlatformView {
    private val webView: WebView = WebView(context)

    init {
        configureWebView()
        DmrtWebViewBackBridge.attach(webView)
        webView.loadUrl("file:///android_asset/flutter_assets/assets/index.html")
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configureWebView() {
        CookieManager.getInstance().setAcceptCookie(true)

        webView.webViewClient = WebViewClient()
        webView.webChromeClient = object : WebChromeClient() {
            override fun onShowFileChooser(
                webView: WebView?,
                filePathCallback: ValueCallback<Array<Uri>>,
                fileChooserParams: FileChooserParams
            ): Boolean {
                return DmrtWebViewBackBridge.openFileChooser(activity, filePathCallback, fileChooserParams)
            }

            override fun onPermissionRequest(request: PermissionRequest) {
                activity.runOnUiThread {
                    DmrtWebViewBackBridge.handlePermissionRequest(activity, request)
                }
            }
        }
        webView.isVerticalScrollBarEnabled = false
        webView.isHorizontalScrollBarEnabled = false
        webView.overScrollMode = View.OVER_SCROLL_NEVER

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            loadsImagesAutomatically = true
            mediaPlaybackRequiresUserGesture = false
            cacheMode = WebSettings.LOAD_DEFAULT
            mixedContentMode = WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
            useWideViewPort = true
            loadWithOverviewMode = true
            builtInZoomControls = false
            displayZoomControls = false
            textZoom = 100
        }
    }

    override fun getView(): View = webView

    override fun dispose() {
        DmrtWebViewBackBridge.detach(webView)
        webView.stopLoading()
        webView.destroy()
    }
}
