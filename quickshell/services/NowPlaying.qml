pragma ComponentBehavior: Bound
pragma Singleton

import QtQml
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property bool hasBrowserBridge: Mpris.players.values.some(player => player.dbusName?.startsWith("org.mpris.MediaPlayer2.plasma-browser-integration"))
    readonly property list<MprisPlayer> allPlayers: Mpris.players.values.filter(player => !root.isIgnoredPlayer(player))
    readonly property list<MprisPlayer> players: Mpris.players.values.filter(player => root.isUsefulPlayer(player))
    property MprisPlayer trackedPlayer: null
    readonly property MprisPlayer activePlayer: trackedPlayer ?? players[0] ?? allPlayers[0] ?? null

    readonly property string player: activePlayer?.identity ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property real volume: activePlayer?.volume ?? 0.55
    readonly property string rawArtUrl: activePlayer?.trackArtUrl ?? ""
    property string lastArtUrl: ""
    property int artRevision: 0
    readonly property string fallbackArtUrl: fallbackArtUrlFor(activePlayer)
    readonly property list<string> artUrls: bestArtUrls(activePlayer)
    readonly property string artUrl: {
        const next = artUrls.length ? artUrls[0] : "";
        return next.length ? next : lastArtUrl;
    }
    readonly property string displayText: {
        if (!title.length)
            return "Nothing is playing";
        if (artist.length)
            return `${artist} - ${title}`;
        return title;
    }

    onRawArtUrlChanged: syncArtUrl()

    function isUsefulPlayer(player) {
        if (!player)
            return false;

        if (isIgnoredPlayer(player))
            return false;

        if (!hasBrowserBridge)
            return true;

        return !(player.dbusName?.startsWith("org.mpris.MediaPlayer2.firefox") || player.dbusName?.startsWith("org.mpris.MediaPlayer2.chromium") || player.dbusName?.startsWith("org.mpris.MediaPlayer2.brave") || player.dbusName?.startsWith("org.mpris.MediaPlayer2.google-chrome"));
    }

    function isIgnoredPlayer(player) {
        return player?.dbusName?.startsWith("org.mpris.MediaPlayer2.playerctld") ?? true;
    }

    function pickPlayer() {
        for (const player of players) {
            if (player?.isPlaying)
                return player;
        }

        for (const player of allPlayers) {
            if (player?.isPlaying)
                return player;
        }

        return players.length ? players[0] : (allPlayers.length ? allPlayers[0] : null);
    }

    function refresh() {
        trackedPlayer = pickPlayer();
        syncArtUrl();
    }

    function youtubeVideoId(url) {
        if (!url.length)
            return "";

        return url.match(/[?&]v=([\w-]{11})/)?.[1] ?? url.match(/youtu\.be\/([\w-]{11})/)?.[1] ?? "";
    }

    function youtubeArtUrls(player) {
        const url = player?.metadata?.["xesam:url"] ?? "";
        const id = youtubeVideoId(url);
        return id.length ? [`https://i.ytimg.com/vi/${id}/maxresdefault.jpg`, `https://i.ytimg.com/vi/${id}/sddefault.jpg`, `https://i.ytimg.com/vi/${id}/hqdefault.jpg`] : [];
    }

    function isBrowserCachedArt(url) {
        return url.startsWith("file://") && url.includes("firefox-mpris/");
    }

    function fallbackArtUrlFor(player) {
        const raw = player?.trackArtUrl ?? "";
        return isBrowserCachedArt(raw) ? raw : "";
    }

    function addUnique(list, url) {
        if (url.length && list.indexOf(url) === -1)
            list.push(url);
    }

    function bestArtUrls(player) {
        const raw = player?.trackArtUrl ?? "";
        const youtubeArts = youtubeArtUrls(player);
        const next = upscaleArtUrl(raw);
        let urls = [];

        if (isBrowserCachedArt(raw)) {
            for (const url of youtubeArts)
                addUnique(urls, url);
            addUnique(urls, raw);
            return urls;
        }

        addUnique(urls, next);
        for (const url of youtubeArts)
            addUnique(urls, url);

        return urls;
    }

    function upscaleArtUrl(url) {
        if (!url.length)
            return "";

        if (url.includes("googleusercontent.com") || url.includes("ggpht.com"))
            return url.replace(/=(?:w\d+-h\d+|s\d+)[^?&#]*/, "=w800-h800-l90-rj");

        if (url.includes("i.ytimg.com") || url.includes("img.youtube.com"))
            return url.replace(/\/(default|mqdefault)\.jpg($|\?)/, "/hqdefault.jpg$2");

        return url;
    }

    function syncArtUrl() {
        const next = bestArtUrls(root.activePlayer);
        if (next.length)
            root.lastArtUrl = next[0];
        root.artRevision += 1;
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(total / 60);
        const rest = (total % 60).toString().padStart(2, "0");
        return `${minutes}:${rest}`;
    }

    function seekToFraction(fraction) {
        if (!root.activePlayer || root.length <= 0)
            return;

        root.activePlayer.position = Math.max(0, Math.min(1, fraction)) * root.length;
        root.activePlayer.positionChanged();
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.isPlaying
        onTriggered: root.activePlayer?.positionChanged()
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: root.refresh()
            Component.onDestruction: root.refresh()

            function onPlaybackStateChanged() {
                root.refresh();
            }

            function onPostTrackChanged() {
                root.refresh();
                root.syncArtUrl();
            }

            function onTrackArtUrlChanged() {
                root.syncArtUrl();
            }
        }
    }

    Connections {
        target: Mpris.players

        function onValuesChanged() {
            root.refresh();
        }
    }

    Component.onCompleted: syncArtUrl()
}
