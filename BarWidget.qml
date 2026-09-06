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
  property var canvasBounds: null
  property bool arrangementDirty: false
  property string arrangementStatus: "Arrangement saved"
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

  function restartShell() {
    root.close()
    Quickshell.execDetached(["omarchy-restart-shell"])
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
    root.arrangementStatus = "Unsaved changes"
  }

  function setMonitorPosition(monitor, x, y) {
    var next = {}
    for (var key in root.arrangement) next[key] = root.arrangement[key]
    if (!next[monitor.name]) next[monitor.name] = { x: monitor.x || 0, y: monitor.y || 0, transform: monitor.transform || 0 }
    next[monitor.name].x = Math.round(Number(x) || 0)
    next[monitor.name].y = Math.round(Number(y) || 0)
    root.arrangement = next
    root.arrangementDirty = true
    root.arrangementStatus = "Unsaved changes"
  }

  function monitorFootprint(monitor) {
    var scale = Number(monitor.scale || 1)
    var width = Number(monitor.width || 1) / scale
    var height = Number(monitor.height || 1) / scale
    if (Number(monitor.transform || 0) === 1 || Number(monitor.transform || 0) === 3)
      return { width: height, height: width }
    return { width: width, height: height }
  }

  function monitorRect(monitor, x, y) {
    var footprint = monitorFootprint(monitor)
    return { x: x, y: y, width: footprint.width, height: footprint.height }
  }

  function rectanglesOverlap(a, b) {
    return a.x < b.x + b.width && a.x + a.width > b.x
      && a.y < b.y + b.height && a.y + a.height > b.y
  }

  function snappedPosition(monitor, x, y) {
    var footprint = monitorFootprint(monitor)
    var others = []
    var list = enabledMonitors()
    for (var i = 0; i < list.length; i++) {
      if (list[i].name === monitor.name) continue
      others.push({ monitor: list[i], rect: monitorRect(list[i], coordinate(list[i], "x"), coordinate(list[i], "y")) })
    }

    var candidates = []
    for (var j = 0; j < others.length; j++) {
      var other = others[j].rect
      candidates.push({ x: other.x + other.width, y: other.y, distance: Math.hypot(x - (other.x + other.width), y - other.y), snapped: true })
      candidates.push({ x: other.x - footprint.width, y: other.y, distance: Math.hypot(x - (other.x - footprint.width), y - other.y), snapped: true })
      candidates.push({ x: other.x, y: other.y + other.height, distance: Math.hypot(x - other.x, y - (other.y + other.height)), snapped: true })
      candidates.push({ x: other.x, y: other.y - footprint.height, distance: Math.hypot(x - other.x, y - (other.y - footprint.height)), snapped: true })
    }

    var bestSnapped = null
    for (var k = 0; k < candidates.length; k++) {
      var candidate = candidates[k]
      var candidateRect = monitorRect(monitor, candidate.x, candidate.y)
      var valid = true
      for (var n = 0; n < others.length; n++) {
        if (rectanglesOverlap(candidateRect, others[n].rect)) { valid = false; break }
      }
      if (!valid) continue
      if (!bestSnapped || candidate.distance < bestSnapped.distance) bestSnapped = candidate
    }
    return bestSnapped ? { x: Math.round(bestSnapped.x), y: Math.round(bestSnapped.y) } : { x: Math.round(x), y: Math.round(y) }
  }

  function saveArrangement() {
    var args = [root.scriptPath, "save-arrangement"]
    for (var i = 0; i < root.monitors.length; i++) {
      var monitor = root.monitors[i]
      if (monitor.disabled) continue
      args.push(monitor.name, String(coordinate(monitor, "x")), String(coordinate(monitor, "y")))
    }
    root.arrangementDirty = false
    root.arrangementStatus = "Applying saved arrangement..."
    Quickshell.execDetached(args)
    root.arrangementStatus = "Arrangement saved and applied"
    refreshTimer.restart()
  }

  function enabledMonitors() { return root.monitors.filter(function(m) { return !m.disabled }) }

  function calculateArrangementBounds() {
    var list = enabledMonitors()
    if (!list.length) return { minX: 0, minY: 0, width: 1, height: 1 }
    var minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity
    for (var i = 0; i < list.length; i++) {
      var monitor = list[i]
      var scale = Number(monitor.scale || 1)
      var footprint = root.monitorFootprint(monitor)
      var width = footprint.width
      var height = footprint.height
      var x = coordinate(monitor, "x")
      var y = coordinate(monitor, "y")
      minX = Math.min(minX, x); minY = Math.min(minY, y)
      maxX = Math.max(maxX, x + width); maxY = Math.max(maxY, y + height)
    }
    return { minX: minX, minY: minY, width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) }
  }

  function arrangementBounds() { return root.canvasBounds || root.calculateArrangementBounds() }

  function arrangementScale() {
    var bounds = arrangementBounds()
    return Math.min((arrangementCanvas.width - 16) / bounds.width, (arrangementCanvas.height - 16) / bounds.height)
  }

  function arrangementOffsetX(bounds, scale) { return Math.max(8, (arrangementCanvas.width - bounds.width * scale) / 2) }
  function arrangementOffsetY(bounds, scale) { return Math.max(8, (arrangementCanvas.height - bounds.height * scale) / 2) }
  function boxX(monitor) {
    var bounds = arrangementBounds(), scale = arrangementScale()
    var footprint = monitorFootprint(monitor)
    var x = arrangementOffsetX(bounds, scale) + (coordinate(monitor, "x") + footprint.width / 2 - bounds.minX) * scale - boxWidth(monitor) / 2
    return Math.max(0, Math.min(arrangementCanvas.width - boxWidth(monitor), x))
  }
  function boxY(monitor) {
    var bounds = arrangementBounds(), scale = arrangementScale()
    var footprint = monitorFootprint(monitor)
    var y = arrangementOffsetY(bounds, scale) + (coordinate(monitor, "y") + footprint.height / 2 - bounds.minY) * scale - boxHeight(monitor) / 2
    return Math.max(0, Math.min(arrangementCanvas.height - boxHeight(monitor), y))
  }
  function boxWidth(monitor) { return 116 }
  function boxHeight(monitor) { return 68 }
  function canvasX(x, monitor, bounds, scale) {
    var footprint = monitorFootprint(monitor)
    return Math.round((x + boxWidth(monitor) / 2 - arrangementOffsetX(bounds, scale)) / scale + bounds.minX - footprint.width / 2)
  }
  function canvasY(y, monitor, bounds, scale) {
    var footprint = monitorFootprint(monitor)
    return Math.round((y + boxHeight(monitor) / 2 - arrangementOffsetY(bounds, scale)) / scale + bounds.minY - footprint.height / 2)
  }

  Component.onCompleted: {
    refreshMonitors()
    Quickshell.execDetached([root.scriptPath, "apply"])
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
    command: [root.scriptPath, "state"]
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
          root.canvasBounds = root.calculateArrangementBounds()
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
        height: Style.space(230)
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
            property var dragBounds: ({})
            property real dragScale: 1
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
                monitorBox.dragBounds = root.arrangementBounds()
                monitorBox.dragScale = root.arrangementScale()
                monitorBox.dragOffsetX = mouseX
                monitorBox.dragOffsetY = mouseY
                cursorShape = Qt.ClosedHandCursor
              }
              onPositionChanged: {
                if (!pressed) return
                var nextX = Math.max(0, Math.min(arrangementCanvas.width - monitorBox.width, mouseX + monitorBox.x - monitorBox.dragOffsetX))
                var nextY = Math.max(0, Math.min(arrangementCanvas.height - monitorBox.height, mouseY + monitorBox.y - monitorBox.dragOffsetY))
                monitorBox.x = nextX
                monitorBox.y = nextY
              }
              onReleased: {
                var nextX = root.canvasX(monitorBox.x, monitorData, monitorBox.dragBounds, monitorBox.dragScale)
                var nextY = root.canvasY(monitorBox.y, monitorData, monitorBox.dragBounds, monitorBox.dragScale)
                var snapped = root.snappedPosition(monitorData, nextX, nextY)
                root.setMonitorPosition(monitorData, snapped.x, snapped.y)
                monitorBox.dragging = false
                cursorShape = Qt.OpenHandCursor
              }
            }
          }
        }
      }

      RowLayout {
        width: column.width
        Button {
          text: "Save arrangement"
          enabled: root.arrangementDirty
          onClicked: root.saveArrangement()
        }
        Item { Layout.fillWidth: true }
        Text {
          text: root.arrangementStatus
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.caption
        }
        Button {
          text: "Re-apply config"
          onClicked: root.forceRefresh()
        }
      }
      RowLayout {
        width: column.width
        Item { Layout.fillWidth: true }
        Button {
          text: "Restart shell"
          onClicked: root.restartShell()
        }
      }
    }
  }
}
