import QtQuick
import LsiTools

// Shown when content could not be loaded. Nothing stale is displayed in its
// place, because an out-of-date status or download link would be worse than none.
PageScroll {
    H {
        level: 1
        text: "Content is unavailable"
    }

    P {
        lede: true
        text: "The site could not load its content, so product and download details are not shown."
    }

    P {
        text: Store.errorText
    }

    AppButton {
        text: "Try again"
        onClicked: Store.load()
    }
}
