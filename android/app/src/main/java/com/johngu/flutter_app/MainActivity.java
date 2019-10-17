package com.johngu.flutter_app;

import android.annotation.TargetApi;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.media.MediaMetadataRetriever;
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import java.io.IOException;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

    static MethodChannel AndroidCHANNEL;
    static MethodChannel MediaMetadataRetrieverCHANNEL;
    static MethodChannel MediaPlayerCHANNEL;

    static Intent MediaPlayerServiceIntent;
    static MediaPlayerService.MediaPlayerServiceBinder MediaPlayerServiceBinder;
    static ServiceConnection MediaPlayerServiceConnection;

    static String CHANNEL_ID = "MediaPlayer";
    private void createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

            CharSequence name = "MediaPlayer";
            String description = "MediaPlayer Notification Control";
            int importance = NotificationManager.IMPORTANCE_DEFAULT;
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, name, importance);
            channel.setDescription(description);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        createNotificationChannel();
        NotificationManager notificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        Intent notificationIntent = new Intent(this, MainActivity.class);
        PendingIntent contentIntent =
                PendingIntent.getActivity(this, 0, notificationIntent, PendingIntent.FLAG_UPDATE_CURRENT);
        Notification.Builder builder =
                new Notification.Builder(this)
                        .setSmallIcon(android.R.drawable.ic_media_play)
                        .setContentIntent(contentIntent)
                        .setContentTitle("Media")
                        .setStyle(new Notification.MediaStyle());
        builder.addAction(
                new Notification.Action.Builder(android.R.drawable.ic_media_play, "Play", contentIntent)
                        .build());

        AndroidCHANNEL = new MethodChannel(getFlutterView(), "Android");
        AndroidCHANNEL.setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {

                    @TargetApi(Build.VERSION_CODES.M)
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
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
                                notificationManager.notify(1, builder.build());
                                break;

                            default:
                                result.notImplemented();
                        }
                    }
                });

        MediaMetadataRetrieverCHANNEL = new MethodChannel(getFlutterView(), "MediaMetadataRetriever");
        MediaMetadataRetrieverCHANNEL.setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    MediaMetadataRetriever mmr;

                    @SuppressWarnings("NullableProblems")
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        switch (methodCall.method) {
                            case "getEmbeddedPicture":
                                mmr = new MediaMetadataRetriever();
                                mmr.setDataSource((String) methodCall.argument("path"));
                                result.success(mmr.getEmbeddedPicture());
                                mmr.release();
                                break;

                            default:
                                result.notImplemented();
                        }
                    }
                });

        // setup MethodChannel
        MediaPlayerCHANNEL = new MethodChannel(getFlutterView(), "flutter.io/MediaPlayer");
        MediaPlayerCHANNEL.setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {

                    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
                    @Override
                    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
                        // Note: this method is invoked on the main thread.
                        // TODO
                        switch (call.method) {
                            case "Java":
                            case "java":
                                Log.d("Dart invoke method", "Java is available");
                                result.success(null);
                                break;

                            case "init":
                                MediaPlayerServiceBinder.init();
                                result.success(null);
                                break;
                            case "release":
                                MediaPlayerServiceBinder.release();
                                result.success(null);
                                break;

                            case "reset":
                                MediaPlayerServiceBinder.reset();
                                result.success(null);
                                break;

                            case "isAvailable":
                                result.success(MediaPlayerServiceBinder.isBinderAlive());
                                break;

                            case "play":
                            case "start":
                                MediaPlayerServiceBinder.start();
                                result.success(null);
                                break;

                            case "isPlaying":
                                result.success(MediaPlayerServiceBinder.isPlaying());
                                break;

                            case "stop":
                                MediaPlayerServiceBinder.stop();
                                result.success(null);
                                break;

                            case "pause":
                                MediaPlayerServiceBinder.pause();
                                result.success(null);
                                break;

                            case "setDataSource":
                                String url = call.argument("path");
                                try {
                                    MediaPlayerServiceBinder.setDataSource(url);
                                    result.success(true);
                                } catch (IOException e) {
                                    result.error(
                                            "MediaPlayer failed to setDataSource",
                                            "Java Exception" + e.getMessage(),
                                            null);
                                    result.success(false);
                                }

                                break;

                            case "getCurrentPosition":
                                result.success(MediaPlayerServiceBinder.getCurrentPosition());
                                break;

                            case "getDuration":
                                result.success(MediaPlayerServiceBinder.getDuration());
                                break;

                            case "seekTo":
                                MediaPlayerServiceBinder.seekTo(call.argument("position"));
                                result.success(null);
                                break;

                            case "setLooping":
                                MediaPlayerServiceBinder.setLooping(call.argument("loop"));
                                result.success(null);
                                break;

                            case "isLooping":
                                result.success(MediaPlayerServiceBinder.isLooping());
                                break;

                            case "setVolume":
                                double _v = call.argument("volume");
                                float volume = (float) _v;
                                MediaPlayerServiceBinder.setVolume(volume);
                                result.success(null);
                                break;

                            default:
                                result.notImplemented();
                        }
                    }
                });

        // setup intent
        MediaPlayerServiceConnection =
                new ServiceConnection() {
                    @Override
                    public void onServiceConnected(ComponentName name, IBinder service) {
                        MediaPlayerServiceBinder = (MediaPlayerService.MediaPlayerServiceBinder) service;
                    }

                    @Override
                    public void onServiceDisconnected(ComponentName name) {
                        Log.d("MediaPlayerService", "onServiceDisconnected");
                    }
                };
        MediaPlayerServiceIntent = new Intent(this, MediaPlayerService.class);
        bindService(MediaPlayerServiceIntent, MediaPlayerServiceConnection, BIND_AUTO_CREATE);
    }

    @Override
    protected void onDestroy() {
        MediaPlayerServiceBinder.release();
        unbindService(MediaPlayerServiceConnection);
        super.onDestroy();
    }
}
