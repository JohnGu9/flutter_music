package com.johngu.flutter_app;

import android.os.Handler;

import io.flutter.plugin.common.MethodChannel;

public final class Constants {
    static MethodChannel AndroidMethodChannel;
    static MethodChannel MediaMetadataRetrieverMethodChannel;
    static MethodChannel MediaPlayerMethodChannel;

    /// Stop all service
    static final String ACTION_STOPSELF = "com.johngu.STOPSELF";

    static Handler mainThreadHandler;

}
