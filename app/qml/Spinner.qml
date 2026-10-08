import QtQuick
import LsiTools

// A small turning ring that says work is in progress. Under reduced motion it
// is a still ring, so the words next to it must carry the meaning too.
Canvas {
    id: spinner

    property color color: Theme.ink
    property int size: 18
    property bool running: visible

    width: size
    height: size
    Accessible.ignored: true

    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.strokeStyle = color;
        ctx.globalAlpha = 0.3;
        ctx.beginPath();
        ctx.arc(size / 2, size / 2, size / 2 - 2, 0, 2 * Math.PI);
        ctx.stroke();
        ctx.globalAlpha = 1;
        ctx.beginPath();
        ctx.arc(size / 2, size / 2, size / 2 - 2, -Math.PI / 2, Math.PI / 6);
        ctx.stroke();
    }

    RotationAnimator on rotation {
        running: spinner.running && Theme.motion
        from: 0
        to: 360
        duration: 800
        loops: Animation.Infinite
    }
}
