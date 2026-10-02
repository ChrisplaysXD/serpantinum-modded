import QtQuick
import QtQuick.Layouts
import "../../"
import "../"

Item {
    id: root

    property real value: 0.0
    property color colorBase: ThemeBackend.surface0
    property color colorFill: ThemeBackend.mauve
    property string icon: ""
    property string title: ""
    property string midText: ""
    property string valueText: ""
    property string subText: ""
    property alias bottomLeftText: root.subText

    property real wavePhase: 0.0
    property real waveIntensity: 0.0
    property bool isLive: true
    property bool hasShadow: false
    property color shadowColor: Qt.rgba(0, 0, 0, 0.22)

    property bool compact: false

    property var scaleFunc: null
    function s(val) {
        return typeof scaleFunc === "function" ? scaleFunc(val) : (typeof Scaler !== "undefined" ? Scaler.s(val) : val);
    }

    property real cardRadius: compact ? s(Math.max(0, ThemeBackend.clampedBorderRadius - 2)) : s(ThemeBackend.clampedBorderRadius)
    property real contentMargins: compact ? s(10) : s(12)
    property real waveAmpMax: compact ? s(4) : s(5)

    property real iconSize: compact ? s(26) : s(28)
    property real iconCornerRadius: Math.min(iconSize / 2, s(ThemeBackend.borderRadius))
    property real iconFontSize: compact ? s(14) : s(16)
    property real midTextFontSize: compact ? s(10.5) : s(13)
    property real titleFontSize: compact ? s(10.5) : s(13)
    property real subTextFontSize: compact ? s(11) : s(15)
    property real valueFontSize: compact ? s(18) : s(24)

    property string fontFamily: ThemeBackend.fontFamily
    property color borderColor: Qt.rgba(ThemeBackend.text.r, ThemeBackend.text.g, ThemeBackend.text.b, 0.06)
    property color iconAccentColor: Qt.rgba(ThemeBackend.surface1.r, ThemeBackend.surface1.g, ThemeBackend.surface1.b, 0.6)
    property color iconTextColor: ThemeBackend.subtext0
    property color midTextColor: Qt.rgba(ThemeBackend.subtext0.r, ThemeBackend.subtext0.g, ThemeBackend.subtext0.b, 0.7)
    property color titleColor: ThemeBackend.subtext0
    property color subTextColor: ThemeBackend.subtext0
    property color valueTextColor: ThemeBackend.text

    property color filledIconAccentColor: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.15)
    property color filledTextColor: ThemeBackend.crust
    property color filledMidTextColor: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.6)
    property color filledTitleColor: Qt.rgba(ThemeBackend.crust.r, ThemeBackend.crust.g, ThemeBackend.crust.b, 0.85)
    property color filledSubTextColor: ThemeBackend.crust

    default property alias childItems: customContentBox.data

    readonly property real targetRatio: Math.max(0.0, Math.min(1.0, root.value))
    property real fillRatio: targetRatio
    readonly property real fillY: height * (1.0 - root.fillRatio)
    readonly property real waveAmp: (root.fillRatio < 0.99 && root.fillRatio > 0.01) ? root.waveAmpMax * Math.sin(root.fillRatio * Math.PI) * root.waveIntensity : 0
    readonly property real waveCenterOffset: root.waveAmp > 0 ? 0.375 * root.waveAmp * (Math.sin(root.wavePhase) - Math.cos(root.wavePhase)) : 0

    onTargetRatioChanged: {
        if (!root.isLive) {
            growAnimation.stop();
            fallAnimation.stop();
            root.fillRatio = targetRatio;
            root.waveIntensity = 0.0;
            fluidCanvas.requestPaint();
            return;
        }

        if (targetRatio > root.fillRatio) {
            fallAnimation.stop();
            growAnimation.stop();
            growAnimation.fromRatio = root.fillRatio;
            growAnimation.toRatio = targetRatio;
            growAnimation.restart();
        } else if (targetRatio < root.fillRatio) {
            growAnimation.stop();
            fallAnimation.stop();
            fallAnimation.fromRatio = root.fillRatio;
            fallAnimation.toRatio = targetRatio;
            fallAnimation.restart();
        }
    }

    onFillRatioChanged: {
        if (root.isLive) {
            fluidCanvas.requestPaint();
        }
    }

    onWavePhaseChanged: {
        if (root.isLive && root.waveAmp > 0) {
            fluidCanvas.requestPaint();
        }
    }

    onWaveIntensityChanged: {
        if (root.isLive) {
            fluidCanvas.requestPaint();
        }
    }

    onColorFillChanged: {
        if (root.isLive) {
            fluidCanvas.requestPaint();
        }
    }

    onWidthChanged: fluidCanvas.requestPaint()
    onHeightChanged: fluidCanvas.requestPaint()

    ParallelAnimation {
        id: growAnimation
        property real fromRatio: 0.0
        property real toRatio: 0.0

        NumberAnimation {
            target: root
            property: "fillRatio"
            from: growAnimation.fromRatio
            to: growAnimation.toRatio
            duration: 750
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            NumberAnimation {
                target: root
                property: "waveIntensity"
                from: 0.0
                to: 1.0
                duration: 180
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: root
                property: "waveIntensity"
                from: 1.0
                to: 0.0
                duration: 570
                easing.type: Easing.InOutQuad
            }
        }

        NumberAnimation {
            target: root
            property: "wavePhase"
            from: root.wavePhase
            to: root.wavePhase + (Math.PI * 3)
            duration: 750
            easing.type: Easing.Linear
        }

        onFinished: {
            root.waveIntensity = 0.0;
            fluidCanvas.requestPaint();
        }
    }

    ParallelAnimation {
        id: fallAnimation
        property real fromRatio: 0.0
        property real toRatio: 0.0

        NumberAnimation {
            target: root
            property: "fillRatio"
            from: fallAnimation.fromRatio
            to: fallAnimation.toRatio
            duration: 450
            easing.type: Easing.OutCubic
        }

        PropertyAction {
            target: root
            property: "waveIntensity"
            value: 0.0
        }

        onFinished: {
            root.waveIntensity = 0.0;
            fluidCanvas.requestPaint();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: root.s(2)
        anchors.bottomMargin: -root.s(2)
        radius: root.cardRadius
        color: root.shadowColor
        visible: root.hasShadow
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cardRadius
        color: root.colorBase
        border.width: 1
        border.color: root.borderColor
    }

    Canvas {
        id: fluidCanvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Immediate

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (root.fillRatio <= 0) return;

            ctx.save();
            var r = root.cardRadius;
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
            ctx.moveTo(0, root.fillY);
            if (root.waveAmp > 0) {
                var sinPhase = Math.sin(root.wavePhase);
                var cosPhase = Math.cos(root.wavePhase + Math.PI);
                var cp1y = root.fillY + sinPhase * root.waveAmp;
                var cp2y = root.fillY + cosPhase * root.waveAmp;
                ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, root.fillY);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
            } else {
                ctx.lineTo(width, root.fillY);
                ctx.lineTo(width, height);
                ctx.lineTo(0, height);
            }
            ctx.closePath();

            var grad = ctx.createLinearGradient(0, 0, 0, height);
            grad.addColorStop(0, Qt.lighter(root.colorFill, 1.18).toString());
            grad.addColorStop(1, root.colorFill.toString());
            ctx.fillStyle = grad;
            ctx.globalAlpha = 0.94;
            ctx.fill();
            ctx.restore();
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.contentMargins

        IconButton {
            id: baseCardIcon
            anchors.top: parent.top
            anchors.left: parent.left
            size: Math.round(root.iconSize)
            cornerRadius: Math.round(root.iconCornerRadius)
            accentColor: root.iconAccentColor
            textColor: root.iconTextColor
            buttonIcon: root.icon
            iconFontSize: Math.round(root.iconFontSize)
            enabled: false
        }

        Row {
            anchors.verticalCenter: baseCardIcon.verticalCenter
            anchors.right: parent.right
            spacing: root.s(4)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: root.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: root.midTextFontSize
                color: root.midTextColor
                text: root.midText
                visible: root.midText !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                font.family: root.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: root.titleFontSize
                color: root.titleColor
                text: root.title
            }
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: root.s(1)
            font.family: root.fontFamily
            font.weight: Font.DemiBold
            font.pixelSize: root.subTextFontSize
            color: root.subTextColor
            text: root.subText
            visible: root.subText !== ""
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            font.family: root.fontFamily
            font.weight: Font.Black
            font.pixelSize: root.valueFontSize
            color: root.valueTextColor
            text: root.valueText
        }
    }

    Item {
        id: waveClipBox
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(parent.height, Math.max(0, (parent.height * root.fillRatio) - root.waveCenterOffset))
        clip: true
        visible: root.fillRatio > 0

        Item {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.height
            anchors.margins: root.contentMargins

            IconButton {
                id: filledCardIcon
                anchors.top: parent.top
                anchors.left: parent.left
                size: Math.round(root.iconSize)
                cornerRadius: Math.round(root.iconCornerRadius)
                accentColor: root.filledIconAccentColor
                textColor: root.filledTextColor
                buttonIcon: root.icon
                iconFontSize: Math.round(root.iconFontSize)
                enabled: false
            }

            Row {
                anchors.verticalCenter: filledCardIcon.verticalCenter
                anchors.right: parent.right
                spacing: root.s(4)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.fontFamily
                    font.weight: Font.DemiBold
                    font.pixelSize: root.midTextFontSize
                    color: root.filledMidTextColor
                    text: root.midText
                    visible: root.midText !== ""
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.fontFamily
                    font.weight: Font.DemiBold
                    font.pixelSize: root.titleFontSize
                    color: root.filledTitleColor
                    text: root.title
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: root.s(1)
                font.family: root.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: root.subTextFontSize
                color: root.filledSubTextColor
                text: root.subText
                visible: root.subText !== ""
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                font.family: root.fontFamily
                font.weight: Font.Black
                font.pixelSize: root.valueFontSize
                color: root.filledTextColor
                text: root.valueText
            }
        }
    }

    Item {
        id: customContentBox
        anchors.fill: parent
        anchors.margins: root.contentMargins
        z: 10
    }
}
