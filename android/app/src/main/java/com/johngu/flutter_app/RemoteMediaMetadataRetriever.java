package com.johngu.flutter_app;

import android.annotation.TargetApi;
import android.os.Build;
import android.util.Log;
import android.util.Xml;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.RequestFuture;
import com.android.volley.toolbox.StringRequest;

import org.apache.commons.io.IOUtils;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.IOException;
import java.io.StringReader;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import fm.last.musicbrainz.coverart.CoverArt;
import fm.last.musicbrainz.coverart.CoverArtArchiveClient;
import fm.last.musicbrainz.coverart.CoverArtImage;
import fm.last.musicbrainz.coverart.impl.DefaultCoverArtArchiveClient;

public final class RemoteMediaMetadataRetriever {
    private static final String ns = null;
    static RequestQueue queue;

    private static final String getMBID = "getMBID";
    private static final String getMBIDError = "getMBID-Error";

    public static class GetMBIDRunnable implements Runnable {
        private final String artist;
        private final String title;

        GetMBIDRunnable(String artist, String title) {
            this.artist = artist;
            this.title = title;
        }

        @Override
        public void run() {
            getMBID(artist, title, null);
        }
    }

    private static final String maxQueryLimit = "7";

    public static Set<String> getMBID(String artist, String title, String duration) {
        assert (artist != null || title != null);
        String request = "http://musicbrainz.org/ws/2/recording/?query=:";
        if (artist == null) {
            request += "recording:" + title;
        } else if (title == null) {
            request += "artist:" + artist;
        } else {
            request += "recording:" + title + "+artist:" + artist;
        }

        // duration is a optional parameter
        if (duration != null) {
            request += "+dur:" + duration;
        }

        request += "&limit=" + maxQueryLimit;

        RequestFuture<String> future = RequestFuture.newFuture();
        StringRequest stringRequest = new StringRequest(Request.Method.GET, request, future, error -> Log.d(getMBIDError, error.getMessage()));
        queue.add(stringRequest);
        Set<String> ids = new HashSet<String>();
        XmlPullParser parser = Xml.newPullParser();
        try {
            String response = future.get();
            parser.setFeature(XmlPullParser.FEATURE_PROCESS_NAMESPACES, false);
            parser.setInput(new StringReader(response));
            parser.nextTag();
            while (parser.next() != XmlPullParser.END_DOCUMENT) {
                if (parser.getEventType() != XmlPullParser.START_TAG) {
                    continue;
                }
                String name = parser.getName();
                if (name.equals("release")) {
                    String id = parser.getAttributeValue(null, "id");
                    ids.add(id);
                }
            }
            Log.d("ids-length", String.valueOf(ids.size()));
        } catch (Exception e) {
            Log.d(getMBIDError, e.getMessage());

        }

        return ids;
    }

    static private String readRecording(XmlPullParser parser) throws IOException, XmlPullParserException {
        parser.require(XmlPullParser.START_TAG, ns, "recording");
        String tag = parser.getName();
        String id = parser.getAttributeValue(null, "id");
        if (tag.equals("recording")) {
            return id;
        }
        parser.require(XmlPullParser.END_TAG, ns, "recording");
        return null;
    }

    static private void skip(XmlPullParser parser) throws XmlPullParserException, IOException {
        if (parser.getEventType() != XmlPullParser.START_TAG) {
            throw new IllegalStateException();
        }
        int depth = 1;
        while (depth != 0) {
            switch (parser.next()) {
                case XmlPullParser.END_TAG:
                    depth--;
                    break;
                case XmlPullParser.START_TAG:
                    depth++;
                    break;
            }
        }
    }

    public static class GetArtworkUrl implements Runnable {
        private final String artist;
        private final String title;

        GetArtworkUrl(String artist, String title) {
            this.artist = artist;
            this.title = title;
        }

        @Override
        public void run() {
            Set<String> ids = getMBID(artist, title, null);
            getArtwork(ids);
        }
    }

    private final static String getArtworkUrl = "getArtworkUrl";
    private final static String getArtworkUrlError = "getArtworkUrl-error";

    public static byte[] getArtwork(Iterable<String> ids) {
        byte[] res = null;
        for (String id : ids) {
            res = getArtworkById(id);
            if (res != null) {
                break;
            }
        }
        if (res == null) {
            Log.d(getArtworkUrl, "No Artwork");
        }
        return res;
    }

    private static byte[] getArtworkById(String id) {

        final UUID mbid = UUID.fromString(id);
        final CoverArtArchiveClient client = new DefaultCoverArtArchiveClient();
        byte[] res = null;
        try {
            final CoverArt coverArt = client.getByMbid(mbid);
            if (coverArt != null) {
                for (CoverArtImage coverArtImage : coverArt.getImages()) {
                    res = IOUtils.toByteArray(coverArtImage.getImage());
                    if (res != null) {
                        break;
                    }
                }
            }
        } catch (Exception e) {
            Log.d(getArtworkUrlError, e.getMessage());
        }
        return res;
    }
}
