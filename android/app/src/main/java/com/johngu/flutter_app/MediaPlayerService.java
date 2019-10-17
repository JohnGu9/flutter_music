package com.johngu.flutter_app;

import android.annotation.TargetApi;
import android.app.Service;
import android.content.Intent;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.session.MediaSession;
import android.media.session.MediaSessionManager;
import android.os.Binder;
import android.os.Build;
import android.os.PowerManager;
import android.util.Log;

import java.io.IOException;

import io.flutter.plugin.common.MethodChannel;

import static java.lang.Math.max;

public final class MediaPlayerService extends Service
    implements MediaPlayer.OnPreparedListener,
        MediaPlayer.OnCompletionListener,
        MediaPlayer.OnErrorListener,
        MediaPlayer.OnSeekCompleteListener,
        MediaPlayer.OnBufferingUpdateListener {

  private MediaPlayer mediaPlayer;
  private AudioManager audioManager;
  public MediaPlayerServiceBinder mediaPlayerServiceBinder;
  private MediaSessionManager mediaSessionManager;
  private MediaSession mediaSession;
  private AudioManager.OnAudioFocusChangeListener onAudioFocusChangeListener;
  private float volume;

  public MediaPlayerService() {}

  @TargetApi(Build.VERSION_CODES.LOLLIPOP)
  public final void MediaPlayerInit() {
    mediaPlayer = new MediaPlayer();
    mediaPlayer.setWakeMode(getApplicationContext(), PowerManager.PARTIAL_WAKE_LOCK);
    mediaPlayer.setOnPreparedListener(this);
    mediaPlayer.setOnCompletionListener(this);
    mediaPlayer.setOnErrorListener(this);
    mediaPlayer.setOnBufferingUpdateListener(this);
    mediaPlayer.setOnSeekCompleteListener(this);
    mediaPlayer.setAudioAttributes(
        new AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
            .setUsage(AudioAttributes.USAGE_MEDIA)
            .setLegacyStreamType(AudioManager.STREAM_MUSIC)
            .build());
  }

  @Override
  public void onCreate() {
    super.onCreate();
    MediaPlayerInit();
    MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "idle");
    audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
    mediaPlayerServiceBinder = new MediaPlayerServiceBinder();
    volume = -1;
    onAudioFocusChangeListener =
        focusChange -> {
          switch (focusChange) {
            case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
            case AudioManager.AUDIOFOCUS_LOSS:
              if (mediaPlayer != null && mediaPlayer.isPlaying()) {
                mediaPlayer.pause();
                MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "paused");
              }
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
              if (!mediaPlayer.isPlaying()) {
                mediaPlayer.start();
                MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "started");
              }
              break;
          }
        };
  }

  @Override
  public void onDestroy() {
    Log.d("MediaPlayer", "onDestroy");
    mediaPlayer.release();
    MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "end");
    super.onDestroy();
  }

  @Override
  public final MediaPlayerServiceBinder onBind(Intent intent) {
    return mediaPlayerServiceBinder;
  }

  public class MediaPlayerServiceBinder extends Binder {
    public final void init() {
      if (mediaPlayer == null) {
        MediaPlayerInit();
        MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "idle");
      } else {
        mediaPlayer.reset();
        MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "idle");
      }
    }

    public final void start() {
      audioManager.abandonAudioFocus(onAudioFocusChangeListener);
      audioManager.requestAudioFocus(
          onAudioFocusChangeListener,
          AudioManager.STREAM_MUSIC,
          AudioManager.AUDIOFOCUS_GAIN_TRANSIENT);
      mediaPlayer.start();
      MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "started");
    }

    public final void pause() {
      mediaPlayer.pause();
      MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "paused");
    }

    public final void stop() {
      mediaPlayer.stop();
      MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "stopped");
    }

    public final void reset() {
      mediaPlayer.reset();
      MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "idle");
    }

    public final void release() {
      mediaPlayer.release();
      MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "end");
    }

    public final void setDataSource(String url) throws IOException {
      mediaPlayer.reset();
      mediaPlayer.setDataSource(url);
      MainActivity.MediaPlayerCHANNEL.invokeMethod("stateManager", "preparing");
      mediaPlayer.prepare();
      //      executor.submit(new setDataSourceCallable(url));
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

  @Override
  public final void onPrepared(MediaPlayer mediaPlayer) {
    Log.d("mediaPlayer", "onPrepared");
    MainActivity.MediaPlayerCHANNEL.invokeMethod(
        "onPreparedListener",
        // onPrepared will return duration
        mediaPlayer.getDuration(),
        new MethodChannel.Result() {
          @Override
          public void success(Object o) {}

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
    MainActivity.MediaPlayerCHANNEL.invokeMethod(
        "onCompletionListener",
        null,
        new MethodChannel.Result() {
          @Override
          public void success(Object o) {}

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
    MainActivity.MediaPlayerCHANNEL.invokeMethod(
        "onErrorListener",
        new int[] {what, extra},
        new MethodChannel.Result() {
          @Override
          public void success(Object o) {}

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
    MainActivity.MediaPlayerCHANNEL.invokeMethod(
        "onSeekCompleteListener",
        mediaPlayer.getCurrentPosition(),
        new MethodChannel.Result() {
          @Override
          public void success(Object o) {}

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
    MainActivity.MediaPlayerCHANNEL.invokeMethod(
        "onBufferingUpdateListener",
        i,
        new MethodChannel.Result() {
          @Override
          public void success(Object o) {}

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
}
