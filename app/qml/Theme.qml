pragma Singleton
import QtQuick
import LsiTools

// Design tokens, built on the LSI brand: navy #01245d and gold #ddab22.
// Text and control colours are chosen to meet WCAG AA contrast in both schemes.
//
// The look is crisp and flat: near-white surfaces separated by hairline
// borders rather than shadows, small corner radii, squared controls and
// tight headings. Navy carries actions and the brand bands; gold is an accent.
QtObject {
    /// "system" follows the device; "light" and "dark" are the visitor's own choice, remembered between visits.
    property string mode: "system"
    readonly property bool dark: mode === "dark" || (mode === "system" && (Platform.devDark || Qt.styleHints.colorScheme === Qt.ColorScheme.Dark))

    Component.onCompleted: {
        const saved = Platform.stored("theme");
        if (saved === "light" || saved === "dark")
            mode = saved;
    }

    function cycleMode() {
        mode = mode === "system" ? "light" : mode === "light" ? "dark" : "system";
        Platform.store("theme", mode === "system" ? "" : mode);
    }

    /// Animation is skipped entirely for visitors who ask their system for reduced motion.
    readonly property bool motion: !Platform.reducedMotion
    readonly property int fast: motion ? 130 : 0
    readonly property int medium: motion ? 240 : 0
    readonly property int slow: motion ? 420 : 0

    /// True once the current page has been scrolled; the header gains a shadow.
    property bool scrolled: false

    // Brand colours. Gold is decorative on light backgrounds (it is too pale for text there).
    readonly property color navy: "#01245d"
    readonly property color gold: "#ddab22"

    readonly property color bg: dark ? "#0a0e17" : "#fafbfc"
    readonly property color surface: dark ? "#10151f" : "#ffffff"
    readonly property color surfaceAlt: dark ? "#19202d" : "#f1f3f7"
    readonly property color ink: dark ? "#eef1f6" : "#0d1526"
    readonly property color muted: dark ? "#a3adc0" : "#4f5a70"
    /// Hairline between surfaces: decoration, so it may be faint.
    readonly property color border: dark ? "#232c3d" : "#e2e5ec"
    /// Edge of something to type in or press: at least 3:1 against the surface.
    readonly property color controlBorder: dark ? "#66728a" : "#848da0"
    readonly property color shadow: dark ? "#66000000" : "#1a0f1b33"
    /// One layer of a soft shadow; several are stacked (see Shadow.qml).
    readonly property color shadowLayer: dark ? "#000000" : "#0f1b33"
    readonly property real shadowOpacity: dark ? 0.07 : 0.018
    readonly property color scrim: dark ? "#b3000000" : "#800f1b33"

    /// Filled buttons and selected controls.
    readonly property color primary: dark ? "#e2b436" : "#01245d"
    readonly property color primaryHover: dark ? "#f0c75a" : "#0a357f"
    readonly property color primaryInk: dark ? "#0a1222" : "#ffffff"
    /// Soft tint behind a selected navigation item or chip.
    readonly property color primarySoft: dark ? "#272618" : "#e8edf7"

    /// Links.
    readonly property color accent: dark ? "#8db4ff" : "#0e45a6"
    readonly property color accentHover: dark ? "#b9d1ff" : "#01245d"

    readonly property color focus: dark ? "#f0c552" : "#0e45a6"
    readonly property color danger: dark ? "#ff9d94" : "#a3231b"

    /// The hero band and other full-brand areas: always navy with white text.
    readonly property color heroTop: dark ? "#0c1a36" : "#01245d"
    readonly property color heroBottom: dark ? "#0f2145" : "#032a6b"
    readonly property color onHero: "#ffffff"
    readonly property color onHeroMuted: "#c9d6f2"
    /// Hairlines and quiet panels on the navy band.
    readonly property color heroLine: "#33ffffff"
    readonly property color heroPanel: "#14ffffff"

    readonly property var tones: ({
        "available": dark ? ["#12331f", "#8fe0aa"] : ["#dff3e6", "#125227"],
        "in-development": dark ? ["#3a2c08", "#f3cf7a"] : ["#fbeecb", "#694300"],
        "planned": dark ? ["#3a2c08", "#f3cf7a"] : ["#fbeecb", "#694300"],
        "in-review": dark ? ["#3a2c08", "#f3cf7a"] : ["#fbeecb", "#694300"],
        "coming-soon": dark ? ["#142a55", "#b3cdff"] : ["#e0eafc", "#123f8c"],
        "maintenance": dark ? ["#431a18", "#ffb3ac"] : ["#fbe3e0", "#8a1f18"],
        "withdrawn": dark ? ["#431a18", "#ffb3ac"] : ["#fbe3e0", "#8a1f18"],
        "neutral": dark ? ["#1f2c4a", "#c5cfe3"] : ["#e6eaf3", "#3c4763"]
    })

    function tone(name) {
        return tones[name] || tones["neutral"];
    }

    readonly property string mono: "monospace"

    readonly property int small: 14
    /// Text on buttons, chips and navigation.
    readonly property int label: 15
    readonly property int body: 16
    readonly property int h3: 18
    readonly property int h2: 24
    readonly property int h1: 38

    readonly property int s1: 4
    readonly property int s2: 8
    readonly property int s3: 12
    readonly property int s4: 16
    readonly property int s5: 24
    readonly property int s6: 32
    readonly property int s7: 48

    /// Width of the window, set by Main. Layouts switch to one column when narrow.
    property real viewWidth: 1200
    readonly property bool narrow: viewWidth < 720
    /// Side margin of page content.
    readonly property int gutter: narrow ? 16 : 24

    readonly property int radius: 8
    readonly property int controlRadius: 6
    /// Smallest comfortable size for something a finger has to hit.
    readonly property int touch: 48
    /// Height of buttons, inputs and chips: compact with a pointer, finger-sized on a small screen.
    readonly property int control: narrow ? touch : 40
    /// Height of secondary controls in a row (chips, navigation).
    readonly property int controlSmall: narrow ? 44 : 34
    readonly property int maxWidth: 1120
    readonly property int measure: 720

    /// Scrolls the enclosing page so that a newly focused control is visible.
    function reveal(item) {
        for (let p = item.parent; p; p = p.parent) {
            if (typeof p.revealItem === "function") {
                p.revealItem(item);
                return;
            }
        }
    }
}
