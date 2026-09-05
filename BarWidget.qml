import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "soulshocker.monitor-sleep"

  readonly property string scriptPath: Qt.resolvedUrl("monitor-blanker").toString().replace(/^file:\/\//, "")
  property bool popupOpen: false
  property var monitors: []
  readonly property bool opened: popupOpen

  function open() { popupOpen = true; refreshMonitors() }
  function close() { popupOpen = false }
  function togglePopup() { popupOpen ? close() : open() }

  function refreshMonitors() { monitorProcess.running = true }
  function run(action, monitor) {
    if (!monitor) return
    root.close()
    Quickshell.execDetached([root.scriptPath, action, monitor])
    refreshTimer.restart()
  }

  Component.onCompleted: refreshMonitors()

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰍹"
    slotSize: Style.bar.statusSlot
    fontSize: Style.font.caption
    tooltipText: "Monitor blanker"
    onPressed: root.togglePopup()
  }

  Process {
    id: monitorProcess
    command: ["omarchy-monitor-state"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var lines = String(text || "").split("\n")
          var monitors = JSON.parse(String(lines[7] || "[]").trim())
          root.monitors = Array.isArray(monitors) ? monitors : []
        } catch (e) { console.warn("monitor-blanker: unable to read monitors: " + e) }
      }
    }
  }

  Timer { id: refreshTimer; interval: 500; onTriggered: root.refreshMonitors() }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(390))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
    }

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Text {
        text: "Monitor Blanker"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.title
        font.bold: true
      }

      Text {
        text: "Disable or restore a monitor."
        color: Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: root.monitors
        delegate: RowLayout {
          width: column.width
          spacing: Style.space(8)

          Text {
            Layout.fillWidth: true
            text: modelData.name + (modelData.focused ? " · focused" : "")
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            elide: Text.ElideRight
          }

          Text {
            text: modelData.enabled ? "Active" : "Disabled"
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
          }

          Button {
            text: modelData.enabled ? "Disable" : "Restore"
            enabled: modelData.enabled ? root.monitors.filter(function(m) { return m.enabled }).length > 1 : true
            onClicked: root.run(modelData.enabled ? "disable" : "restore", modelData.name)
          }
        }
      }

      PanelSeparator { foreground: root.bar.foreground }
    }
  }
}
