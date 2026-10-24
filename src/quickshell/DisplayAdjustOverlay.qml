import QtQuick
import "../../"

ShaderEffect {
    id: root

    property real saturation: 1.0
    property real contrast: 1.0
    property real brightness: 1.0
    property variant src: ShellRoot ? ShellRoot.contentItem ? ShellRoot.contentItem.children[0] : null : null

    anchors.fill: parent
    visible: (saturation !== 1.0 || contrast !== 1.0 || brightness !== 1.0)

    fragmentShader: "file://" + (typeof Caching !== "undefined" && Caching.serpantinumDir ? Caching.serpantinumDir : Quickshell.env("HOME") + "/.local/share/serpantinum") + "/src/assets/shaders/effects/display_adjust.frag"

    Connections {
        target: Config
        function onSettingsLoaded() {
            let ts = Config.getSetting("theme", {});
            root.saturation = ts.saturation !== undefined ? Number(ts.saturation) / 100 : 1.0;
            root.contrast = ts.contrast !== undefined ? Number(ts.contrast) / 100 : 1.0;
            root.brightness = 1.0;
        }
        function onRawSettingsChanged() {
            let ts = Config.getSetting("theme", {});
            root.saturation = ts.saturation !== undefined ? Number(ts.saturation) / 100 : 1.0;
            root.contrast = ts.contrast !== undefined ? Number(ts.contrast) / 100 : 1.0;
        }
    }
    property variant srcTexture: ShaderEffectSource {
        sourceItem: root.parent ? root.parent : null
        visible: false
        live: true
        hideSource: true
    }
    source: ShaderEffectSource {
        sourceItem: root.parent ? root.parent.children[0] ? root.parent.children[0] : root.parent : root.parent
        visible: false
        live: true
        hideSource: true
    }
}
