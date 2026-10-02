import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import "../../../reusables"
import "../../../"

Rectangle {
    id: batWidgetRoot
    property var barWindow
    property bool isSolid: false
    property bool distinctPills: barWindow ? (barWindow.distinctPills !== undefined ? barWindow.distinctPills : false) : false
    property bool moduleActive: true
    property bool isGrouped: false
    property bool isCompact: isGrouped || (isSolid && distinctPills)

    property bool isDesktop: UPower.displayDevice.ready ? !UPower.displayDevice.isLaptopBattery : SystemInfo.isDesktop
    readonly property int batCap: UPower.displayDevice.ready ? Math.round(UPower.displayDevice.percentage * 100) : 0
    readonly property string batPercent: batCap + "%"

    readonly property string batStatus: UPower.displayDevice.ready ? (UPower.displayDevice.state === UPowerDeviceState.FullyCharged ? "Full" : (UPower.displayDevice.state === UPowerDeviceState.Charging ? "Charging" : "Unknown")) : "Unknown"
    readonly property bool isCharging: UPower.displayDevice.ready && (UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.FullyCharged)
    readonly property string batIcon: isDesktop ? "󰐥" : (isCharging ? "󰂄" : (batCap > 20 ? "󰁹" : "󰂃"))

    property color batDynamicColor: {
        if (isDesktop) return ThemeBackend.red;
        if (isCharging) return Qt.lighter(ThemeBackend.green, 1.15);
        if (batCap <= 15) return ThemeBackend.red;
        if (batCap <= 25) return ThemeBackend.peach;
        return ThemeBackend.teal;
    }

    property real targetX: 0
    property bool showLayout: false
    property alias batPill: batPill

    x: targetX
    Behavior on x {
        enabled: barWindow && barWindow.startupCascadeFinished
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }
    height: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    y: barWindow ? barWindow.baseOffsetY + (barWindow.barHeight - height) / 2 : 0
    radius: ThemeBackend.borderRadius
    border.width: 0
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    clip: true

    property real targetWidth: (moduleActive && sysLayout.implicitWidth > 0) ? (sysLayout.implicitWidth + (barWindow ? barWindow.s(isCompact ? 8 : 10) : (isCompact ? 8 : 10))) : 0
    width: targetWidth

    opacity: (showLayout && moduleActive) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Timer {
        running: batWidgetRoot.moduleActive && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: batWidgetRoot.showLayout = true
    }

    transform: Translate {
        x: batWidgetRoot.showLayout ? 0 : (barWindow ? barWindow.s(60) : 60)
        Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    Row {
        id: sysLayout
        anchors.centerIn: parent
        property int pillHeight: barWindow ? barWindow.s(batWidgetRoot.isCompact ? 28 : 30) : (batWidgetRoot.isCompact ? 28 : 30)

        Rectangle {
            id: batPill
            property bool initAnimTrigger: false

            property real value: batWidgetRoot.isDesktop ? 0.0 : (UPower.displayDevice.ready ? UPower.displayDevice.percentage : 0.0)
            property real animValue: value
            Behavior on animValue { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

            property real fillRatio: Math.max(0.0, Math.min(1.0, isNaN(animValue) ? 0.0 : animValue))
            property real fillWidth: width * fillRatio

            property color baseAccentColor: batWidgetRoot.batDynamicColor
            property color accentColor: batMouseArea.pressed ? Qt.darker(baseAccentColor, 1.15) : (batMouseArea.containsMouse ? Qt.lighter(baseAccentColor, 1.08) : baseAccentColor)

            height: sysLayout.pillHeight
            property real targetWidth: batWidgetRoot.isDesktop ? (barWindow ? barWindow.s(batWidgetRoot.isCompact ? 30 : 32) : (batWidgetRoot.isCompact ? 30 : 32)) : (baseContentRow.implicitWidth + (barWindow ? barWindow.s(batWidgetRoot.isCompact ? 16 : 18) : (batWidgetRoot.isCompact ? 16 : 18)))
            width: targetWidth
            Behavior on width { NumberAnimation { duration: 480; easing.type: Easing.OutQuint } }

            scale: batMouseArea.pressed ? 0.94 : (batMouseArea.containsMouse ? 1.04 : 1.0)
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            radius: Math.max(0, ThemeBackend.borderRadius - (barWindow ? barWindow.s(2) : 2))
            property color baseColor: batWidgetRoot.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0
            color: batMouseArea.pressed ? Qt.darker(baseColor, 1.15) : (batMouseArea.containsMouse ? Qt.lighter(baseColor, 1.08) : baseColor)
            Behavior on color { ColorAnimation { duration: 150 } }
            property color baseBorderColor: batWidgetRoot.isCompact ? ThemeBackend.surface2 : ThemeBackend.surface1
            border.color: batMouseArea.containsMouse ? ThemeBackend.surface2 : baseBorderColor
            Behavior on border.color { ColorAnimation { duration: 150 } }
            border.width: 1
            clip: true

            Timer {
                running: batWidgetRoot.moduleActive && batWidgetRoot.showLayout && !batPill.initAnimTrigger
                interval: 150
                onTriggered: batPill.initAnimTrigger = true
            }

            opacity: initAnimTrigger ? 1.0 : 0.0
            transform: Translate {
                y: batPill.initAnimTrigger ? 0 : (barWindow ? barWindow.s(15) : 15)
                Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
            }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            Canvas {
                id: pillCanvas
                anchors.fill: parent
                renderTarget: Canvas.FramebufferObject
                renderStrategy: Canvas.Cooperative

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (batPill.fillRatio <= 0) return;

                    ctx.save();
                    var r = Math.max(0, Math.min(batPill.radius, Math.min(width / 2, height / 2)));
                    ctx.beginPath();
                    ctx.moveTo(r, 0);
                    ctx.lineTo(width - r, 0);
                    ctx.quadraticCurveTo(width, 0, width, r);
                    ctx.lineTo(width, height - r);
                    ctx.quadraticCurveTo(width, height, width - r, height);
                    ctx.lineTo(r, height);
                    ctx.quadraticCurveTo(0, height, 0, height - r);
                    ctx.lineTo(0, r);
                    ctx.quadraticCurveTo(0, 0, r, 0);
                    ctx.closePath();
                    ctx.clip();

                    ctx.beginPath();
                    ctx.rect(0, 0, batPill.fillWidth, height);
                    ctx.closePath();

                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                    grad.addColorStop(0, Qt.lighter(batPill.accentColor, 1.25).toString());
                    grad.addColorStop(1, batPill.accentColor.toString());
                    ctx.fillStyle = grad;
                    ctx.globalAlpha = 0.95;
                    ctx.fill();
                    ctx.restore();
                }

                Connections {
                    target: batPill
                    enabled: batWidgetRoot.showLayout && batWidgetRoot.moduleActive
                    function onRadiusChanged() { pillCanvas.requestPaint(); }
                    function onFillRatioChanged() { pillCanvas.requestPaint(); }
                    function onFillWidthChanged() { pillCanvas.requestPaint(); }
                    function onAccentColorChanged() { pillCanvas.requestPaint(); }
                }
            }

            Row {
                id: baseContentRow
                anchors.centerIn: parent
                spacing: batWidgetRoot.isDesktop ? 0 : (barWindow ? barWindow.s(5) : 5)

                Text {
                    id: baseBatIconText
                    text: batWidgetRoot.batIcon
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: batWidgetRoot.isDesktop ? (barWindow ? barWindow.s(batWidgetRoot.isCompact ? 15 : 16) : (batWidgetRoot.isCompact ? 15 : 16)) : (barWindow ? barWindow.s(batWidgetRoot.isCompact ? 12 : 13.5) : (batWidgetRoot.isCompact ? 12 : 13.5))
                    color: batWidgetRoot.isDesktop ? ThemeBackend.red : (batWidgetRoot.isCompact ? ThemeBackend.text : ThemeBackend.subtext0)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: baseBatPercentText
                    visible: !batWidgetRoot.isDesktop
                    text: batWidgetRoot.batPercent
                    font.family: ThemeBackend.fontFamily
                    font.pixelSize: barWindow ? barWindow.s(batWidgetRoot.isCompact ? 11 : 12.6) : (batWidgetRoot.isCompact ? 11 : 12.6)
                    font.bold: true
                    color: ThemeBackend.text
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item {
                id: waveClipBox
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.min(parent.width, Math.max(0, batPill.fillWidth))
                clip: true
                visible: batPill.fillRatio > 0

                Row {
                    x: baseContentRow.x
                    y: baseContentRow.y
                    spacing: baseContentRow.spacing

                    Text {
                        text: baseBatIconText.text
                        font.family: baseBatIconText.font.family
                        font.pixelSize: baseBatIconText.font.pixelSize
                        color: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.75)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        visible: baseBatPercentText.visible
                        text: baseBatPercentText.text
                        font.family: baseBatPercentText.font.family
                        font.pixelSize: baseBatPercentText.font.pixelSize
                        font.bold: baseBatPercentText.font.bold
                        color: ThemeBackend.crust
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            MouseArea {
                id: batMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["bash", "-c", Caching.serpantinumDir + "/scripts/qs_manager.sh toggle system"])
            }
        }
    }
}
