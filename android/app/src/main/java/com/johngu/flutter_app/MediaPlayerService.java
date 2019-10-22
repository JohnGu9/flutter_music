package com.johngu.flutter_app;

import android.annotation.TargetApi;
import android.app.IntentService;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.media.MediaMetadataRetriever;
import android.media.MediaPlayer;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.PowerManager;
import android.util.Log;

import androidx.core.app.NotificationCompat;
import androidx.media.app.NotificationCompat.MediaStyle;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Objects;

import io.flutter.plugin.common.MethodChannel;

import static java.lang.Math.max;

@TargetApi(Build.VERSION_CODES.M)
public final class MediaPlayerService extends IntentService
        implements MediaPlayer.OnPreparedListener,
        MediaPlayer.OnCompletionListener,
        MediaPlayer.OnErrorListener,
        MediaPlayer.OnSeekCompleteListener,
        MediaPlayer.OnBufferingUpdateListener,
        AudioManager.OnAudioFocusChangeListener {

    static public final String ACTION_OnPlay = "com.johngu.onPlay";
    static public final String ACTION_OnPause = "com.johngu.onPause";
    static public final String ACTION_OnPrevious = "com.johngu.onPrevious";
    static public final String ACTION_OnNext = "com.johngu.onNext";
    static public final String ACTION_STOPSELF = "com.johngu.STOPSELF";

    enum State {Idle, Initialized, Preparing, Prepared}

    static private MediaPlayer mediaPlayer;
    static private volatile State state;
    static private AudioManager audioManager;
    static private NotificationManager notificationManager;
    static private AudioAttributes audioAttributes;
    static private AudioFocusRequest audioFocusRequest;
    static private Handler audioFocusRequestHandler;
    static private volatile String currentDataSource;
    static private String title;
    static private String artist;
    static private String album;
    static private float volume;

    private NotificationCompat.Builder notificationPendingBuilder;
    static private Notification notificationPending;
    private NotificationCompat.Builder notificationActingBuilder;
    static private Notification notificationActing;
    static private Bitmap emptyBitmap;

    static private final Runnable onPlayRunnable = () -> Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "started");
    static private final Runnable onPauseRunnable = () -> Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "paused");
    static private final Runnable onPreviousRunnable = () -> Constants.MediaPlayerMethodChannel.invokeMethod("onPrevious", null);
    static private final Runnable onNextRunnable = () -> Constants.MediaPlayerMethodChannel.invokeMethod("onNext", null);
    private final Runnable updateNotificationRunnable = new Runnable() {
        @Override
        public void run() {
            MediaMetadataRetriever mmr = new MediaMetadataRetriever();
            mmr.setDataSource(currentDataSource);
            if (title == null) {
                title = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_TITLE);
            }
            if (artist == null) {
                artist = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ARTIST);
            }
            if (album == null) {
                album = mmr.extractMetadata(MediaMetadataRetriever.METADATA_KEY_ALBUM);
            }

            notificationPendingBuilder.setContentTitle(title);
            notificationPendingBuilder.setContentText(artist);
            notificationPendingBuilder.setSubText(album);

            notificationActingBuilder.setContentTitle(title);
            notificationActingBuilder.setContentText(artist);
            notificationActingBuilder.setSubText(album);

            byte[] artwork = mmr.getEmbeddedPicture();
            if (artwork != null) {
                Bitmap bitmap = BitmapFactory.decodeByteArray(artwork, 0, artwork.length);
                notificationPendingBuilder.setLargeIcon(bitmap);
                notificationActingBuilder.setLargeIcon(bitmap);
                notificationPending = notificationPendingBuilder.build();
                notificationActing = notificationActingBuilder.build();
                bitmap.recycle();
            } else {
                notificationPendingBuilder.setLargeIcon(emptyBitmap);
                notificationActingBuilder.setLargeIcon(emptyBitmap);
                notificationPending = notificationPendingBuilder.build();
                notificationActing = notificationActingBuilder.build();
            }
            synchronized (this) {
                if (mediaPlayer.isPlaying()) {
                    notificationManager.notify(MediaPlayerNotifyID, notificationActing);
                } else {
                    notificationManager.notify(MediaPlayerNotifyID, notificationPending);
                }
            }

        }
    };

    static final String MediaPlayerNotificationChannel_ID = "MediaPlayer";
    static final CharSequence MediaPlayerNotificationChannel_NAME = "Playback";
    static final String MediaPlayerNotificationChannel_DESCRIPTION = "MediaPlayer notification for playback control";
    static final int MediaPlayerNotificationChannel_IMPORTANT = NotificationManager.IMPORTANCE_DEFAULT;
    static final int MediaPlayerNotifyID = 0;

    static public MediaPlayerServiceBinder mediaPlayerServiceBinder;


    public MediaPlayerService() {
        super("MediaPlayerService");
        mediaPlayerServiceBinder = new MediaPlayerServiceBinder();
        audioFocusRequestHandler = new Handler();
        volume = -1;

    }

    @Override
    public void onCreate() {
        super.onCreate();
        MediaPlayerInit();
        NotificationInit();
        Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "idle");
        audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O){
            audioFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(audioAttributes)
                    .setAcceptsDelayedFocusGain(true)
                    .setWillPauseWhenDucked(true)
                    .setOnAudioFocusChangeListener(this, audioFocusRequestHandler)
                    .build();
        }
    }

    @Override
    public void onDestroy() {
        Log.d("MediaPlayer", "onDestroy");
        notificationManager.cancel(MediaPlayerNotifyID);
        mediaPlayer.release();
        mediaPlayer = null;
        Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "end");
        super.onDestroy();
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        notificationManager.cancel(MediaPlayerNotifyID);
        mediaPlayer.release();
        mediaPlayer = null;
        Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "end");
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public final MediaPlayerServiceBinder onBind(Intent intent) {
        return mediaPlayerServiceBinder;
    }

    private int audioFocusRequest() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.abandonAudioFocusRequest(audioFocusRequest);
            return audioManager.requestAudioFocus(audioFocusRequest);
        } else {
            audioManager.abandonAudioFocus(this);
            return audioManager.requestAudioFocus(this, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT);
        }
    }

    public final void MediaPlayerInit() {
        mediaPlayer = new MediaPlayer();
        mediaPlayer.setWakeMode(getApplicationContext(), PowerManager.PARTIAL_WAKE_LOCK);
        mediaPlayer.setOnPreparedListener(this);
        mediaPlayer.setOnCompletionListener(this);
        mediaPlayer.setOnErrorListener(this);
        mediaPlayer.setOnBufferingUpdateListener(this);
        mediaPlayer.setOnSeekCompleteListener(this);
        audioAttributes = new AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setLegacyStreamType(AudioManager.STREAM_MUSIC).build();
        mediaPlayer.setAudioAttributes(audioAttributes);
    }

    private void NotificationInit() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    MediaPlayerNotificationChannel_ID,
                    MediaPlayerNotificationChannel_NAME,
                    MediaPlayerNotificationChannel_IMPORTANT);
            channel.setDescription(MediaPlayerNotificationChannel_DESCRIPTION);
            channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);
            channel.setSound(null, null);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            notificationManager = getSystemService(NotificationManager.class);
            assert notificationManager != null;
            notificationManager.deleteNotificationChannel(MediaPlayerNotificationChannel_ID);
            notificationManager.createNotificationChannel(channel);
        }
        PendingIntent contentIntent = PendingIntent.getActivity(this,
                0,
                new Intent(this, MainActivity.class),
                PendingIntent.FLAG_UPDATE_CURRENT);

        MediaStyle mediaStyle = new MediaStyle().setShowActionsInCompactView(1);
        notificationPendingBuilder = new NotificationCompat.Builder(this, MediaPlayerNotificationChannel_ID)
                .setSmallIcon(R.drawable.ic_stat_name)
                .setContentIntent(contentIntent)
                .setContentTitle("Playback")
                .setSound(null)
                .setOngoing(false)
                .setStyle(mediaStyle)
                .addAction(generateAction(R.drawable.ic_previous, "Previous", MediaPlayerService.ACTION_OnPrevious))
                .addAction(generateAction(R.drawable.ic_play, "Play", MediaPlayerService.ACTION_OnPlay))
                .addAction(generateAction(R.drawable.ic_next, "Next", MediaPlayerService.ACTION_OnNext));

        notificationActingBuilder = new NotificationCompat.Builder(this, MediaPlayerNotificationChannel_ID)
                .setSmallIcon(R.drawable.ic_stat_name)
                .setContentIntent(contentIntent)
                .setContentTitle("Playback")
                .setSound(null)
                .setOngoing(true)
                .setStyle(mediaStyle)
                .addAction(generateAction(R.drawable.ic_previous, "Previous", MediaPlayerService.ACTION_OnPrevious))
                .addAction(generateAction(R.drawable.ic_pause, "Pause", MediaPlayerService.ACTION_OnPause))
                .addAction(generateAction(R.drawable.ic_next, "Next", MediaPlayerService.ACTION_OnNext));

        notificationManager.cancel(MediaPlayerNotifyID);
    }

    private NotificationCompat.Action generateAction(int icon, String title, String intentAction) {
        Intent intent = new Intent(getApplicationContext(), MediaPlayerService.class);
        intent.setAction(intentAction);
        PendingIntent pendingIntent = PendingIntent.getService(getApplicationContext(), 1, intent, PendingIntent.FLAG_UPDATE_CURRENT);
        return new NotificationCompat.Action.Builder(icon, title, pendingIntent).build();
    }

    public class MediaPlayerServiceBinder extends Binder {

        public final void init() {
            if (mediaPlayer == null) {
                MediaPlayerInit();
                Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "idle");
            } else {
                mediaPlayer.reset();
                Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "idle");
            }
        }

        public final void start() {
            onPlay();
        }

        public final void pause() {
            onPause();
        }

        public final void stop() {
            mediaPlayer.stop();
            notificationManager.cancel(MediaPlayerNotifyID);
            Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "stopped");
        }

        public final void reset() {
            mediaPlayer.reset();
            notificationManager.cancel(MediaPlayerNotifyID);
            Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "idle");
        }

        public final void release() {
            notificationManager.cancel(MediaPlayerNotifyID);
            mediaPlayer.release();
            mediaPlayer = null;
            Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "end");
        }

        public final void setDataSource(String path) {
            currentDataSource = path;
            Constants.MediaPlayerMethodChannel.invokeMethod("stateManager", "preparing", new MethodChannel.Result() {
                @Override
                public void success(Object o) {
                    ArrayList<String> res = (ArrayList<String>) o;
                    title = res.get(0);
                    artist = res.get(1);
                    album = res.get(2);
                    Thread thread = new Thread(updateNotificationRunnable);
                    thread.setPriority(Thread.MIN_PRIORITY);
                    thread.start();
                }

                @Override
                public void error(String s, String s1, Object o) {
                    album = artist = title = null;
                    Thread thread = new Thread(updateNotificationRunnable);
                    thread.setPriority(Thread.MIN_PRIORITY);
                    thread.start();
                }

                @Override
                public void notImplemented() {
                    album = artist = title = null;
                    Thread thread = new Thread(updateNotificationRunnable);
                    thread.setPriority(Thread.MIN_PRIORITY);
                    thread.start();
                }
            });
            Thread prepareThread = new Thread(new SetDataSourceRunnable(path));
            prepareThread.setPriority(Thread.MIN_PRIORITY);
            prepareThread.start();
        }

        public final int getCurrentPosition() {
            return mediaPlayer.getCurrentPosition();
        }

        public final int getDuration() {
            return mediaPlayer.getDuration();
        }

        public final boolean isPlaying() {
            return mediaPlayer.isPlaying();
        }

        public final void setLooping(boolean looping) {
            mediaPlayer.setLooping(looping);
        }

        public final boolean isLooping() {
            return mediaPlayer.isLooping();
        }

        public final void seekTo(int position) {
            mediaPlayer.seekTo(position);
        }

        public final void setVolume(float val) {
            volume = val;
            mediaPlayer.setVolume(volume, volume);
        }
    }

    class SetDataSourceRunnable implements Runnable {
        final String path;

        public SetDataSourceRunnable(String path) {
            this.path = path;
        }

        @Override
        public void run() {
            synchronized (this) {
                if (state != State.Idle && path == currentDataSource) {
                    mediaPlayer.reset();
                    state = State.Idle;
                } else if (path != currentDataSource) {
                    return;
                }
            }

            synchronized (this) {
                if (state == State.Idle && path == currentDataSource) {
                    try {
                        mediaPlayer.setDataSource(currentDataSource);
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                    state = State.Initialized;
                } else {
                    return;
                }
            }

            synchronized (this) {
                if (state == State.Initialized && path == currentDataSource) {
                    state = State.Preparing;
                    mediaPlayer.prepareAsync();
                }
            }
        }
    }

    private void onPlay() {
        if (state == State.Prepared) {
            int res = audioFocusRequest();
            if (res != AudioManager.AUDIOFOCUS_REQUEST_FAILED) {
                mediaPlayer.start();
                notificationManager.notify(MediaPlayerNotifyID, notificationActing);
            }
            Constants.mainThreadHandler.post(onPlayRunnable);
        }
    }

    private void onPause() {
        mediaPlayer.pause();
        Constants.mainThreadHandler.post(onPauseRunnable);
        notificationManager.notify(MediaPlayerNotifyID, notificationPending);
    }

    private void onPrevious() {
        Log.d("IntentService", "onPrevious");
        Constants.mainThreadHandler.post(onPreviousRunnable);
    }

    private void onNext() {
        Log.d("IntentService", "onNext");
        Constants.mainThreadHandler.post(onNextRunnable);
    }

    @Override
    protected void onHandleIntent(Intent intent) {
        switch (Objects.requireNonNull(intent.getAction())) {
            case ACTION_OnPlay:
                onPlay();
                break;
            case ACTION_OnPause:
                onPause();
                break;
            case ACTION_OnPrevious:
                onPrevious();
                break;
            case ACTION_OnNext:
                onNext();
                break;
            case ACTION_STOPSELF:
                stopSelf();
            default:
        }
    }

    @Override
    public final void onPrepared(MediaPlayer mediaPlayer) {
        state = State.Prepared;
        Constants.MediaPlayerMethodChannel.invokeMethod(
                "onPreparedListener",
                // onPrepared will return duration
                mediaPlayer.getDuration(),
                new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                        Log.d("Dart onPrepared", "error");
                        Log.d(s, s1);
                    }

                    @Override
                    public void notImplemented() {
                        Log.d("Dart onPrepared", "notImplemented");
                    }
                });
    }

    @Override
    public final void onCompletion(MediaPlayer mediaPlayer) {
        Constants.MediaPlayerMethodChannel.invokeMethod(
                "onCompletionListener",
                null,
                new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                        Log.d("Dart onCompletion", "error");
                        Log.d(s, s1);
                    }

                    @Override
                    public void notImplemented() {
                        Log.d("Dart onCompletion", "notImplemented");
                    }
                });
    }

    @Override
    public final boolean onError(MediaPlayer mediaPlayer, int what, int extra) {
        Constants.MediaPlayerMethodChannel.invokeMethod(
                "onErrorListener",
                new int[]{what, extra},
                new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                        Log.d("Dart onError", "error");
                        Log.d(s, s1);
                    }

                    @Override
                    public void notImplemented() {
                        Log.d("Dart onError", "notImplemented");
                    }
                });
        return false;
    }

    @Override
    public final void onSeekComplete(MediaPlayer mediaPlayer) {
        Constants.MediaPlayerMethodChannel.invokeMethod(
                "onSeekCompleteListener",
                mediaPlayer.getCurrentPosition(),
                new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                        Log.d("Dart OnSeekComplete", "error");
                        Log.d(s, s1);
                    }

                    @Override
                    public void notImplemented() {
                        Log.d("Dart onSeekComplete", "notImplemented");
                    }
                });
    }

    @Override
    public final void onBufferingUpdate(MediaPlayer mediaPlayer, int i) {
        Constants.MediaPlayerMethodChannel.invokeMethod(
                "onBufferingUpdateListener",
                i,
                new MethodChannel.Result() {
                    @Override
                    public void success(Object o) {
                    }

                    @Override
                    public void error(String s, String s1, Object o) {
                        Log.d("Dart onBufferingUpdate", "error");
                        Log.d(s, s1);
                    }

                    @Override
                    public void notImplemented() {
                        Log.d("Dart onBufferingUpdate", "notImplemented");
                    }
                });
    }

    private boolean isPlayingBeforeLossFocus;

    @Override
    public void onAudioFocusChange(int focusChange) {
        switch (focusChange) {
            case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
            case AudioManager.AUDIOFOCUS_LOSS:
                if (mediaPlayer != null && mediaPlayer.isPlaying()) {
                    isPlayingBeforeLossFocus = true;
                } else {
                    isPlayingBeforeLossFocus = false;
                }
                onPause();
                break;

            case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
                mediaPlayer.setVolume((float) max(volume - 0.2, 0.0), (float) max(volume - 0.2, 0.0));
                break;

            case AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE:
            case AudioManager.AUDIOFOCUS_GAIN_TRANSIENT:
            case AudioManager.AUDIOFOCUS_GAIN:
                Log.d("AUDIOFOCUS_GAIN: ", "focusChange");
                if (volume >= 0) {
                    mediaPlayer.setVolume(volume, volume);
                }
                if (!mediaPlayer.isPlaying() && isPlayingBeforeLossFocus) {
                    onPlay();
                }
                break;
        }
    }
}

