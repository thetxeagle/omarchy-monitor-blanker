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
  moduleName: "io.github.omarchy.monitor-blanker"
  readonly property string scriptPath: Qt.resolvedUrl("monitor-blanker").toString().replace(/^file:\/\//, "")
  property bool popupOpen: false
  property var monitors: []
  property var arrangement: ({})
  property bool arrangementDirty: false
  readonly property bool opened: popupOpen

  function open() { popupOpen = true; refreshMonitors() }
  function close() { popupOpen = false }
  function togglePopup() { popupOpen ? close() : open() }
  function refreshMonitors() { if (!monitorInfoProcess.running) monitorInfoProcess.running = true }

  function run(action, monitor, extra) {
    if (!monitor) return
    root.close()
    var args = [root.scriptPath, action, monitor]
    if (extra !== undefined) args.push(String(extra))
    Quickshell.execDetached(args)
    refreshTimer.restart()
  }

  function forceRefresh() {
    root.close()
    Quickshell.execDetached([root.scriptPath, "refresh"])
    refreshTimer.restart()
  }

  function cleanVendor(value) {
    return String(value || "").replace(/\b(Electric Company|Electronics Co\.?\s*Ltd\.?|Technology Co\.?\s*Ltd\.?|Corporation|Incorporated|Inc\.?|Corp\.?)\b/gi, "").replace(/\s+/g, " ").trim()
  }

  function friendlyName(monitor) {
    if (!monitor) return "Unknown display"
    if (/^(eDP|LVDS|DSI)-/i.test(String(monitor.name || ""))) return "Built-in Display"
    var make = cleanVendor(monitor.make)
    var model = String(monitor.model || "").trim()
    if (/^0x[0-9a-f]+$/i.test(model)) model = ""
    if (model) return make && make.toLowerCase() !== model.toLowerCase() ? make + " " + model : model
    return String(monitor.description || monitor.name || "Unknown display")
  }

  function monitorDetails(monitor) {
    if (!monitor) return ""
    var resolution = Number(monitor.width || 0) + " × " + Number(monitor.height || 0)
    var rate = Number(monitor.refreshRate || 0)
    return resolution + (rate ? " @ " + rate.toFixed(2).replace(/\.00$/, "") + " Hz" : "")
  }

  function coordinate(monitor, axis) {
    var saved = root.arrangement[monitor.name]
    return saved ? Number(saved[axis]) : Number(monitor[axis] || 0)
  }

  function setCoordinate(monitor, axis, value) {
    var next = {}
    for (var key in root.arrangement) next[key] = root.arrangement[key]
    if (!next[monitor.name]) next[monitor.name] = { x: monitor.x || 0, y: monitor.y || 0, transform: monitor.transform || 0 }
    next[monitor.name][axis] = Math.round(Number(value) || 0)
    root.arrangement = next
    root.arrangementDirty = true
  }

  function saveArrangement() {
    var args = [root.scriptPath, "save-arrangement"]
    for (var i = 0; i < root.monitors.length; i++) {
      var monitor = root.monitors[i]
      if (monitor.disabled) continue
      args.push(monitor.name, String(coordinate(monitor, "x")), String(coordinate(monitor, "y")))
    }
    root.arrangementDirty = false
    Quickshell.execDetached(args)
    refreshTimer.restart()
  }

  Component.onCompleted: {
    refreshMonitors()
    Quickshell.execDetached([root.scriptPath, "refresh"])
  }
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
    id: monitorInfoProcess
    command: ["bash", "-lc", "hyprctl monitors all -j | jq -c '[.[] | {name, make, model, description, x, y, width, height, refreshRate, scale, transform, disabled, focused}]'"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var parsed = JSON.parse(String(text || "[]"))
          root.monitors = Array.isArray(parsed) ? parsed : []
          if (!root.arrangementDirty) {
            var next = {}
            for (var i = 0; i < root.monitors.length; i++) {
              var monitor = root.monitors[i]
              next[monitor.name] = { x: monitor.x || 0, y: monitor.y || 0, transform: monitor.transform || 0 }
            }
            root.arrangement = next
          }
        } catch (e) {
          console.warn("monitor-blanker: unable to read monitor info: " + e)
        }
      }
    }
  }

  Timer { id: refreshTimer; interval: 700; onTriggered: root.refreshMonitors() }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(520))
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
        text: "Disable, rotate, arrange, and re-apply displays."
        color: Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: root.monitors
        delegate: Column {
          width: column.width
          spacing: Style.space(3)

          RowLayout {
            width: parent.width
            spacing: Style.space(8)

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                Layout.fillWidth: true
                text: root.friendlyName(modelData) + " (" + modelData.name + ")" + (modelData.focused ? " — Focused" : "")
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                font.bold: modelData.focused
                elide: Text.ElideRight
              }

              Text {
                text: root.monitorDetails(modelData) + " · " + (modelData.disabled ? "Disabled" : "Active")
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            ComboBox {
              implicitWidth: Style.space(82)
              model: ["0°", "90°", "180°", "270°"]
              currentIndex: Number(modelData.transform || 0)
              onActivated: root.run("rotate", modelData.name, currentIndex)
            }

            Button {
              text: modelData.disabled ? "Restore" : "Disable"
              enabled: modelData.disabled || root.monitors.filter(function(m) { return !m.disabled }).length > 1
              onClicked: root.run(modelData.disabled ? "restore" : "disable", modelData.name)
            }
          }
        }
      }

      PanelSeparator { foreground: root.bar.foreground }

      Text {
        text: "Arrangement"
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }

      Text {
        text: "Set each monitor's layout position. Changes are saved for the next refresh."
        color: Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Repeater {
        model: root.monitors.filter(function(m) { return !m.disabled })
        delegate: RowLayout {
          width: column.width
          spacing: Style.space(6)

          Text {
            Layout.fillWidth: true
            text: root.friendlyName(modelData)
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            elide: Text.ElideRight
          }

          Text { text: "X"; color: root.bar.foreground }
          SpinBox {
            from: -32768; to: 32767; stepSize: 1
            value: root.coordinate(modelData, "x")
            onValueModified: root.setCoordinate(modelData, "x", value)
          }
          Text { text: "Y"; color: root.bar.foreground }
          SpinBox {
            from: -32768; to: 32767; stepSize: 1
            value: root.coordinate(modelData, "y")
            onValueModified: root.setCoordinate(modelData, "y", value)
          }
        }
      }

      RowLayout {
        width: column.width
        Button {
          text: root.arrangementDirty ? "Save arrangement" : "Arrangement saved"
          enabled: root.arrangementDirty
          onClicked: root.saveArrangement()
        }
        Item { Layout.fillWidth: true }
        Switch {
          text: "Re-apply config"
          checked: false
          onClicked: root.forceRefresh()
        }
      }
    }
  }
}
