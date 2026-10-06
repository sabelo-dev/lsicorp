import QtQuick
import LsiTools

// Small line icons, drawn rather than loaded so they are sharp at any size
// and take the surrounding text colour. name: search, sun, moon, auto, close, arrow.
Canvas {
    id: icon

    property string name: "search"
    property color color: Theme.ink
    property int size: 20

    width: size
    height: size
    Accessible.ignored: true

    onNameChanged: requestPaint()
    onColorChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        const s = size;
        ctx.reset();
        ctx.strokeStyle = color;
        ctx.fillStyle = color;
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        if (name === "search") {
            ctx.beginPath();
            ctx.arc(s * 0.43, s * 0.43, s * 0.29, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(s * 0.65, s * 0.65);
            ctx.lineTo(s * 0.88, s * 0.88);
            ctx.stroke();
        } else if (name === "sun") {
            ctx.beginPath();
            ctx.arc(s / 2, s / 2, s * 0.2, 0, 2 * Math.PI);
            ctx.stroke();
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4;
                ctx.beginPath();
                ctx.moveTo(s / 2 + Math.cos(a) * s * 0.34, s / 2 + Math.sin(a) * s * 0.34);
                ctx.lineTo(s / 2 + Math.cos(a) * s * 0.44, s / 2 + Math.sin(a) * s * 0.44);
                ctx.stroke();
            }
        } else if (name === "moon") {
            ctx.beginPath();
            ctx.arc(s / 2, s / 2, s * 0.36, Math.PI * 0.35, Math.PI * 1.65);
            ctx.arc(s * 0.74, s / 2, s * 0.34, Math.PI * 1.35, Math.PI * 0.65, true);
            ctx.closePath();
            ctx.stroke();
        } else if (name === "auto") {
            // Half filled: follows the device.
            ctx.beginPath();
            ctx.arc(s / 2, s / 2, s * 0.36, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.beginPath();
            ctx.arc(s / 2, s / 2, s * 0.36, -Math.PI / 2, Math.PI / 2);
            ctx.closePath();
            ctx.fill();
        } else if (name === "close") {
            ctx.beginPath();
            ctx.moveTo(s * 0.22, s * 0.22);
            ctx.lineTo(s * 0.78, s * 0.78);
            ctx.moveTo(s * 0.78, s * 0.22);
            ctx.lineTo(s * 0.22, s * 0.78);
            ctx.stroke();
        } else if (name === "arrow") {
            ctx.beginPath();
            ctx.moveTo(s * 0.18, s / 2);
            ctx.lineTo(s * 0.82, s / 2);
            ctx.moveTo(s * 0.56, s * 0.24);
            ctx.lineTo(s * 0.82, s / 2);
            ctx.lineTo(s * 0.56, s * 0.76);
            ctx.stroke();
        }
    }
}
