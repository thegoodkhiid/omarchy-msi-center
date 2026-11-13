import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "tumi.msi-center"
  ipcTarget: "tumi.msi-center"
  manageIpc: false

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  readonly property string ctlScript: decodeURIComponent(String(Qt.resolvedUrl("bin/msi-center-ctl")).replace(/^(file|qs):\/\//, ""))
  readonly property bool showBarTemp: setting("showBarTemp", false) === true
  readonly property real openPanelIndicatorWidth: showBarTemp && !button.vertical ? button.glyphPaintedWidth : 0

  property var state: Model.defaultState()
  property string activeTab: "monitor"
  property string busyText: ""
  property string errorText: ""

  readonly property var tabs: [
    { id: "monitor",   icon: "󰍛", label: strings.t("tab.monitor") },
    { id: "scenarios", icon: "󰓅", label: strings.t("tab.scenarios") },
    { id: "mystic",    icon: "󰌌", label: strings.t("tab.mystic") },
    { id: "hardware",  icon: "󰁹", label: strings.t("tab.hardware") }
  ]

  readonly property var scenarioList: [
    { id: "extreme",       icon: "󰓅", label: strings.t("scenario.extreme"),  hint: strings.t("scenario.extremeHint") },
    { id: "balanced",      icon: "󰊚", label: strings.t("scenario.balanced"), hint: strings.t("scenario.balancedHint") },
    { id: "silent",        icon: "󰖁", label: strings.t("scenario.silent"),   hint: strings.t("scenario.silentHint") },
    { id: "super-battery", icon: "󰌪", label: strings.t("scenario.battery"),  hint: strings.t("scenario.batteryHint") }
  ]

  readonly property var fanModes: [
    { id: "auto",     icon: "󰑓", label: strings.t("cooling.fanAuto") },
    { id: "silent",   icon: "󰖁", label: strings.t("cooling.fanSilent") },
    { id: "advanced", icon: "󰈐", label: strings.t("cooling.fanAdvanced") }
  ]

  readonly property var mysticModes: [
    { id: "steady",    icon: "󰌌", label: strings.t("mystic.steady") },
    { id: "breathing", icon: "󰔟", label: strings.t("mystic.breathing") },
    { id: "wave",      icon: "🌈", label: strings.t("mystic.wave") },
    { id: "off",       icon: "󰶐", label: strings.t("mystic.off") }
  ]

  readonly property string themeAccentHex: {
    var c = Commons.Color.accent
    var r = Math.round((c ? c.r : 1) * 255)
    var g = Math.round((c ? c.g : 0.12) * 255)
    var b = Math.round((c ? c.b : 0.12) * 255)
    function hex2(n) {
      var s = Math.max(0, Math.min(255, n)).toString(16).toUpperCase()
      return s.length < 2 ? "0" + s : s
    }
    return "#" + hex2(r) + hex2(g) + hex2(b)
  }

  readonly property var mysticColors: [
    { hex: "#FF1E1E", label: strings.t("mystic.colorRed") },
    { hex: "#00E5FF", label: strings.t("mystic.colorCyan") },
    { hex: "#00E676", label: strings.t("mystic.colorGreen") },
    { hex: "#AA00FF", label: strings.t("mystic.colorPurple") },
    { hex: "#FFB300", label: strings.t("mystic.colorGold") },
    { hex: "#FFFFFF", label: strings.t("mystic.colorWhite") },
    { hex: root.themeAccentHex, label: strings.t("mystic.colorTheme") }
  ]

  readonly property var batteryLimits: [
    { limit: 100, icon: "󰁹", label: strings.t("battery.limit100") },
    { limit: 80,  icon: "󰂀", label: strings.t("battery.limit80") },
    { limit: 60,  icon: "󰁿", label: strings.t("battery.limit60") }
  ]

  readonly property string heroSubtitle: {
    if (busyText !== "") return Model.neutralizeMarkup(busyText, 80)
    if (state.coolerBoost) return strings.t("hero.coolerBoostActive")
    if (state.scenario === "extreme") return strings.t("hero.scenarioExtreme")
    if (state.scenario === "silent") return strings.t("hero.scenarioSilent")
    if (state.scenario === "super-battery") return strings.t("hero.scenarioBattery")
    return strings.t("hero.scenarioBalanced")
  }

  function fmtNum(val, decimals) {
    return Commons.I18n.formatNumber(Number(val || 0), decimals)
  }

  function safeText(val, maxLen) {
    return Model.neutralizeMarkup(val, maxLen)
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function runCommand(args, label, needsPkexec) {
    if (actionProc.running) return
    errorText = ""
    busyText = strings.t("status.applying").arg(safeText(label, 48))
    if (needsPkexec && !state.hardware.ecDirectReady) {
      actionProc.command = ["pkexec", root.ctlScript].concat(args)
    } else {
      actionProc.command = [root.ctlScript].concat(args)
    }
    actionProc.running = true
  }

  function mutateState(patchFn) {
    var copy = JSON.parse(JSON.stringify(root.state))
    patchFn(copy)
    root.state = copy
  }

  function setScenario(id) {
    mutateState(function(s) {
      s.scenario = id
      s.coolerBoost = false
      s.fanMode = (id === "silent" || id === "super-battery") ? "silent" : "auto"
      s.cpuTurbo = (id !== "super-battery")
    })
    runCommand(["scenario", id], id, true)
  }

  function toggleCoolerBoost() {
    var nextBool = !state.coolerBoost
    var next = nextBool ? "on" : "off"
    mutateState(function(s) {
      s.coolerBoost = nextBool
      s.fanMode = nextBool ? "advanced" : "auto"
    })
    runCommand(["cooler-boost", next], strings.t("cooling.coolerBoost"), true)
  }

  function setFanMode(mode) {
    mutateState(function(s) {
      s.fanMode = mode
      s.coolerBoost = (mode === "advanced")
    })
    runCommand(["fan-mode", mode], mode, true)
  }

  function toggleCpuTurbo() {
    var nextBool = !state.cpuTurbo
    var next = nextBool ? "on" : "off"
    mutateState(function(s) { s.cpuTurbo = nextBool })
    runCommand(["turbo", next], strings.t("cpu.turboBoost"), true)
  }

  function applyMystic(mode, colorHex, brightnessPct, speedPct) {
    var m = mode || state.mystic.mode || "steady"
    var c = Model.sanitizeHexColor(colorHex || state.mystic.colorHex, "#FF1E1E")
    var bNum = Math.round(Model.clampNumber(brightnessPct !== undefined ? brightnessPct : state.mystic.brightnessPct, 0, 100, 100))
    var sNum = Math.round(Model.clampNumber(speedPct !== undefined ? speedPct : state.mystic.speedPct, 5, 100, 50))
    var b = String(bNum)
    var sp = String(sNum)
    mutateState(function(s) {
      s.mystic.mode = m
      s.mystic.colorHex = c
      s.mystic.brightnessPct = bNum
      s.mystic.speedPct = sNum
    })
    runCommand(["mystic", m, c, b, sp], strings.t("tab.mystic"), true)
  }

  function setBatteryLimit(limit) {
    mutateState(function(s) { s.battery.chargeLimit = limit })
    runCommand(["battery-limit", String(limit)], String(limit) + "%", true)
  }

  function toggleHardwareSwitch(switchName, currentVal, label) {
    var nextBool = !currentVal
    var next = nextBool ? "on" : "off"
    mutateState(function(s) {
      if (switchName === "webcam") s.hardware.webcamEnabled = nextBool
      else if (switchName === "fn-swap") s.hardware.fnWinSwap = nextBool
      else if (switchName === "usb-share") s.hardware.usbPowerShare = nextBool
    })
    runCommand([switchName, next], label, true)
  }

  function setupDirectPermissions() {
    if (actionProc.running) return
    errorText = ""
    busyText = strings.t("status.applying").arg(strings.t("section.ecAccess"))
    actionProc.command = ["pkexec", root.ctlScript, "setup-permissions"]
    actionProc.running = true
  }

  function toggleBarTemp() {
    root.settings = Object.assign({}, root.settings, { showBarTemp: !root.showBarTemp })
    if (root.bar && root.bar.shell) root.bar.shell.updateEntryInline(root.moduleName, root.settings)
  }

  function cycleTab(delta) {
    var idx = 0
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].id === activeTab) { idx = i; break }
    }
    var next = (idx + delta + tabs.length) % tabs.length
    activeTab = tabs[next].id
  }

  ShellIpc {
    id: ipcHandler
    enabled: false
    target: ""

    Component.onCompleted: {
      if (IpcRegistry.handlerFor("tumi.msi-center") === null) {
        ipcHandler.target = "tumi.msi-center"
        ipcHandler.enabled = true
        IpcRegistry.register(ipcHandler)
      }
    }

    function open() { root.open() }
    function close() { root.close() }
    function show() { root.open() }
    function hide() { root.close() }
    function toggle() { root.toggle() }
    function toggleBarTemp() { root.toggleBarTemp() }
    function coolerBoost() { root.toggleCoolerBoost() }
  }

  onOpenedChanged: {
    if (opened) {
      errorText = ""
      refresh()
    }
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProc
    command: [root.ctlScript, "json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        root.state = Model.parseAndSanitizeState(text)
      }
    }
  }

  Process {
    id: actionProc
    stderr: StdioCollector { id: actionErr; waitForEnd: true }
    onExited: function(code) {
      root.busyText = ""
      if (code === 126 || code === 127) {
        root.errorText = "Authentication cancelled"
      } else if (code !== 0) {
        var rawErr = String(actionErr.text || "Command failed").trim().split("\n").pop()
        root.errorText = root.safeText(rawErr, 120)
      }
      root.refresh()
    }
  }

  // Fast 3s telemetry refresh while open; low-overhead 15s refresh when closed for bar icon/temp.
  Timer {
    interval: root.opened ? 3000 : 15000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.scenarioIcon(root.state.scenario, root.state.coolerBoost)
    labelText: Model.barLabelForState(root.state, root.showBarTemp && !vertical, function(v) { return root.fmtNum(v) })
    slotSize: Style.bar.iconSlot * (root.showBarTemp && !vertical ? 2.1 : 1)
    tooltipText: root.safeText(root.state.model + " · " + root.heroSubtitle, 96)
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleBarTemp()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(410))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) root.cycleTab(dx)
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        // ---------- Hero ----------
        PanelHero {
          title: root.safeText(strings.t("hero.title"), 48)
          detail: root.safeText(root.state.model, 36)
          meta: root.safeText(root.heroSubtitle, 64)
          foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          iconComponent: Component {
            PlainText {
              text: Model.scenarioIcon(root.state.scenario, root.state.coolerBoost)
              color: root.state.coolerBoost ? Commons.Color.accent : (root.bar ? root.bar.foreground : Commons.Color.foreground)
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.display
              Behavior on color { ColorAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }
            }
          }
          trailingControl: Component {
            PanelActionButton {
              iconText: "󰈐"
              bordered: true
              foreground: root.state.coolerBoost ? Commons.Color.accent : (root.bar ? root.bar.foreground : Commons.Color.foreground)
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              tooltipText: root.safeText(strings.t("cooling.coolerBoostHint"), 80)
              onClicked: root.toggleCoolerBoost()
            }
          }
        }

        // ---------- Error Banner ----------
        PlainText {
          visible: root.errorText !== ""
          text: root.errorText
          color: Commons.Color.urgent
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
          width: parent.width
        }

        // ---------- One-Time EC & RGB Unlock Banner ----------
        Button {
          visible: !root.state.hardware.ecDirectReady
          width: parent.width
          iconText: "󰌆"
          text: root.safeText(strings.t("ec.unlockButton"), 48)
          tooltipText: root.safeText(strings.t("ec.unlockPrompt"), 96)
          fontSize: Style.font.bodySmall
          foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          bordered: true
          selected: true
          onClicked: root.setupDirectPermissions()
        }

        // ---------- Navigation Tabs ----------
        Row {
          id: tabRow
          width: parent.width
          spacing: Style.space(6)
          readonly property real cellWidth: (width - spacing * (root.tabs.length - 1)) / root.tabs.length

          Repeater {
            model: root.tabs
            Button {
              required property var modelData
              width: tabRow.cellWidth
              iconText: modelData.icon
              iconSize: Style.font.body
              text: root.safeText(modelData.label, 24)
              fontSize: Style.font.caption
              foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
              horizontalPadding: Style.space(6)
              verticalPadding: Style.space(6)
              bordered: true
              active: root.activeTab === modelData.id
              onClicked: root.activeTab = modelData.id
            }
          }
        }

        PanelSeparator {
          foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
        }

        // =====================================================================
        // TAB 1: MONITOR (Telemetry, Fans, Driver Health)
        // =====================================================================
        Column {
          visible: root.activeTab === "monitor"
          width: parent.width
          spacing: Style.space(12)

          PanelSectionHeader {
            text: root.safeText(strings.t("section.telemetry"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          // CPU & GPU side-by-side telemetry cards
          Row {
            width: parent.width
            spacing: Style.space(8)
            readonly property real cardW: (width - spacing) / 2

            TelemetryCard {
              width: parent.cardW
              icon: "󰻠"
              title: strings.t("metric.cpu")
              primaryValue: root.fmtNum(Math.round(root.state.cpu.tempC)) + "°C"
              fraction: Model.clampNumber(root.state.cpu.usagePct / 100.0, 0, 1, 0)
              subLeft: root.fmtNum(root.state.cpu.usagePct) + "% load"
              subRight: strings.t("metric.ghz").arg(root.fmtNum(root.state.cpu.freqGhz, 2))
            }

            TelemetryCard {
              width: parent.cardW
              icon: "󰢮"
              title: strings.t("metric.gpu")
              primaryValue: root.state.gpu.present ? (root.fmtNum(root.state.gpu.tempC) + "°C") : "—"
              fraction: Model.clampNumber(root.state.gpu.utilPct / 100.0, 0, 1, 0)
              subLeft: root.fmtNum(root.state.gpu.utilPct) + "% · " + (root.state.gpu.pstate || "P0")
              subRight: strings.t("metric.watts").arg(root.fmtNum(root.state.gpu.powerW, 1))
            }
          }

          // VRAM, System RAM, NVMe stats
          Row {
            width: parent.width
            spacing: Style.space(16)

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.space(4)
              InfoPair {
                label: strings.t("metric.vram")
                value: strings.t("metric.mib").arg(root.fmtNum(root.state.gpu.vramUsedMib)).arg(root.fmtNum(root.state.gpu.vramTotalMib))
              }
              InfoPair {
                label: strings.t("metric.ram")
                value: strings.t("metric.gib").arg(root.fmtNum(root.state.memory.usedGib, 1)).arg(root.fmtNum(root.state.memory.totalGib, 1))
              }
            }

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.space(4)
              InfoPair {
                label: strings.t("metric.nvme")
                value: root.fmtNum(root.state.nvme.tempC, 1) + "°C"
              }
              InfoPair {
                label: strings.t("metric.memTemp")
                value: root.state.memory.tempC > 0 ? (root.fmtNum(root.state.memory.tempC, 1) + "°C") : "—"
              }
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          // Cooler RPMs
          PanelSectionHeader {
            text: root.safeText(strings.t("section.fans"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Row {
            width: parent.width
            spacing: Style.space(16)

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.space(4)
              InfoPair {
                label: strings.t("metric.fan1")
                value: strings.t("metric.rpm").arg(root.fmtNum(root.state.fans.fan1Rpm))
              }
              InfoPair {
                visible: root.state.fans.fan3Rpm > 0 || root.state.chassis === "desktop"
                label: strings.t("metric.fan3")
                value: strings.t("metric.rpm").arg(root.fmtNum(root.state.fans.fan3Rpm))
              }
            }

            Column {
              width: (parent.width - parent.spacing) / 2
              spacing: Style.space(4)
              InfoPair {
                label: strings.t("metric.fan2")
                value: strings.t("metric.rpm").arg(root.fmtNum(root.state.fans.fan2Rpm))
              }
              InfoPair {
                visible: root.state.fans.fan4Rpm > 0 || root.state.chassis === "desktop"
                label: strings.t("metric.fan4")
                value: strings.t("metric.rpm").arg(root.fmtNum(root.state.fans.fan4Rpm))
              }
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          // Driver & Kernel Health
          PanelSectionHeader {
            text: root.safeText(strings.t("section.drivers"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Column {
            width: parent.width
            spacing: Style.space(5)

            DriverRow {
              label: strings.t("driver.nvidia")
              ok: root.state.drivers.nvidiaOk
              detail: root.state.drivers.nvidiaDetail
            }
            DriverRow {
              label: strings.t("driver.igpu")
              ok: root.state.drivers.igpuOk
              detail: root.state.drivers.igpuDetail
            }
            DriverRow {
              label: strings.t("driver.msiWmi")
              ok: root.state.drivers.msiWmiOk
              detail: root.state.drivers.msiWmiDetail
            }
            DriverRow {
              label: strings.t("driver.msiEc")
              ok: root.state.drivers.msiEcOk
              detail: root.state.drivers.msiEcDetail
            }
            DriverRow {
              label: strings.t("driver.mystic")
              ok: root.state.drivers.mysticOk
              detail: root.state.drivers.mysticDetail
            }
            DriverRow {
              label: strings.t("driver.audioNet")
              ok: root.state.drivers.audioNetOk
              detail: root.state.drivers.audioNetDetail
            }
          }
        }

        // =====================================================================
        // TAB 2: SCENARIOS (User Scenarios, Cooler Boost, Fan Mode, CPU Turbo)
        // =====================================================================
        Column {
          visible: root.activeTab === "scenarios"
          width: parent.width
          spacing: Style.space(12)

          PanelSectionHeader {
            text: root.safeText(strings.t("section.scenarios"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Grid {
            id: scenarioGrid
            width: parent.width
            columns: 2
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing) / 2

            Repeater {
              model: root.scenarioList
              Button {
                required property var modelData
                width: scenarioGrid.cellWidth
                iconText: modelData.icon
                iconSize: Style.font.title
                text: root.safeText(modelData.label, 28)
                tooltipText: root.safeText(modelData.hint, 80)
                fontSize: Style.font.bodySmall
                foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                verticalPadding: Style.spacing.controlPaddingY + Style.space(3)
                bordered: true
                active: root.state.scenario === modelData.id
                onClicked: root.setScenario(modelData.id)
              }
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          PanelSectionHeader {
            text: root.safeText(strings.t("section.cooling"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          SwitchRow {
            label: strings.t("cooling.coolerBoost")
            checked: root.state.coolerBoost
            busy: actionProc.running
            onToggled: root.toggleCoolerBoost()
          }

          Row {
            id: fanModeRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * (root.fanModes.length - 1)) / root.fanModes.length

            Repeater {
              model: root.fanModes
              Button {
                required property var modelData
                width: fanModeRow.cellWidth
                iconText: modelData.icon
                iconSize: Style.font.body
                text: root.safeText(modelData.label, 24)
                fontSize: Style.font.bodySmall
                foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                bordered: true
                active: root.state.fanMode === modelData.id
                onClicked: root.setFanMode(modelData.id)
              }
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          PanelSectionHeader {
            text: root.safeText(strings.t("section.cpuControl"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          SwitchRow {
            label: strings.t("cpu.turboBoost")
            checked: root.state.cpuTurbo
            busy: actionProc.running
            onToggled: root.toggleCpuTurbo()
          }
        }

        // =====================================================================
        // TAB 3: MYSTIC LIGHT (RGB Mode, Color Presets, Brightness)
        // =====================================================================
        Column {
          visible: root.activeTab === "mystic"
          width: parent.width
          spacing: Style.space(12)

          PlainText {
            text: root.state.mystic.present
              ? strings.t("mystic.deviceFound").arg(root.state.mystic.deviceName + " (" + root.state.mystic.deviceId + ")")
              : strings.t("mystic.deviceNone")
            color: root.bar ? root.bar.foreground : Commons.Color.foreground
            opacity: 0.7
            font.family: root.bar ? root.bar.fontFamily : Style.font.family
            font.pixelSize: Style.font.bodySmall
            width: parent.width
            elide: Text.ElideRight
          }

          PanelSectionHeader {
            text: root.safeText(strings.t("section.mysticMode"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Row {
            id: mysticModeRow
            width: parent.width
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing * (root.mysticModes.length - 1)) / root.mysticModes.length

            Repeater {
              model: root.mysticModes
              Button {
                required property var modelData
                width: mysticModeRow.cellWidth
                text: root.safeText(modelData.label, 20)
                fontSize: Style.font.bodySmall
                foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                bordered: true
                active: root.state.mystic.mode === modelData.id
                onClicked: root.applyMystic(modelData.id, root.state.mystic.colorHex, root.state.mystic.brightnessPct, root.state.mystic.speedPct)
              }
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          PanelSectionHeader {
            text: root.safeText(strings.t("section.mysticColor"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Grid {
            id: colorGrid
            width: parent.width
            columns: 2
            spacing: Style.space(6)
            readonly property real cellWidth: (width - spacing) / 2

            Repeater {
              model: root.mysticColors
              Button {
                required property var modelData
                width: colorGrid.cellWidth
                iconText: "󰝤"
                text: root.safeText(modelData.label + " (" + modelData.hex + ")", 32)
                fontSize: Style.font.caption
                foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
                fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                bordered: true
                active: root.state.mystic.colorHex.toUpperCase() === modelData.hex.toUpperCase()
                onClicked: {
                  var nextMode = root.state.mystic.mode === "off" ? "steady" : root.state.mystic.mode
                  var nextBright = root.state.mystic.brightnessPct > 0 ? root.state.mystic.brightnessPct : 100
                  root.applyMystic(nextMode, modelData.hex, nextBright, root.state.mystic.speedPct)
                }
              }
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          Row {
            width: parent.width
            PanelSectionHeader {
              text: root.safeText(strings.t("section.mysticBrightness"), 48)
              foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            }
            Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - brightValText.implicitWidth); height: 1 }
            PlainText {
              id: brightValText
              text: root.fmtNum(root.state.mystic.brightnessPct) + "%"
              color: root.bar ? root.bar.foreground : Commons.Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          PanelSlider {
            width: parent.width
            bar: root.bar
            minimum: 0
            maximum: 100
            step: 5
            integer: true
            tickCount: 0
            value: root.state.mystic.brightnessPct
            onReleased: function(v) {
              var nextMode = (v > 0 && root.state.mystic.mode === "off") ? "steady" : root.state.mystic.mode
              root.applyMystic(nextMode, root.state.mystic.colorHex, v, root.state.mystic.speedPct)
            }
          }

          Row {
            width: parent.width
            PanelSectionHeader {
              text: root.safeText(strings.t("section.mysticSpeed"), 48)
              foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            }
            Item { width: Math.max(0, parent.width - parent.children[0].implicitWidth - speedValText.implicitWidth); height: 1 }
            PlainText {
              id: speedValText
              text: root.fmtNum(root.state.mystic.speedPct) + "%"
              color: root.bar ? root.bar.foreground : Commons.Color.foreground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }
          }

          PanelSlider {
            width: parent.width
            bar: root.bar
            minimum: 10
            maximum: 100
            step: 5
            integer: true
            tickCount: 0
            value: root.state.mystic.speedPct
            onReleased: function(v) {
              root.applyMystic(root.state.mystic.mode, root.state.mystic.colorHex, root.state.mystic.brightnessPct, v)
            }
          }
        }

        // =====================================================================
        // TAB 4: HARDWARE (Battery Master, Switches, GPU MUX, EC Unlock)
        // =====================================================================
        Column {
          visible: root.activeTab === "hardware"
          width: parent.width
          spacing: Style.space(12)

          // Battery Master (shown when laptop battery is present)
          Column {
            visible: root.state.battery.present
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: root.safeText(strings.t("section.batteryMaster"), 48)
              foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
              fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            }

            Row {
              id: batLimitRow
              width: parent.width
              spacing: Style.space(6)
              readonly property real cellWidth: (width - spacing * (root.batteryLimits.length - 1)) / root.batteryLimits.length

              Repeater {
                model: root.batteryLimits
                Button {
                  required property var modelData
                  width: batLimitRow.cellWidth
                  iconText: modelData.icon
                  iconSize: Style.font.body
                  text: root.safeText(modelData.label, 24)
                  fontSize: Style.font.caption
                  foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
                  fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
                  bordered: true
                  active: root.state.battery.chargeLimit === modelData.limit
                  onClicked: root.setBatteryLimit(modelData.limit)
                }
              }
            }

            Row {
              width: parent.width
              spacing: Style.space(16)

              Column {
                width: (parent.width - parent.spacing) / 2
                spacing: Style.space(4)
                InfoPair {
                  label: strings.t("battery.health")
                  value: root.fmtNum(root.state.battery.healthPct) + "%"
                }
                InfoPair {
                  label: strings.t("battery.cycles")
                  value: root.fmtNum(root.state.battery.cycles)
                }
              }

              Column {
                width: (parent.width - parent.spacing) / 2
                spacing: Style.space(4)
                InfoPair {
                  label: strings.t("battery.status")
                  value: root.state.battery.status + " (" + root.fmtNum(root.state.battery.capacityPct) + "%)"
                }
                InfoPair {
                  label: strings.t("battery.rate")
                  value: strings.t("metric.watts").arg(root.fmtNum(root.state.battery.powerW, 1))
                }
              }
            }

            PanelSeparator {
              foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            }
          }

          PanelSectionHeader {
            text: root.safeText(strings.t("section.hardwareSwitches"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          Column {
            width: parent.width
            spacing: Style.space(6)

            SwitchRow {
              label: strings.t("hw.webcam")
              checked: root.state.hardware.webcamEnabled
              busy: actionProc.running
              onToggled: root.toggleHardwareSwitch("webcam", root.state.hardware.webcamEnabled, strings.t("hw.webcam"))
            }

            SwitchRow {
              label: strings.t("hw.fnSwap")
              checked: root.state.hardware.fnWinSwap
              busy: actionProc.running
              onToggled: root.toggleHardwareSwitch("fn-swap", root.state.hardware.fnWinSwap, strings.t("hw.fnSwap"))
            }

            SwitchRow {
              label: strings.t("hw.usbShare")
              checked: root.state.hardware.usbPowerShare
              busy: actionProc.running
              onToggled: root.toggleHardwareSwitch("usb-share", root.state.hardware.usbPowerShare, strings.t("hw.usbShare"))
            }

            SwitchRow {
              label: strings.t("hw.barTemp")
              checked: root.showBarTemp
              busy: false
              onToggled: root.toggleBarTemp()
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          PanelSectionHeader {
            text: root.safeText(strings.t("section.gpuDisplay"), 48)
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
          }

          InfoPair {
            label: strings.t("hw.gpuMode")
            value: root.state.gpu.mode + " (" + (root.state.gpu.runtimeStatus || "active") + ")"
          }

          InfoPair {
            label: strings.t("hw.displaysLabel")
            value: {
              var count = root.state.gpu.displays.length
              var listStr = count > 0 ? root.state.gpu.displays.join(", ") : "—"
              return strings.tn("hw.displays", count).arg(root.fmtNum(count)).arg(listStr)
            }
          }

          PanelSeparator {
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
          }

          // Direct EC & RGB permission setup
          Button {
            width: parent.width
            iconText: root.state.hardware.ecDirectReady ? "󰄬" : "󰌆"
            text: root.safeText(
              root.state.hardware.ecDirectReady
                ? strings.t("ec.unlockedButton")
                : strings.t("ec.unlockButton"),
              48
            )
            tooltipText: root.safeText(
              root.state.hardware.ecDirectReady
                ? strings.t("ec.ready")
                : strings.t("ec.unlockPrompt"),
              96
            )
            fontSize: Style.font.bodySmall
            foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
            fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
            bordered: true
            active: root.state.hardware.ecDirectReady
            onClicked: root.setupDirectPermissions()
          }
        }
      }
    }
  }

  // ---------- Reusable Local Components ----------

  component PlainText: Text {
    textFormat: Text.PlainText
  }

  component TelemetryCard: BorderSurface {
    property string icon: ""
    property string title: ""
    property string primaryValue: ""
    property real fraction: 0
    property string subLeft: ""
    property string subRight: ""

    implicitHeight: cardCol.implicitHeight + Style.space(16)
    radius: Style.cornerRadius
    color: Style.normalFillFor(root.bar ? root.bar.foreground : Commons.Color.foreground, Commons.Color.accent)
    borderSpec: Border.controlSpec("normal", root.bar ? root.bar.foreground : Commons.Color.foreground, Commons.Color.accent)

    Column {
      id: cardCol
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: Style.space(8)
      spacing: Style.space(6)

      Row {
        width: parent.width
        spacing: Style.space(6)

        PlainText {
          text: icon
          color: root.bar ? root.bar.foreground : Commons.Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          anchors.verticalCenter: parent.verticalCenter
        }

        PlainText {
          text: title
          color: root.bar ? root.bar.foreground : Commons.Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[1].implicitWidth - parent.children[3].implicitWidth - parent.spacing * 3)
          height: 1
        }

        PlainText {
          text: primaryValue
          color: root.bar ? root.bar.foreground : Commons.Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Rectangle {
        width: parent.width
        height: Style.space(5)
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.12)

        Rectangle {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          height: parent.height
          radius: parent.radius
          color: root.bar ? root.bar.foreground : Commons.Color.foreground
          width: Math.max(height, parent.width * Math.max(0, Math.min(1, fraction)))
          Behavior on width { NumberAnimation { duration: Style.duration(220); easing.type: Easing.OutCubic } }
        }
      }

      Row {
        width: parent.width
        PlainText {
          text: subLeft
          color: root.bar ? root.bar.foreground : Commons.Color.foreground
          opacity: 0.65
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
        Item {
          width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth)
          height: 1
        }
        PlainText {
          text: subRight
          color: root.bar ? root.bar.foreground : Commons.Color.foreground
          opacity: 0.85
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  component InfoPair: Row {
    property string label: ""
    property string value: ""

    width: parent.width
    spacing: Style.space(6)

    PlainText {
      text: label
      color: root.bar ? root.bar.foreground : Commons.Color.foreground
      opacity: 0.6
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
    }
    Item {
      width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth - parent.spacing * 2)
      height: 1
    }
    PlainText {
      text: value
      color: root.bar ? root.bar.foreground : Commons.Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }
  }

  component DriverRow: Row {
    property string label: ""
    property bool ok: false
    property string detail: ""

    width: parent.width
    spacing: Style.space(8)

    PlainText {
      text: ok ? "󰄬" : "󰅙"
      color: ok ? (root.bar ? root.bar.foreground : Commons.Color.foreground) : Commons.Color.urgent
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      anchors.verticalCenter: parent.verticalCenter
    }

    PlainText {
      text: label
      color: root.bar ? root.bar.foreground : Commons.Color.foreground
      opacity: 0.7
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      anchors.verticalCenter: parent.verticalCenter
    }

    Item {
      width: Math.max(0, parent.width - parent.children[0].implicitWidth - parent.children[1].implicitWidth - parent.children[3].implicitWidth - parent.spacing * 3)
      height: 1
    }

    PlainText {
      text: detail
      color: root.bar ? root.bar.foreground : Commons.Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
    }
  }

  component SwitchRow: Row {
    property string label: ""
    property bool checked: false
    property bool busy: false
    signal toggled()

    width: parent.width
    spacing: Style.space(8)

    PlainText {
      text: label
      color: root.bar ? root.bar.foreground : Commons.Color.foreground
      font.family: root.bar ? root.bar.fontFamily : Style.font.family
      font.pixelSize: Style.font.bodySmall
      anchors.verticalCenter: parent.verticalCenter
      width: Math.max(0, parent.width - sw.implicitWidth - parent.spacing)
      elide: Text.ElideRight
    }

    ToggleSwitch {
      id: sw
      checked: parent.checked
      busy: parent.busy
      foreground: root.bar ? root.bar.foreground : Commons.Color.foreground
      accent: Commons.Color.accent
      anchors.verticalCenter: parent.verticalCenter
      onToggled: parent.toggled()
    }
  }
}
