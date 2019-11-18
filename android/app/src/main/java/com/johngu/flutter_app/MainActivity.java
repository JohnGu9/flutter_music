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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.Set;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

    static Intent mediaPlayerServiceIntent;
    static MediaPlayerService.MediaPlayerServiceBinder mediaPlayerServiceBinder;
    static ServiceConnection mediaPlayerServiceConnection;

    static final Bitmap.CompressFormat BitmapCompressFormat = Bitmap.CompressFormat.JPEG;

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

                        case "SaveByteAsJpeg":
                            Thread thread = new Thread(new Runnable() {
                                String filePath = methodCall.argument("filePath");
                                byte[] bytes = methodCall.argument("bytes");

                                @Override
                                public void run() {
                                    File file = new File(filePath);
                                    if (file.exists()) {
                                        file.delete();
                                    }
                                    Bitmap bm = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                                    try {
                                        FileOutputStream out = new FileOutputStream(file);
                                        bm.compress(BitmapCompressFormat, 100, out);
                                        out.flush();
                                        out.close();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                    bm.recycle();
                                    Log.d("Jpeg", filePath);
                                }
                            });
                            thread.setPriority(Thread.MIN_PRIORITY);
                            thread.start();
                            result.success(null);
                            break;

                        case "ReadJpegAsByte":
                            String filePath = methodCall.argument("filePath");
                            Bitmap bitmap = BitmapFactory.decodeFile(filePath);
                            ByteArrayOutputStream stream = new ByteArrayOutputStream();
                            bitmap.compress(BitmapCompressFormat, 100, stream);
                            result.success(stream.toByteArray());
                            bitmap.recycle();
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

                            Thread thread = new Thread(() -> {
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
                                    Constants.mainThreadHandler.post(() -> Constants.MediaMetadataRetrieverMethodChannel.invokeMethod("Palette", list));
                                    bitmap.recycle();
                                }
                            });
                            thread.setPriority(Thread.MIN_PRIORITY);
                            thread.start();


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
                            thread = new Thread(new Runnable() {
                                // flutter have more accurate parser
                                String artist = methodCall.argument("artist");
                                String title = methodCall.argument("title");
                                String album = methodCall.argument("album");

                                @Override
                                public void run() {
                                    Set<String> ids = RemoteMediaMetadataRetriever.getMBID(artist, album, title);
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
                            thread = new Thread(() -> {
                                Bitmap bitmap = BitmapFactory.decodeByteArray(artwork, 0, artwork.length);

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
                            result.success(null);
                            break;

                        case "cancelNotification":
                            mediaPlayerServiceBinder.cancelNotification();
                            result.success(null);
                            break;

                        case "notificationSwitch":
                            mediaPlayerServiceBinder.notificationSwitch(methodCall.argument("value"));
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
