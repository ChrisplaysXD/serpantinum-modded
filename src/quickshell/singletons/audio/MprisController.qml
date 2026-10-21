pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../../"

Singleton {
    id: root

    readonly property var _playerWatch: {
        let players = Mpris.players.values;
        let states = [];
        for (let i = 0; i < players.length; i++) {
            states.push(players[i].isPlaying);
            states.push(players[i].canControl);
            states.push(players[i].busName);
        }
        return states;
    }

    property string lastPlayingBus: ""

    readonly property MprisPlayer activePlayer: {
        let _ = _playerWatch;
        try {
            let players = Mpris.players.values.filter(p => p).sort((a, b) => (a.busName || "").localeCompare(b.busName || ""));
            let playing = players.find(p => p.isPlaying);
            if (playing) return playing;
            let last = root.lastPlayingBus !== "" ? players.find(p => p.busName === root.lastPlayingBus) : null;
            if (last) return last;
            let loaded = players.find(p => p.playbackState !== MprisPlaybackState.Stopped && p.trackTitle !== "");
            if (loaded) return loaded;
            let controllable = players.find(p => p.canControl);
            if (controllable) return controllable;
            return players.length > 0 ? players[0] : null;
        } catch (e) {
            return null;
        }
    }

    readonly property string activePlayerId: activePlayer ? (activePlayer.busName || activePlayer.identity || "") : ""
    readonly property bool hasActivePlayer: activePlayer !== null
    readonly property bool isPlaying: {
        try {
            return activePlayer ? activePlayer.isPlaying === true : false;
        } catch (e) {
            return false;
        }
    }
    readonly property string trackTitle: {
        try {
            return activePlayer ? String(activePlayer.trackTitle || "") : "";
        } catch (e) {
            return "";
        }
    }
    readonly property string trackArtist: {
        try {
            return activePlayer ? String(activePlayer.trackArtist || "") : "";
        } catch (e) {
            return "";
        }
    }
    readonly property string currentArtUrl: {
        if (!activePlayer) return "";
        if (activePlayer.trackArtUrl && activePlayer.trackArtUrl !== "") return activePlayer.trackArtUrl;
        if (activePlayer.metadata) {
            let m = activePlayer.metadata;
            if (m["mpris:artUrl"]) return m["mpris:artUrl"];
            if (m["artUrl"]) return m["artUrl"];
            if (m["xesam:url"] && typeof m["xesam:url"] === "string" && (m["xesam:url"].startsWith("http") || m["xesam:url"].startsWith("file://"))) {
                if (m["xesam:url"].match(/\.(jpg|jpeg|png|webp)$/i)) return m["xesam:url"];
            }
        }
        return "";
    }

    readonly property bool isMusicService: {
        if (!activePlayer) return false;

        let bus = (activePlayer.busName || "").toLowerCase();
        let ident = (activePlayer.identity || "").toLowerCase();
        let art = (root.currentArtUrl || "").toLowerCase();
        let trackUrl = "";
        if (activePlayer.metadata && activePlayer.metadata["xesam:url"]) {
            trackUrl = String(activePlayer.metadata["xesam:url"]).toLowerCase();
        }

        let isYouTubeVideo = (trackUrl.indexOf("youtube.com/watch") !== -1 || trackUrl.indexOf("youtu.be/") !== -1 || art.indexOf("ytimg.com") !== -1)
            && trackUrl.indexOf("music.youtube.com") === -1;
        let isTwitch = trackUrl.indexOf("twitch.tv") !== -1 || art.indexOf("jtvnw.net") !== -1 || art.indexOf("ttvnw.net") !== -1;
        let isKick = trackUrl.indexOf("kick.com") !== -1;

        if (isYouTubeVideo || isTwitch || isKick) {
            return false;
        }

        let musicAppTokens = [
            "spotify", "amberol", "rhythmbox", "clementine", "strawberry",
            "audacious", "deadbeef", "elisa", "lollypop", "cider",
            "apple-music", "applemusic", "tidal", "deezer", "youtube-music",
            "youtube music", "cmus", "mpd", "feishin", "supersonic",
            "quodlibet", "gmusicbrowser", "tauon", "cantata", "pragha",
            "sayonara", "musique", "mopidy", "plexamp", "substreamer"
        ];
        for (let i = 0; i < musicAppTokens.length; i++) {
            if (bus.indexOf(musicAppTokens[i]) !== -1 || ident.indexOf(musicAppTokens[i]) !== -1) {
                return true;
            }
        }

        let musicDomains = [
            "open.spotify.com", "music.youtube.com", "soundcloud.com",
            "listen.tidal.com", "deezer.com", "bandcamp.com", "music.apple.com",
            "music.amazon.com", "pandora.com", "qobuz.com"
        ];
        for (let j = 0; j < musicDomains.length; j++) {
            if (trackUrl.indexOf(musicDomains[j]) !== -1 || art.indexOf(musicDomains[j]) !== -1) {
                return true;
            }
        }
        if (art.indexOf("scdn.co") !== -1 || art.indexOf("sndcdn.com") !== -1 || art.indexOf("mzstatic.com") !== -1) {
            return true;
        }

        if (trackUrl.startsWith("file://") || (trackUrl === "" && art.startsWith("file://"))) {
            let audioExts = [".mp3", ".flac", ".ogg", ".opus", ".m4a", ".wav", ".aac", ".alac", ".wma", ".aiff"];
            for (let k = 0; k < audioExts.length; k++) {
                if (trackUrl.endsWith(audioExts[k])) return true;
            }
            let videoExts = [".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv"];
            for (let v = 0; v < videoExts.length; v++) {
                if (trackUrl.endsWith(videoExts[v])) return false;
            }
        }

        if (bus.indexOf("firefox") !== -1 || bus.indexOf("chrome") !== -1 || bus.indexOf("chromium") !== -1 || bus.indexOf("brave") !== -1 || bus.indexOf("edge") !== -1 || bus.indexOf("opera") !== -1 || bus.indexOf("vivaldi") !== -1) {
            return false;
        }

        return Boolean(root.trackTitle && root.trackArtist);
    }

    property real livePosition: activePlayer ? activePlayer.position : 0

    property string artUrl: ""
    property string blur: ""
    property string grad: ""
    property string textColor: "#cdd6f4"
    property string deviceIcon: "󰓃"
    property string deviceName: "Speaker"
    property bool fetchPending: false

    onActivePlayerChanged: {
        if (root.activePlayer && root.activePlayer.isPlaying) {
            root.lastPlayingBus = root.activePlayer.busName || "";
        }
        if (root.activePlayer) {
            root.livePosition = root.activePlayer.position;
        }
        root.queueFetch();
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.hasActivePlayer && root.isPlaying
        onTriggered: {
            if (root.activePlayer) {
                root.activePlayer.positionChanged();
                root.livePosition = root.activePlayer.position;
            }
        }
    }

    Timer {
        id: fetchDebounceTimer
        interval: 60
        repeat: false
        onTriggered: root.fetchArt()
    }

    function queueFetch() {
        fetchDebounceTimer.restart();
    }

    Connections {
        target: root.activePlayer
        function onPositionChanged() {
            if (root.activePlayer) root.livePosition = root.activePlayer.position;
        }
        function onPostTrackChanged() {
            if (root.activePlayer) root.livePosition = root.activePlayer.position;
            root.queueFetch();
        }
        function onTrackArtUrlChanged() {
            root.queueFetch();
        }
        function onTrackTitleChanged() {
            root.queueFetch();
        }
        function onMetadataChanged() {
            root.queueFetch();
        }
        function onPlaybackStateChanged() {
            root.queueFetch();
        }
    }

    Process {
        id: artFetchProc
        command: [
            "bash",
            Caching.qsDir + "/media/art_fetch.sh",
            root.activePlayerId,
            root.currentArtUrl,
            root.trackTitle,
            root.trackArtist
        ]
        onExited: {
            if (root.fetchPending) {
                root.fetchPending = false;
                artFetchProc.running = true;
            }
        }
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let d = JSON.parse(txt);
                        root.deviceIcon = d.deviceIcon || "󰓃";
                        root.deviceName = d.deviceName || "Speaker";

                        if (d.playerId !== root.activePlayerId || d.title !== root.trackTitle || d.artist !== root.trackArtist) {
                            return;
                        }

                        if (d.isPlaceholder === false && d.artUrl) {
                            root.artUrl = d.artUrl;
                            root.blur = d.blur || "";
                            root.grad = d.grad || "";
                            root.textColor = d.textColor || "#cdd6f4";
                        } else {
                            root.artUrl = "";
                            root.blur = "";
                            root.grad = d.grad || "";
                            root.textColor = d.textColor || "#cdd6f4";
                        }
                    } catch(e) {}
                }
            }
        }
    }

    function fetchArt() {
        if (!root.hasActivePlayer) {
            root.artUrl = "";
            root.blur = "";
            root.grad = "";
            root.textColor = "#cdd6f4";
            return;
        }
        if (artFetchProc.running) {
            root.fetchPending = true;
            return;
        }
        root.fetchPending = false;
        artFetchProc.running = true;
    }

    function forceArtRefresh() {
        root.fetchArt();
    }
}
