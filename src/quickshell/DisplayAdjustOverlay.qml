import QtQuick
import "../../"

Rectangle {
    id: root

    anchors.fill: parent
    color: "transparent"
    border.color: (Config.getSetting("theme",{}).saturation !== undefined && Config.getSetting("theme",{}).saturation !== 100) || (Config.getSetting("theme",{}).contrast !== undefined && Config.getSetting("theme",{}).contrast !== 100) ? Qt.rgba(ThemeBackend.mauve.r, ThemeBackend.mauve.g, ThemeBackend.mauve.b, 0.25) : "transparent"
    border.width: 2
    opacity: 0.08
    visible: true

    Connections {
        target: Config
        function onSettingsLoaded() {
            root.opacity = (Config.getSetting("theme",{}).saturation !== undefined && Config.getSetting("theme",{}).saturation !== 100) ? 0.08 : 0.0;
        }
        function onRawSettingsChanged() {
            root.opacity = (Config.getSetting("theme",{}).saturation !== undefined && Config.getSetting("theme",{}).saturation !== 100) ? 0.08 : 0.0;
        }
    }
}
