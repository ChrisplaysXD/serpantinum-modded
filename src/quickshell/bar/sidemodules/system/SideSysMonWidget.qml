import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "../../../reusables"
import "../../../"

Rectangle {
    id: sideSysMonRoot
    property var barWindow
    property bool isSolid: false
    property bool distinctPills: barWindow ? (barWindow.distinctPills !== undefined ? barWindow.distinctPills : false) : false
    property bool moduleActive: true
    property bool isGrouped: false
    property bool isCompact: isGrouped || (isSolid && distinctPills)
    property real targetY: 0
    property bool showLayout: false

    property int circleSize: barWindow ? barWindow.s(isCompact ? 22 : 28) : (isCompact ? 22 : 28)

    property bool isSysVisible: moduleActive && showLayout
    property color basePrimary: (ThemeBackend.primary !== undefined && ThemeBackend.primary !== "") ? ThemeBackend.primary : ThemeBackend.mauve

    function updateSubscription() {
        if (isSysVisible) {
            SysData.subscribe()
        } else {
            SysData.unsubscribe()
        }
    }

    Component.onCompleted: updateSubscription()
    Component.onDestruction: SysData.unsubscribe()
    onIsSysVisibleChanged: updateSubscription()

    property real targetWidth: barWindow ? (isGrouped ? barWindow.barHeight - 8 : ((isSolid && distinctPills) ? barWindow.barHeight - 6 : barWindow.barHeight)) : (isGrouped ? 22 : ((isSolid && distinctPills) ? 24 : 30))
    property real targetHeight: (moduleActive && sysLayout.implicitHeight > 0) ? (sysLayout.implicitHeight + (barWindow ? barWindow.s(isCompact ? 8 : 10) : (isCompact ? 8 : 10))) : 0

    width: targetWidth
    height: targetHeight

    Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

    x: barWindow ? ((barWindow.baseOffsetX !== undefined ? barWindow.baseOffsetX : 0) + (barWindow.barHeight - width) / 2) : 0
    y: targetY
    Behavior on y {
        enabled: barWindow && barWindow.startupCascadeFinished
        NumberAnimation { duration: 600; easing.type: Easing.OutQuint }
    }

    radius: ThemeBackend.borderRadius
    border.width: 0
    color: isGrouped ? "transparent" : (isSolid ? (distinctPills ? Qt.darker(ThemeBackend.surface0, 1.15) : "transparent") : ThemeBackend.base)
    clip: true
    layer.enabled: true

    opacity: (showLayout && moduleActive) ? ((barWindow && barWindow.barOpacity !== undefined) ? barWindow.barOpacity : 1.0) : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Timer {
        running: sideSysMonRoot.moduleActive && barWindow && barWindow.isStartupReady && barWindow.isDataReady
        interval: 100
        onTriggered: sideSysMonRoot.showLayout = true
    }

    transform: Translate {
        y: sideSysMonRoot.showLayout ? 0 : (barWindow ? barWindow.s(60) : 60)
        Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutQuint } }
    }

    component SysMonCircle: Rectangle {
        id: circleRoot
        property real value: 0
        property string textVal: ""
        property string icon: ""
        property color accentColor: sideSysMonRoot.basePrimary
        property bool showText: textVal !== ""
        property bool initAnimTrigger: false

        property real animValue: initAnimTrigger ? value : 0
        Behavior on animValue { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

        property real fillRatio: Math.max(0.0, Math.min(1.0, isNaN(animValue) ? 0.0 : animValue))

        implicitWidth: sideSysMonRoot.circleSize
        implicitHeight: sideSysMonRoot.circleSize
        width: implicitWidth
        height: implicitHeight
        radius: width / 2
        color: "transparent"
        border.width: 0

        Timer {
            running: sideSysMonRoot.moduleActive && sideSysMonRoot.showLayout && !initAnimTrigger
            interval: 150
            onTriggered: initAnimTrigger = true
        }

        opacity: initAnimTrigger ? 1.0 : 0.0
        transform: Translate {
            y: initAnimTrigger ? 0 : (barWindow ? barWindow.s(15) : 15)
            Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
        }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Canvas {
            id: circleCanvas
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Cooperative
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var cx = width / 2;
                var cy = height / 2;
                var strokeW = barWindow ? barWindow.s(2.2) : 2.2;
                var amp = barWindow ? barWindow.s(0.9) : 0.9;
                var radius = Math.min(cx, cy) - amp - (strokeW / 2) - (barWindow ? barWindow.s(0.4) : 0.4);
                if (radius <= 0) return;

                ctx.save();

                ctx.beginPath();
                ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
                ctx.strokeStyle = Qt.rgba(circleRoot.accentColor.r, circleRoot.accentColor.g, circleRoot.accentColor.b, 0.22);
                ctx.lineWidth = strokeW;
                ctx.stroke();

                if (circleRoot.fillRatio > 0.001) {
                    var totalP = 2 * Math.PI * radius;
                    var cycles = Math.max(5, Math.round(totalP / 8.5));
                    var freq = (Math.PI * 2 * cycles) / totalP;
                    var startAngle = -Math.PI / 2;
                    var sweepAngle = Math.PI * 2 * circleRoot.fillRatio;
                    var arcLen = totalP * circleRoot.fillRatio;
                    var steps = Math.max(6, Math.ceil(arcLen / 1.2));

                    ctx.beginPath();
                    for (var i = 0; i <= steps; i++) {
                        var t = i / steps;
                        var a = startAngle + sweepAngle * t;
                        var arcDist = (a - startAngle) * radius;
                        var wOff = amp * Math.sin(freq * arcDist);
                        var px = cx + (radius + wOff) * Math.cos(a);
                        var py = cy + (radius + wOff) * Math.sin(a);

                        if (i === 0) {
                            ctx.moveTo(px, py);
                        } else {
                            ctx.lineTo(px, py);
                        }
                    }

                    if (circleRoot.fillRatio >= 0.999) {
                        ctx.closePath();
                    }

                    ctx.strokeStyle = circleRoot.accentColor;
                    ctx.lineWidth = strokeW;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.stroke();
                }

                var displayText = circleRoot.showText ? circleRoot.textVal : circleRoot.icon;
                var fontSize = circleRoot.showText
                    ? (barWindow ? barWindow.s(sideSysMonRoot.isCompact ? 7.5 : 9) : (sideSysMonRoot.isCompact ? 7.5 : 9))
                    : (barWindow ? barWindow.s(sideSysMonRoot.isCompact ? 9 : 11) : (sideSysMonRoot.isCompact ? 9 : 11));

                var fontFam = (ThemeBackend.fontFamily !== undefined && ThemeBackend.fontFamily !== "") ? ThemeBackend.fontFamily : "sans-serif";
                var fontStr = (circleRoot.showText ? "bold " : "normal ") + Math.round(fontSize) + "px \"" + fontFam + "\", \"Iosevka Nerd Font\", \"JetBrainsMono Nerd Font\", sans-serif";
                var baseTextColor = (ThemeBackend.text !== undefined && ThemeBackend.text !== "") ? ThemeBackend.text : "#ffffff";

                ctx.font = fontStr;
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.fillStyle = baseTextColor;
                ctx.fillText(displayText, cx, cy);

                ctx.restore();
            }

            Component.onCompleted: circleCanvas.requestPaint()
            onWidthChanged: circleCanvas.requestPaint()
            onHeightChanged: circleCanvas.requestPaint()

            Connections {
                target: circleRoot
                enabled: sideSysMonRoot.isSysVisible
                function onFillRatioChanged() { circleCanvas.requestPaint(); }
                function onAccentColorChanged() { circleCanvas.requestPaint(); }
                function onTextValChanged() { circleCanvas.requestPaint(); }
                function onIconChanged() { circleCanvas.requestPaint(); }
                function onShowTextChanged() { circleCanvas.requestPaint(); }
            }

            Connections {
                target: sideSysMonRoot
                enabled: sideSysMonRoot.isSysVisible
                function onBasePrimaryChanged() { circleCanvas.requestPaint(); }
            }
        }
    }

    Column {
        id: sysLayout
        anchors.centerIn: parent
        spacing: barWindow ? barWindow.s(sideSysMonRoot.isCompact ? 5 : 6) : (sideSysMonRoot.isCompact ? 5 : 6)
        property int circleSize: sideSysMonRoot.circleSize

        SysMonCircle {
            value: isNaN(SysData.cpu) ? 0 : SysData.cpu / 100.0
            icon: "󰍛"
            accentColor: Qt.tint(sideSysMonRoot.basePrimary, Qt.rgba(1.0, 0.22, 0.22, 0.25))
        }

        SysMonCircle {
            value: isNaN(SysData.ramPercent) ? 0 : SysData.ramPercent / 100.0
            icon: "\uF2DB"
            accentColor: Qt.lighter(sideSysMonRoot.basePrimary, 1.15)
        }

        SysMonCircle {
            value: isNaN(SysData.temp) ? 0 : Math.max(0, Math.min(1, SysData.temp / 100.0))
            textVal: isNaN(SysData.temp) ? "0" : Math.round(SysData.temp).toString()
            icon: "\uF2C9"
            accentColor: Qt.darker(sideSysMonRoot.basePrimary, 1.15)
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            FloatingController.showSystemUsage(sideSysMonRoot.barWindow ? sideSysMonRoot.barWindow.screen : null);
        }
    }
}
