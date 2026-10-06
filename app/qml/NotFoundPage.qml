import QtQuick
import QtQuick.Layouts
import LsiTools

PageScroll {
    H {
        level: 1
        text: "Page not found"
    }

    P {
        lede: true
        text: "There is nothing at this address. It may have moved, or the link may be wrong."
    }

    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3

        AppButton {
            text: "See our work"
            to: "/work"
        }

        AppButton {
            text: "Go to the home page"
            to: "/"
            secondary: true
        }
    }
}
