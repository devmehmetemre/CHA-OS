import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

// CHA SDDM - LXQt Edition, Qt bagimliligi zaten var, hafif QML (blur yok)
Rectangle {
    id: root
    width: 1920; height: 1080
    color: "#10151A"

    Image {
        id: bg
        anchors.fill: parent
        source: "/usr/share/backgrounds/cha/01-abyss-teal-1920.png"
        fillMode: Image.PreserveAspectCrop
    }
    Rectangle { anchors.fill: parent; color: "#80000000" }

    Column {
        anchors.centerIn: parent
        spacing: 12
        Text { text: "CHA OS"; font.family: "Inter"; font.pointSize: 36; font.bold: true; color: "#F2F4F3"; anchors.horizontalCenter: parent.horizontalCenter }
        Text { text: "2026.10 Kıvılcım"; font.family: "Inter"; font.pointSize: 11; color: "#0FB5A6"; anchors.horizontalCenter: parent.horizontalCenter }

        TextBox {
            id: user; width: 280; height: 36
            text: userModel.lastUser; font.family: "Inter"
            color: "#F2F4F3"
        }
        PasswordBox {
            id: pw; width: 280; height: 36
            font.family: "Inter"; echoMode: TextInput.Password
            color: "#F2F4F3"
            Keys.onReturnPressed: sddm.login(user.text, pw.text, session.index)
        }
        Button {
            width: 280; height: 38; text: "Giriş"
            background: Rectangle { color: "#0FB5A6"; radius: 8 }
            contentItem: Text { text: parent.text; color: "#10151A"; font.bold: true; horizontalAlignment: Text.AlignHCenter }
            onClicked: sddm.login(user.text, pw.text, session.index)
        }
        ComboBox {
            id: session; width: 280; model: sessionModel; textRole: "name"
        }
        Text { text: "Güç: F1 • Dil: F2"; color: "#5A6570"; font.pointSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
    }
    Connections {
        target: sddm
        onLoginFailed: { pw.text = ""; pw.focus = true; }
    }
    Component.onCompleted: { user.focus = true; }
}
