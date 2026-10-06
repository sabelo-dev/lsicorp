import QtQuick
import QtQuick.Layouts
import LsiTools
import "rules.mjs" as Rules

// Platform-aware download block: one section per platform a product targets,
// with either the releases a visitor can act on or a clear non-download state.
ColumnLayout {
    id: root

    property var product
    /// Show only this platform ("" for all).
    property string only: ""

    readonly property var releases: Store.releasesFor(product.slug)
    readonly property var platforms: Rules.platformsFor(product, releases)
    readonly property var shown: only === "" ? platforms : platforms.filter(p => p === only)

    Layout.fillWidth: true
    spacing: Theme.s4

    EmptyState {
        visible: root.platforms.length === 0 && root.only === ""
        text: "Coming Soon. Supported platforms for " + root.product.public_name
              + " have not been confirmed, so there is nothing to download yet."
    }

    EmptyState {
        visible: root.only !== "" && root.shown.length === 0
        text: "No release available for " + (Rules.PLATFORMS[root.only] || "") + "."
    }

    Repeater {
        model: root.shown

        ColumnLayout {
            id: platformBlock

            required property string modelData
            readonly property var available: Rules.availableReleases(root.releases, root.product.slug, modelData)

            Layout.fillWidth: true
            spacing: Theme.s3

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.border
            }

            H {
                level: 4
                text: Rules.PLATFORMS[platformBlock.modelData]
            }

            EmptyState {
                visible: platformBlock.available.length === 0
                text: "No release available for " + Rules.PLATFORMS[platformBlock.modelData] + "."
            }

            Repeater {
                model: platformBlock.available

                ColumnLayout {
                    id: releaseBlock

                    required property var modelData

                    Layout.fillWidth: true
                    spacing: Theme.s3

                    ReleaseAction {
                        release: releaseBlock.modelData
                        productName: root.product.public_name
                    }

                    ReleaseFacts {
                        release: releaseBlock.modelData
                    }

                    LinkText {
                        text: releaseBlock.modelData.destination_type === "web-app" ? "How to get started, and notes" : "Install steps and release notes"
                        to: Rules.releasePath(releaseBlock.modelData)
                        font.pixelSize: Theme.small
                        Accessible.name: text + " for " + root.product.public_name + " " + releaseBlock.modelData.version
                                         + " on " + Rules.PLATFORMS[releaseBlock.modelData.platform]
                    }
                }
            }
        }
    }
}
