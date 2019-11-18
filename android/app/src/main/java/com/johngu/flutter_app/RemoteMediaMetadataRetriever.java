package com.johngu.flutter_app;

import android.util.Log;
import android.util.Xml;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.toolbox.RequestFuture;
import com.android.volley.toolbox.StringRequest;

import org.apache.commons.io.IOUtils;
import org.xmlpull.v1.XmlPullParser;
import org.xmlpull.v1.XmlPullParserException;

import java.io.BufferedInputStream;
import java.io.FileInputStream;
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


    private static final String maxQueryLimit = "10";
    private static DefaultRetryPolicy defaultRetryPolicy = new DefaultRetryPolicy(
            DefaultRetryPolicy.DEFAULT_TIMEOUT_MS * 2,
            DefaultRetryPolicy.DEFAULT_MAX_RETRIES,
            DefaultRetryPolicy.DEFAULT_BACKOFF_MULT);

    public enum Category {
        release, recording;

        @Override
        public String toString() {
            switch (this) {
                case release:
                    return "release";
                case recording:
                    return "recording";
            }
            return super.toString();
        }
    }

    private static String generateRequest(String artist, String album, String title) {
        if (title == null) {
            String request = "http://musicbrainz.org/ws/2/release/?query=";
            request += "release:" + album.replaceAll("\\p{P}", "");
            if (artist != null) {
                request += " AND " + "artist:" + artist.replaceAll("\\p{P}", "");
            }
            return request;
        } else {
            String request = "http://musicbrainz.org/ws/2/recording/?query=";
            request += "recording:" + title.replaceAll("\\p{P}", "");
            if (album != null) {
                request += " AND " + "release:" + album.replaceAll("\\p{P}", "");
            }
            if (artist != null) {
                request += " AND " + "artist:" + artist.replaceAll("\\p{P}", "");
            }
            return request;
        }
    }


    static Set<String> getMBID(String artist, String album, String title) {
        assert (artist != null || album != null);
        String request = generateRequest(artist, album, title);
        request += "&limit=" + maxQueryLimit;

        Log.d("request", request);

        RequestFuture<String> future = RequestFuture.newFuture();
        StringRequest stringRequest = new StringRequest(Request.Method.GET, request, future, error -> Log.d(getMBIDError, error.getMessage()));
        stringRequest.setRetryPolicy(defaultRetryPolicy);
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

    public static String codeString(String fileName) throws Exception {
        BufferedInputStream bin = new BufferedInputStream(
                new FileInputStream(fileName));
        int p = (bin.read() << 8) + bin.read();
        String code = null;

        switch (p) {
            case 0xefbb:
                code = "UTF-8";
                break;
            case 0xfffe:
                code = "Unicode";
                break;
            case 0xfeff:
                code = "UTF-16BE";
                break;
            default:
                code = "GBK";
        }

        return code;
    }
}
