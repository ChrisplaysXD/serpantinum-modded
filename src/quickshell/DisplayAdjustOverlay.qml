import QtQuick
import "../../"

ShaderEffect {
    id: root

    property real saturation: 1.0
    property real contrast: 1.0
    property real brightness: 1.0

    anchors.fill: parent
    visible: true

    fragmentShader: "file://" + (typeof Caching !== "undefined" && Caching.serpantinumDir ? Caching.serpantinumDir : Quickshell.env("HOME") + "/.local/share/serpantinum") + "/src/assets/shaders/effects/display_adjust.frag"

    Connections {
        target: Config
        function onSettingsLoaded() {
            let ts = Config.getSetting("theme", {});
            root.saturation = ts.saturation !== undefined ? Number(ts.saturation) / 100 : 1.0;
            root.contrast = ts.contrast !== undefined ? Number(ts.contrast) / 100 : 1.0;
        }
        function onRawSettingsChanged() {
            let ts = Config.getSetting("theme", {});
            root.saturation = ts.saturation !== undefined ? Number(ts.saturation) / 100 : 1.0;
            root.contrast = ts.contrast !== undefined ? Number(ts.contrast) / 100 : 1.0;
        }
    }

    ShaderEffectSource {
        id: screenSource
        sourceItem: root.parent ? root.parent : null
        visible: false
        live: true
        hideSource: true
    }
    source: screenSource
}
