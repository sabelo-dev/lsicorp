import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools

// How to reach LSI Corp: published contact details and an enquiry form.
PageScroll {
    id: page

    property bool busy: false
    property bool sent: false
    property string message: ""

    readonly property bool hasDetails: !!Store.site.contact_email || !!Store.site.contact_phone || !!Store.site.location

    function send() {
        const problems = [];
        const email = emailField.text.trim();
        if (nameField.text.trim() === "")
            problems.push("Enter your name.");
        if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email))
            problems.push("Enter an email address we can reply to.");
        if (messageField.text.trim().length < 10)
            problems.push("Tell us a little more in the message (at least 10 characters).");
        if (!consent.checked)
            problems.push("Tick the box to agree to us using these details to reply.");
        if (problems.length > 0) {
            message = problems.join("\n");
            return;
        }
        message = "";
        busy = true;
        Store.sendEnquiry({
            name: nameField.text.trim(),
            email: email,
            organisation: organisationField.text.trim() || null,
            service_slug: topic.value || null,
            message: messageField.text.trim(),
            consent: true
        }, function (error) {
            busy = false;
            if (error)
                message = error.message;
            else
                sent = true;
        });
    }

    Breadcrumbs {
        items: [{ label: "Contact" }]
    }

    H {
        level: 1
        text: "Contact"
    }

    P {
        lede: true
        text: "Tell us what you are building or where things are getting stuck. We will come back to you."
    }

    Card {
        visible: page.hasDetails
        Layout.maximumWidth: Theme.measure

        Facts {
            model: [
                { label: "Email", value: Store.site.contact_email },
                { label: "Phone", value: Store.site.contact_phone },
                { label: "Location", value: Store.site.location }
            ].filter(row => !!row.value)
        }
    }

    H {
        text: "Send an enquiry"
    }

    // After sending
    Notice {
        visible: page.sent
        tone: "available"
        title: "Thank you. Your enquiry has been sent."
        body: "We will reply to the email address you gave."
    }

    EmptyState {
        visible: !page.sent && !Supabase.configured
        text: "The enquiry form is unavailable on this copy of the site, because it is not connected to its content service."
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: 620
        visible: !page.sent && Supabase.configured
        spacing: Theme.s4

        FieldLabel {
            text: "Your name (required)"

            Input {
                id: nameField
                Accessible.name: "Your name"
            }
        }

        FieldLabel {
            text: "Email address (required)"

            Input {
                id: emailField
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                Accessible.name: "Email address"
            }
        }

        FieldLabel {
            text: "Organisation"

            Input {
                id: organisationField
                Accessible.name: "Organisation"
            }
        }

        FieldLabel {
            text: "What is it about?"

            ChipRow {
                id: topic
                label: "What is it about?"
                options: [{ value: "", text: "Not sure yet" }].concat(Store.services.map(s => ({ value: s.slug, text: s.name })))
            }
        }

        FieldLabel {
            text: "Message (required)"
            hint: "Please do not include passwords, payment details or other sensitive information."

            TextArea {
                id: messageField
                Layout.fillWidth: true
                Layout.minimumHeight: 160
                padding: Theme.s3
                color: Theme.ink
                wrapMode: TextArea.Wrap
                selectByMouse: true
                font.pixelSize: Theme.body
                Accessible.name: "Message"
                onActiveFocusChanged: if (activeFocus) Theme.reveal(messageField)

                background: Rectangle {
                    color: Theme.surface
                    border.color: messageField.activeFocus ? Theme.focus : Theme.muted
                    border.width: messageField.activeFocus ? 2 : 1
                    radius: Theme.controlRadius
                }
            }
        }

        CheckBox {
            id: consent
            Layout.fillWidth: true
            text: "I agree that " + Store.site.short_name + " may use these details to reply to my enquiry."
            font.pixelSize: Theme.body
            Accessible.name: text
        }

        LinkText {
            text: "How we handle your details: privacy notice"
            to: "/support/privacy"
            font.pixelSize: Theme.small
        }

        P {
            visible: page.message !== ""
            color: Theme.danger
            text: page.message
            Accessible.role: Accessible.AlertMessage
        }

        AppButton {
            text: page.busy ? "Sending…" : "Send enquiry"
            enabled: !page.busy
            onClicked: page.send()
        }
    }

    H {
        text: "Looking for help with a product?"
    }

    ListLink {
        text: "Support and documentation"
        description: "Guides and troubleshooting for the products in our portfolio."
        to: "/support"
    }
}
