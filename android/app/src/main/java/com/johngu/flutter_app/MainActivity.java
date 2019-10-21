package com.johngu.flutter_app;

import android.annotation.TargetApi;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;

import androidx.palette.graphics.Palette;

import java.io.IOException;
import java.util.ArrayList;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

    static Intent mediaPlayerServiceIntent;
    static MediaPlayerService.MediaPlayerServiceBinder mediaPlayerServiceBinder;
    static ServiceConnection mediaPlayerServiceConnection;

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        Constants.mainThreadHandler = new Handler();

        Constants.AndroidMethodChannel = new MethodChannel(getFlutterView(), "Android");
        Constants.AndroidMethodChannel.setMethodCallHandler(
                (methodCall, result) -> {
                    switch (methodCall.method) {
                        case "Java":
                        case "java":
                            String text = "Java is available";
                            Log.d(text + "\n", null);
                            result.success(null);
                            break;

                        case "moveTaskToBack":
                            moveTaskToBack(true);
                            result.success(null);
                            break;

                        case "notification":
                            break;

                        default:
                            result.notImplemented();
                    }
                });

        Constants.MediaMetadataRetrieverMethodChannel = new MethodChannel(getFlutterView(), "MMR");
        Constants.MediaMetadataRetrieverMethodChannel.setMethodCallHandler(
                (methodCall, result) -> {
                    MediaMetadataRetriever mmr;
                    String path = (String) methodCall.argument("path");

                    switch (methodCall.method) {
                        case "getEmbeddedPicture":
                            mmr = new MediaMetadataRetriever();
                            mmr.setDataSource(path);
                            byte[] res = mmr.getEmbeddedPicture();
                            result.success(res);
                            mmr.release();

                            // Addition Function: Get Palette
                            // Get Palette (Full Async) run on background
                            if (methodCall.argument("palette")) {
                                if (res == null) {
                                    ArrayList list = new ArrayList<Object>();
                                    list.add(path);
                                    Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("Palette", list);
                                } else {
                                    Bitmap bitmap = BitmapFactory.decodeByteArray(res, 0, res.length);
                                    Thread thread = new Thread(() -> {
                                        Palette palette = new Palette.Builder(bitmap).generate();
                                        Palette.Swatch d = palette.getDominantSwatch();
                                        Palette.Swatch v = palette.getVibrantSwatch();
                                        Palette.Swatch m = palette.getMutedSwatch();
//                                                Log.d("getDominantSwatch", d.toString());
//                                                Log.d("getVibrantSwatch", v.toString());
//                                                Log.d("getVibrantSwatch", m.toString());
                                        ArrayList list = new ArrayList<Object>();
                                        list.add(path);
                                        list.add(d.getRgb());
                                        list.add(v.getRgb());
                                        list.add(m.getRgb());
                                        Constants.mainThreadHandler.post(() -> Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("Palette", list, new MethodChannel.Result() {
                                            @Override
                                            public void success(Object o) {

                                            }

                                            @Override
                                            public void error(String s, String s1, Object o) {
                                                Log.d(s, s1);
                                            }

                                            @Override
                                            public void notImplemented() {
                                                Log.d("MMR", "notImplemented");
                                            }
                                        }));
                                    });
                                    thread.setPriority(Thread.MIN_PRIORITY);
                                    thread.start();
                                }
                            }
                            break;
                        case "getBasicInfo":
                            mmr = new MediaMetadataRetriever();
                            mmr.setDataSource(path);
                            ArrayList<String> infoList = new ArrayList<String>();
                            infoList.add(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE));
                            infoList.add(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST));
                            infoList.add(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM));
                            result.success(infoList);
                            mmr.release();
                            break;
                        default:
                            result.notImplemented();
                    }
                });

        // setup MethodChannel
        Constants.MediaPlayerMethodChannel = new MethodChannel(getFlutterView(), "MP");
        Constants.MediaPlayerMethodChannel.setMethodCallHandler(
                (methodCall, result) -> {
                    // Note: this method is invoked on the main thread.
                    // TODO
                    switch (methodCall.method) {
                        case "Java":
                        case "java":
                            Log.d("Dart invoke method", "Java is available");
                            result.success(null);
                            break;

                        case "init":
                            mediaPlayerServiceBinder.init();
                            result.success(null);
                            break;
                        case "release":
                            mediaPlayerServiceBinder.release();
                            result.success(null);
                            break;

                        case "reset":
                            mediaPlayerServiceBinder.reset();
                            result.success(null);
                            break;

                        case "isAvailable":
                            result.success(mediaPlayerServiceBinder.isBinderAlive());
                            break;

                        case "play":
                        case "start":
                            mediaPlayerServiceBinder.start();
                            result.success(null);
                            break;

                        case "isPlaying":
                            result.success(mediaPlayerServiceBinder.isPlaying());
                            break;

                        case "stop":
                            mediaPlayerServiceBinder.stop();
                            result.success(null);
                            break;

                        case "pause":
                            mediaPlayerServiceBinder.pause();
                            result.success(null);
                            break;

                        case "setDataSource":
                            String url = methodCall.argument("path");
                            try {
                                mediaPlayerServiceBinder.setDataSource(url);
                                result.success(true);
                            } catch (IOException e) {
                                result.error(
                                        "MediaPlayer failed to setDataSource",
                                        "Java Exception" + e.getMessage(),
                                        null);
                            }

                            break;

                        case "getCurrentPosition":
                            result.success(mediaPlayerServiceBinder.getCurrentPosition());
                            break;

                        case "getDuration":
                            result.success(mediaPlayerServiceBinder.getDuration());
                            break;

                        case "seekTo":
                            mediaPlayerServiceBinder.seekTo(methodCall.argument("position"));
                            result.success(null);
                            break;

                        case "setLooping":
                            mediaPlayerServiceBinder.setLooping(methodCall.argument("loop"));
                            result.success(null);
                            break;

                        case "isLooping":
                            result.success(mediaPlayerServiceBinder.isLooping());
                            break;

                        case "setVolume":
                            double volume = methodCall.argument("volume");
                            mediaPlayerServiceBinder.setVolume((float) volume);
                            result.success(null);
                            break;

                        default:
                            result.notImplemented();
                    }
                });


        // Init Service
        mediaPlayerServiceConnection = new ServiceConnection() {
            @Override
            public final void onServiceConnected(ComponentName name, IBinder service) {
                mediaPlayerServiceBinder = (MediaPlayerService.MediaPlayerServiceBinder) service;
            }

            @Override
            public final void onServiceDisconnected(ComponentName name) {
                Log.d("MediaPlayerService", "onServiceDisconnected");
            }
        };
        mediaPlayerServiceIntent = new Intent(this, MediaPlayerService.class);
        bindService(mediaPlayerServiceIntent, mediaPlayerServiceConnection, BIND_AUTO_CREATE);

    }

    @Override
    protected void onDestroy() {
        Log.d("MainActivity", "onDestroy");
        mediaPlayerServiceBinder.release();
        unbindService(mediaPlayerServiceConnection);
        startActivity(new Intent(MediaPlayerService.ACTION_STOPSELF));
        super.onDestroy();
    }


}
