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

  function enabledMonitors() { return root.monitors.filter(function(m) { return !m.disabled }) }

  function arrangementBounds() {
    var list = enabledMonitors()
    if (!list.length) return { minX: 0, minY: 0, width: 1, height: 1 }
    var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
    for (var i = 0; i < list.length; i++) {
      var monitor = list[i]
      var scale = Number(monitor.scale || 1)
      var width = Number(monitor.width || 1) / scale
      var height = Number(monitor.height || 1) / scale
      var x = coordinate(monitor, "x")
      var y = coordinate(monitor, "y")
      minX = Math.min(minX, x); minY = Math.min(minY, y)
      maxX = Math.max(maxX, x + width); maxY = Math.max(maxY, y + height)
    }
    return { minX: minX, minY: minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) }
  }

  function arrangementScale() {
    var bounds = arrangementBounds()
    return Math.min((arrangementCanvas.width - 16) / bounds.width, (arrangementCanvas.height - 16) / bounds.height)
  }

  function boxX(monitor) { return 8 + (coordinate(monitor, "x") - arrangementBounds().minX) * arrangementScale() }
  function boxY(monitor) { return 8 + (coordinate(monitor, "y") - arrangementBounds().minY) * arrangementScale() }
  function boxWidth(monitor) { return Math.max(56, Number(monitor.width || 1) / Number(monitor.scale || 1) * arrangementScale()) }
  function boxHeight(monitor) { return Math.max(38, Number(monitor.height || 1) / Number(monitor.scale || 1) * arrangementScale()) }
  function canvasX(x) { return Math.round((x - 8) / arrangementScale() + arrangementBounds().minX) }
  function canvasY(y) { return Math.round((y - 8) / arrangementScale() + arrangementBounds().minY) }

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
        text: "Drag displays into position, then save the arrangement."
        color: Qt.darker(root.bar.foreground, 1.4)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption
        wrapMode: Text.WordWrap
      }

      Rectangle {
        id: arrangementCanvas
        width: column.width
        height: Style.space(170)
        radius: Style.space(6)
        color: Qt.darker(root.bar.background, 1.25)
        border.color: Qt.darker(root.bar.foreground, 1.8)
        clip: true

        Repeater {
          model: root.enabledMonitors()
          delegate: Rectangle {
            id: monitorBox
            property var monitorData: modelData
            property bool dragging: false
            property real dragOffsetX: 0
            property real dragOffsetY: 0
            x: root.boxX(monitorData)
            y: root.boxY(monitorData)
            width: Math.min(arrangementCanvas.width - 16, root.boxWidth(monitorData))
            height: Math.min(arrangementCanvas.height - 16, root.boxHeight(monitorData))
            radius: Style.space(4)
            color: monitorData.focused ? Qt.lighter(root.bar.foreground, 1.25) : Qt.darker(root.bar.foreground, 1.35)
            border.color: root.bar.foreground
            border.width: 1

            Text {
              anchors.centerIn: parent
              width: parent.width - Style.space(8)
              text: monitorData.name
              color: root.bar.background
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              horizontalAlignment: Text.AlignHCenter
              elide: Text.ElideRight
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.OpenHandCursor
              onPressed: {
                monitorBox.dragging = true
                monitorBox.dragOffsetX = mouseX
                monitorBox.dragOffsetY = mouseY
                cursorShape = Qt.ClosedHandCursor
              }
              onPositionChanged: {
                if (!pressed) return
                var nextX = Math.max(8, Math.min(arrangementCanvas.width - monitorBox.width - 8, mouseX + monitorBox.x - monitorBox.dragOffsetX))
                var nextY = Math.max(8, Math.min(arrangementCanvas.height - monitorBox.height - 8, mouseY + monitorBox.y - monitorBox.dragOffsetY))
                monitorBox.x = nextX
                monitorBox.y = nextY
              }
              onReleased: {
                root.setCoordinate(monitorData, "x", root.canvasX(monitorBox.x))
                root.setCoordinate(monitorData, "y", root.canvasY(monitorBox.y))
                monitorBox.dragging = false
                monitorBox.x = root.boxX(monitorData)
                monitorBox.y = root.boxY(monitorData)
                cursorShape = Qt.OpenHandCursor
              }
            }
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
