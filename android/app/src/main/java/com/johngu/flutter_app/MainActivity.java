package com.johngu.flutter_app;

import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadataRetriever;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.util.Log;

import androidx.palette.graphics.Palette;

import com.android.volley.toolbox.Volley;

import java.util.ArrayList;
import java.util.Set;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

    static Intent mediaPlayerServiceIntent;
    static MediaPlayerService.MediaPlayerServiceBinder mediaPlayerServiceBinder;
    static ServiceConnection mediaPlayerServiceConnection;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        RemoteMediaMetadataRetriever.queue = Volley.newRequestQueue(this);
        Constants.mainThreadHandler = new Handler();

        Constants.AndroidMethodChannel = new MethodChannel(getFlutterView(), "Android");
        Constants.AndroidMethodChannel.setMethodCallHandler(
                (methodCall, result) -> {
                    switch (methodCall.method) {
                        case "Java":
                        case "java":
                            Log.d("AndroidMethodChannel", "Java is available");
                            result.success(null);
                            break;

                        case "moveTaskToBack":
                            moveTaskToBack(true);
                            result.success(null);
                            break;

                        case "test":
                            result.success(null);
                            break;

                        default:
                            result.notImplemented();
                    }
                });

        Constants.MediaMetadataRetrieverMethodChannel = new MethodChannel(getFlutterView(), "MMR");
        Constants.MediaMetadataRetrieverMethodChannel.setMethodCallHandler(
                (methodCall, result) -> {
                    MediaMetadataRetriever mmr;
                    String filePath = (String) methodCall.argument("filePath");

                    switch (methodCall.method) {
                        case "getEmbeddedPicture":
                            mmr = new MediaMetadataRetriever();
                            mmr.setDataSource(filePath);
                            byte[] res = mmr.getEmbeddedPicture();
                            result.success(res);
                            mmr.release();

                            // Addition Function: Get Palette
                            // Get Palette (Full Async) run on background

                            if (res != null) {
                                Bitmap bitmap = BitmapFactory.decodeByteArray(res, 0, res.length);
                                Thread thread = new Thread(() -> {
                                    Palette palette = new Palette.Builder(bitmap).generate();
                                    ArrayList list = new ArrayList<Object>() {{
                                        add(filePath);
                                        add(palette.getDominantSwatch() != null ? palette.getDominantSwatch().getRgb() : null);
                                        add(palette.getVibrantSwatch() != null ? palette.getVibrantSwatch().getRgb() : null);
                                        add(palette.getMutedSwatch() != null ? palette.getMutedSwatch().getRgb() : null);
                                        add(palette.getLightVibrantSwatch() == null ? null : palette.getLightVibrantSwatch().getRgb());
                                        add(palette.getLightMutedSwatch() == null ? null : palette.getLightMutedSwatch().getRgb());
                                        add(palette.getDarkVibrantSwatch() == null ? null : palette.getDarkVibrantSwatch().getRgb());
                                        add(palette.getDarkMutedSwatch() == null ? null : palette.getDarkMutedSwatch().getRgb());
                                    }};
                                    Constants.mainThreadHandler.post(() -> Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("Palette", list));
                                    bitmap.recycle();
                                });
                                thread.setPriority(Thread.MIN_PRIORITY);
                                thread.start();
                            }

                            break;

                        case "getBasicInfo":
                            mmr = new MediaMetadataRetriever();
                            mmr.setDataSource(filePath);
                            ArrayList<String> infoList = new ArrayList<String>();
                            infoList.add(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE));
                            infoList.add(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST));
                            infoList.add(mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM));
                            result.success(infoList);
                            mmr.release();
                            break;

                        case "getRemotePicture":
                            Thread thread = new Thread(new Runnable() {
                                // flutter have more accurate parser
                                String artist = methodCall.argument("artist");
                                String title = methodCall.argument("title");
                                final String duration = methodCall.argument("duration");

                                @Override
                                public void run() {
                                    if (artist.equals(MediaPlayerService.unknown)) {
                                        artist = null;
                                    }
                                    if (title.equals(MediaPlayerService.unknown)) {
                                        title = null;
                                    }
                                    Set<String> ids = RemoteMediaMetadataRetriever.getMBID(artist, title, duration);
                                    byte[] res = RemoteMediaMetadataRetriever.getArtwork(ids);
                                    final ArrayList<Object> result = new ArrayList<Object>() {{
                                        add(filePath);
                                        add(res);
                                    }};
                                    // return Artwork
                                    Constants.mainThreadHandler.post(() -> Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("getRemotePicture", result));

                                    // Addition Function: Get Palette
                                    // Get Palette (Full Async) run on background
                                    if (res != null) {
                                        Bitmap bitmap = BitmapFactory.decodeByteArray(res, 0, res.length);
                                        Palette palette = new Palette.Builder(bitmap).generate();
                                        ArrayList list = new ArrayList<Object>() {{
                                            add(filePath);
                                            add(palette.getDominantSwatch() != null ? palette.getDominantSwatch().getRgb() : null);
                                            add(palette.getVibrantSwatch() != null ? palette.getVibrantSwatch().getRgb() : null);
                                            add(palette.getMutedSwatch() != null ? palette.getMutedSwatch().getRgb() : null);
                                            add(palette.getLightVibrantSwatch() == null ? null : palette.getLightVibrantSwatch().getRgb());
                                            add(palette.getLightMutedSwatch() == null ? null : palette.getLightMutedSwatch().getRgb());
                                            add(palette.getDarkVibrantSwatch() == null ? null : palette.getDarkVibrantSwatch().getRgb());
                                            add(palette.getDarkMutedSwatch() == null ? null : palette.getDarkMutedSwatch().getRgb());
                                        }};
                                        // return Palette
                                        Constants.mainThreadHandler.post(() -> Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("Palette", list));
                                        bitmap.recycle();
                                    }
                                }
                            });
                            thread.setPriority(Thread.MIN_PRIORITY + 1);
                            thread.start();
                            result.success(null);

                            break;

                        case "getPalette":
                            byte[] artwork = methodCall.argument("artwork");
                            Bitmap bitmap = BitmapFactory.decodeByteArray(artwork, 0, artwork.length);
                            Thread thread0 = new Thread(new Runnable() {

                                @Override
                                public void run() {
                                    Palette palette = new Palette.Builder(bitmap).generate();
                                    ArrayList list = new ArrayList<Object>() {{
                                        add(filePath);
                                        add(palette.getDominantSwatch() != null ? palette.getDominantSwatch().getRgb() : null);
                                        add(palette.getVibrantSwatch() != null ? palette.getVibrantSwatch().getRgb() : null);
                                        add(palette.getMutedSwatch() != null ? palette.getMutedSwatch().getRgb() : null);
                                        add(palette.getLightVibrantSwatch() == null ? null : palette.getLightVibrantSwatch().getRgb());
                                        add(palette.getLightMutedSwatch() == null ? null : palette.getLightMutedSwatch().getRgb());
                                        add(palette.getDarkVibrantSwatch() == null ? null : palette.getDarkVibrantSwatch().getRgb());
                                        add(palette.getDarkMutedSwatch() == null ? null : palette.getDarkMutedSwatch().getRgb());
                                    }};
                                    Constants.mainThreadHandler.post(() -> Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("Palette", list));
                                    bitmap.recycle();
                                }
                            });
                            thread0.setPriority(Thread.MIN_PRIORITY);
                            thread0.start();
                            result.success(null);
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
                            mediaPlayerServiceBinder.setDataSource(url);
                            result.success(true);
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

                        case "updateNotification":
                            mediaPlayerServiceBinder.updateNotification(methodCall.argument("title"), methodCall.argument("artist"), methodCall.argument("album"), methodCall.argument("artwork"));
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
                mediaPlayerServiceBinder = null;
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
        startActivity(new Intent(Constants.ACTION_STOPSELF));
        super.onDestroy();
    }

}
