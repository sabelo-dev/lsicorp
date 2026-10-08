import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import LsiTools

// How to reach LSI Corp: published contact details and an enquiry form.
// Problems are shown next to the field they belong to, what was typed is
// always kept, and the outcome of sending is stated in words.
PageScroll {
    id: page

    property bool busy: false
    property bool sent: false
    /// Why the last attempt to send failed, when the cause was not something the visitor entered.
    property string message: ""
    /// Problems with what was entered, by field. Each clears when its field is edited.
    property var errors: ({})

    readonly property bool hasDetails: !!Store.site.contact_email || !!Store.site.contact_phone || !!Store.site.location

    function clearError(field) {
        if (!errors[field])
            return;
        const rest = Object.assign({}, errors);
        delete rest[field];
        errors = rest;
    }

    function send() {
        if (busy)
            return;
        const found = {};
        const email = emailField.text.trim();
        if (nameField.text.trim() === "")
            found.name = "Enter your name.";
        if (email === "")
            found.email = "Enter an email address we can reply to.";
        else if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email))
            found.email = "This does not look like an email address. Check for a missing @ or ending.";
        if (messageField.text.trim().length < 10)
            found.message = "Tell us a little more (at least 10 characters).";
        if (!consent.checked)
            found.consent = "Tick the box so that we may use these details to reply.";
        errors = found;
        message = "";
        // The keyboard goes to the first field that needs attention.
        const first = found.name ? nameField : found.email ? emailField : found.message ? messageField : found.consent ? consent : null;
        if (first) {
            first.forceActiveFocus();
            const count = Object.keys(found).length;
            page.Accessible.announce("Not sent. " + count + (count === 1 ? " field needs" : " fields need") + " attention.", Accessible.Assertive);
            return;
        }
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
            if (error) {
                message = error.message;
                page.Accessible.announce("Your enquiry was not sent.", Accessible.Assertive);
            } else {
                sent = true;
                page.Accessible.announce("Your enquiry has been sent.");
            }
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
        body: "It has gone to the " + Store.site.short_name + " team, who reply by email to the address you gave. Nothing you sent is published."
    }

    AppButton {
        visible: page.sent
        text: "Back to the home page"
        to: "/"
        secondary: true
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

        P {
            text: "Your enquiry goes to the " + Store.site.short_name + " team, who reply by email. It is not published. Fields are required unless marked optional."
        }

        FieldLabel {
            text: "Your name (required)"
            error: page.errors.name || ""

            Input {
                id: nameField
                invalid: !!page.errors.name
                Accessible.name: "Your name, required"
                Accessible.description: page.errors.name || ""
                onTextEdited: page.clearError("name")
            }
        }

        FieldLabel {
            text: "Email address (required)"
            hint: "Used only to reply to you."
            error: page.errors.email || ""

            Input {
                id: emailField
                invalid: !!page.errors.email
                placeholderText: "name@example.com"
                inputMethodHints: Qt.ImhEmailCharactersOnly | Qt.ImhNoAutoUppercase
                Accessible.name: "Email address, required"
                Accessible.description: page.errors.email || ""
                onTextEdited: page.clearError("email")
            }
        }

        FieldLabel {
            text: "Organisation (optional)"

            Input {
                id: organisationField
                Accessible.name: "Organisation, optional"
            }
        }

        FieldLabel {
            text: "What is it about? (optional)"

            ChipRow {
                id: topic
                label: "What is it about?"
                options: [{ value: "", text: "Not sure yet" }].concat(Store.services.map(s => ({ value: s.slug, text: s.name })))
            }
        }

        FieldLabel {
            text: "Message (required)"
            hint: "Please do not include passwords, payment details or other sensitive information."
            error: page.errors.message || ""

            TextArea {
                id: messageField
                Layout.fillWidth: true
                Layout.minimumHeight: 160
                padding: Theme.s3
                color: Theme.ink
                wrapMode: TextArea.Wrap
                selectByMouse: true
                font.pixelSize: Theme.body
                Accessible.name: "Message, required"
                Accessible.description: page.errors.message || ""
                onActiveFocusChanged: if (activeFocus) Theme.reveal(messageField)
                onTextChanged: page.clearError("message")
                // Tab moves on to the next control instead of typing a tab into the message.
                KeyNavigation.priority: KeyNavigation.BeforeItem
                KeyNavigation.tab: consent

                background: Rectangle {
                    color: Theme.surface
                    border.color: messageField.activeFocus ? Theme.focus : page.errors.message ? Theme.danger : Theme.controlBorder
                    border.width: messageField.activeFocus || page.errors.message ? 2 : 1
                    radius: Theme.controlRadius
                }
            }
        }

        FieldLabel {
            text: "Your agreement (required)"
            error: page.errors.consent || ""

            CheckBox {
                id: consent
                Layout.fillWidth: true
                text: "I agree that " + Store.site.short_name + " may use these details to reply to my enquiry."
                font.pixelSize: Theme.body
                Accessible.name: text
                Accessible.description: page.errors.consent || ""
                onToggled: page.clearError("consent")
                onActiveFocusChanged: if (activeFocus) Theme.reveal(consent)
            }
        }

        LinkText {
            text: "How we handle your details: privacy notice"
            to: "/support/privacy"
            font.pixelSize: Theme.small
        }

        // Stays until the next attempt: a failure to send must not be missed.
        Notice {
            visible: page.message !== ""
            tone: "withdrawn"
            title: "Your enquiry was not sent"
            body: page.message + " What you typed is still here, and it is safe to try again."
        }

        AppButton {
            text: page.busy ? "Sending…" : page.message !== "" ? "Try again" : "Send enquiry"
            busy: page.busy
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
