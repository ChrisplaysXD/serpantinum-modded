pragma Singleton
import QtQuick
import "../../"

Item {
    id: root

    readonly property string themeSource: {
        let themeConfig = Config.getSetting("theme", {});
        return themeConfig.themeSource !== undefined ? themeConfig.themeSource : "wallpaper";
    }

    readonly property bool hasAlbumArt: root.themeSource === "album"
        && typeof MprisController !== "undefined"
        && MprisController.isMusicService
        && MprisController.artUrl !== undefined
        && MprisController.artUrl !== ""

    Timer {
        id: debounceTimer
        interval: 150
        onTriggered: root.applyThemeSource()
    }

    function effectiveSource() {
        return MprisController.artUrl;
    }

    function applyThemeSource() {
        if (typeof ThemeBackend === "undefined" || typeof ThemeBackend.isMatugenTheme !== "function" || !ThemeBackend.isMatugenTheme()) {
            return;
        }
        let themeConfig = Config.getSetting("theme", {});
        let targetImg = root.hasAlbumArt ? root.effectiveSource() : "";
        if (targetImg && targetImg !== "" && typeof Matugen !== "undefined" && typeof Matugen.generate === "function") {
            if (Matugen.isRunning) {
                console.warn("[AlbumTheme] matugen already running, skipping");
                return;
            }
            let clean = targetImg.startsWith("file://") ? targetImg.substring(7) : targetImg;
            let alreadyGen = (Matugen._hasGeneratedSuccessfully
                && Matugen._lastGeneratedReqType === "image"
                && Matugen._lastGeneratedImagePath === clean
                && !Matugen.isRunning);

            Matugen.generate(targetImg, themeConfig.mode, themeConfig.schemeType);

            if (alreadyGen) {
                ThemeBackend.applyMatugenColors();
            }
        } else {
            // album selected but no art, or non-album source: regenerate from wallpaper
            if (typeof ThemeBackend !== "undefined" && typeof ThemeBackend.updateColors === "function") {
                ThemeBackend.updateColors();
            }
        }
    }

    Connections {
        target: typeof MprisController !== "undefined" ? MprisController : null
        function onArtUrlChanged() {
            if (root.themeSource === "album" && root.isMatugenThemeActive()) {
                debounceTimer.restart();
            }
        }
        function onIsMusicServiceChanged() {
            if (root.themeSource === "album" && root.isMatugenThemeActive()) {
                debounceTimer.restart();
            }
        }
    }

    function isMatugenThemeActive() {
        return typeof ThemeBackend !== "undefined" && typeof ThemeBackend.isMatugenTheme === "function" && ThemeBackend.isMatugenTheme();
    }

    Component.onCompleted: {
        if (root.themeSource === "album" && root.isMatugenThemeActive()) {
            debounceTimer.restart();
        }
    }
}
