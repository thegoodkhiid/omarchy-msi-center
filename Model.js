// Pure data-normalization, markup-neutralization, and state helpers for
// oma.msi-center. Shared by Panel.qml and regression tests in tests/model-test.js.

function neutralizeMarkup(value, maxLen) {
  var limit = (typeof maxLen === "number" && maxLen > 0) ? maxLen : 160
  var raw = String(value === undefined || value === null ? "" : value)
  // Strip control characters except space/tab, and neutralize HTML/RichText tags
  // or entity starters so QML Text.AutoText sinks never interpret markup or load
  // external resources such as <img src="...">.
  var cleaned = raw
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "")
    .replace(/<[^>]*>?/g, function(tag) {
      return tag.replace(/</g, "‹").replace(/>/g, "›")
    })
    .replace(/[<>]/g, function(ch) {
      return ch === "<" ? "‹" : "›"
    })
    .replace(/&(#?[A-Za-z0-9]+);/g, "＆$1;")
    .trim()
  if (cleaned.length > limit) {
    return cleaned.substring(0, limit - 1) + "…"
  }
  return cleaned
}

function clampNumber(value, min, max, fallback) {
  var num = Number(value)
  if (isNaN(num) || !isFinite(num)) return fallback !== undefined ? fallback : min
  return Math.max(min, Math.min(max, num))
}

function sanitizeHexColor(hex, fallback) {
  var raw = String(hex || "").trim()
  if (/^#[0-9A-Fa-f]{6}$/.test(raw)) return raw.toUpperCase()
  if (/^[0-9A-Fa-f]{6}$/.test(raw)) return "#" + raw.toUpperCase()
  return fallback || "#FF1E1E"
}

function defaultState() {
  return {
    model: "MSI Computer",
    board: "MSI",
    bios: "",
    ecFirmware: "",
    chassis: "laptop",
    scenario: "balanced",
    powerProfile: "balanced",
    coolerBoost: false,
    fanMode: "auto",
    cpuTurbo: true,
    cpu: {
      tempC: 0,
      usagePct: 0,
      freqGhz: 0,
      cores: 1
    },
    gpu: {
      present: false,
      name: "NVIDIA GPU",
      driverVersion: "",
      cudaVersion: "",
      tempC: 0,
      utilPct: 0,
      powerW: 0,
      powerCapW: 0,
      vramUsedMib: 0,
      vramTotalMib: 0,
      pstate: "",
      runtimeStatus: "",
      mode: "Hybrid / Optimus",
      displays: []
    },
    fans: {
      fan1Rpm: 0,
      fan2Rpm: 0,
      fan3Rpm: 0,
      fan4Rpm: 0
    },
    memory: {
      usedGib: 0,
      totalGib: 0,
      usagePct: 0,
      tempC: 0
    },
    nvme: {
      tempC: 0
    },
    battery: {
      present: false,
      capacityPct: 0,
      status: "Unknown",
      healthPct: 100,
      cycles: 0,
      powerW: 0,
      chargeLimit: 100
    },
    mystic: {
      present: false,
      deviceName: "",
      deviceId: "",
      mode: "steady",
      colorHex: "#FF1E1E",
      brightnessPct: 100,
      speedPct: 50
    },
    hardware: {
      webcamEnabled: true,
      fnWinSwap: false,
      usbPowerShare: false,
      ecDirectReady: false,
      ecBackend: "wmi"
    },
    drivers: {
      nvidiaOk: false,
      nvidiaDetail: "",
      igpuOk: false,
      igpuDetail: "",
      msiWmiOk: false,
      msiWmiDetail: "",
      msiEcOk: false,
      msiEcDetail: "",
      mysticOk: false,
      mysticDetail: "",
      audioNetOk: false,
      audioNetDetail: ""
    }
  }
}

function parseAndSanitizeState(rawText) {
  var base = defaultState()
  if (!rawText || typeof rawText !== "string") return base

  var trimmed = rawText.trim()
  if (!trimmed || trimmed.length > 65536) return base

  var parsed = null
  try {
    parsed = JSON.parse(trimmed)
  } catch (e) {
    return base
  }
  if (!parsed || typeof parsed !== "object") return base

  base.model = neutralizeMarkup(parsed.model || base.model, 80)
  base.board = neutralizeMarkup(parsed.board || base.board, 48)
  base.bios = neutralizeMarkup(parsed.bios || "", 48)
  base.ecFirmware = neutralizeMarkup(parsed.ecFirmware || "", 48)
  base.chassis = parsed.chassis === "desktop" ? "desktop" : "laptop"

  var validScenarios = ["extreme", "balanced", "silent", "super-battery"]
  base.scenario = validScenarios.indexOf(parsed.scenario) >= 0 ? parsed.scenario : "balanced"
  base.powerProfile = neutralizeMarkup(parsed.powerProfile || "balanced", 32)
  base.coolerBoost = !!parsed.coolerBoost

  var validFanModes = ["auto", "silent", "advanced"]
  base.fanMode = validFanModes.indexOf(parsed.fanMode) >= 0 ? parsed.fanMode : "auto"
  base.cpuTurbo = parsed.cpuTurbo !== undefined ? !!parsed.cpuTurbo : true

  if (parsed.cpu && typeof parsed.cpu === "object") {
    base.cpu.tempC = clampNumber(parsed.cpu.tempC, 0, 130, 0)
    base.cpu.usagePct = clampNumber(parsed.cpu.usagePct, 0, 100, 0)
    base.cpu.freqGhz = clampNumber(parsed.cpu.freqGhz, 0, 10, 0)
    base.cpu.cores = clampNumber(parsed.cpu.cores, 1, 256, 1)
  }

  if (parsed.gpu && typeof parsed.gpu === "object") {
    base.gpu.present = !!parsed.gpu.present
    base.gpu.name = neutralizeMarkup(parsed.gpu.name || "NVIDIA GPU", 64)
    base.gpu.driverVersion = neutralizeMarkup(parsed.gpu.driverVersion || "", 32)
    base.gpu.cudaVersion = neutralizeMarkup(parsed.gpu.cudaVersion || "", 24)
    base.gpu.tempC = clampNumber(parsed.gpu.tempC, 0, 130, 0)
    base.gpu.utilPct = clampNumber(parsed.gpu.utilPct, 0, 100, 0)
    base.gpu.powerW = clampNumber(parsed.gpu.powerW, 0, 1000, 0)
    base.gpu.powerCapW = clampNumber(parsed.gpu.powerCapW, 0, 1000, 0)
    base.gpu.vramUsedMib = clampNumber(parsed.gpu.vramUsedMib, 0, 131072, 0)
    base.gpu.vramTotalMib = clampNumber(parsed.gpu.vramTotalMib, 0, 131072, 0)
    base.gpu.pstate = neutralizeMarkup(parsed.gpu.pstate || "", 16)
    base.gpu.runtimeStatus = neutralizeMarkup(parsed.gpu.runtimeStatus || "", 24)
    base.gpu.mode = neutralizeMarkup(parsed.gpu.mode || "Hybrid / Optimus", 48)
    var disp = Array.isArray(parsed.gpu.displays) ? parsed.gpu.displays.slice(0, 8) : []
    base.gpu.displays = []
    for (var i = 0; i < disp.length; i++) {
      var d = neutralizeMarkup(disp[i], 32)
      if (d) base.gpu.displays.push(d)
    }
  }

  if (parsed.fans && typeof parsed.fans === "object") {
    base.fans.fan1Rpm = clampNumber(parsed.fans.fan1Rpm, 0, 12000, 0)
    base.fans.fan2Rpm = clampNumber(parsed.fans.fan2Rpm, 0, 12000, 0)
    base.fans.fan3Rpm = clampNumber(parsed.fans.fan3Rpm, 0, 12000, 0)
    base.fans.fan4Rpm = clampNumber(parsed.fans.fan4Rpm, 0, 12000, 0)
  }

  if (parsed.memory && typeof parsed.memory === "object") {
    base.memory.usedGib = clampNumber(parsed.memory.usedGib, 0, 2048, 0)
    base.memory.totalGib = clampNumber(parsed.memory.totalGib, 0, 2048, 0)
    base.memory.usagePct = clampNumber(parsed.memory.usagePct, 0, 100, 0)
    base.memory.tempC = clampNumber(parsed.memory.tempC, 0, 130, 0)
  }

  if (parsed.nvme && typeof parsed.nvme === "object") {
    base.nvme.tempC = clampNumber(parsed.nvme.tempC, 0, 130, 0)
  }

  if (parsed.battery && typeof parsed.battery === "object") {
    base.battery.present = !!parsed.battery.present
    base.battery.capacityPct = clampNumber(parsed.battery.capacityPct, 0, 100, 0)
    base.battery.status = neutralizeMarkup(parsed.battery.status || "Unknown", 32)
    base.battery.healthPct = clampNumber(parsed.battery.healthPct, 0, 120, 100)
    base.battery.cycles = clampNumber(parsed.battery.cycles, 0, 100000, 0)
    base.battery.powerW = clampNumber(parsed.battery.powerW, 0, 500, 0)
    var lim = clampNumber(parsed.battery.chargeLimit, 50, 100, 100)
    base.battery.chargeLimit = lim <= 65 ? 60 : (lim <= 85 ? 80 : 100)
  }

  if (parsed.mystic && typeof parsed.mystic === "object") {
    base.mystic.present = !!parsed.mystic.present
    base.mystic.deviceName = neutralizeMarkup(parsed.mystic.deviceName || "", 64)
    base.mystic.deviceId = neutralizeMarkup(parsed.mystic.deviceId || "", 24)
    var validModes = ["steady", "breathing", "wave", "off"]
    base.mystic.mode = validModes.indexOf(parsed.mystic.mode) >= 0 ? parsed.mystic.mode : "steady"
    base.mystic.colorHex = sanitizeHexColor(parsed.mystic.colorHex, "#FF1E1E")
    base.mystic.brightnessPct = clampNumber(parsed.mystic.brightnessPct, 0, 100, 100)
    base.mystic.speedPct = clampNumber(parsed.mystic.speedPct, 0, 100, 50)
  }

  if (parsed.hardware && typeof parsed.hardware === "object") {
    base.hardware.webcamEnabled = parsed.hardware.webcamEnabled !== undefined ? !!parsed.hardware.webcamEnabled : true
    base.hardware.fnWinSwap = !!parsed.hardware.fnWinSwap
    base.hardware.usbPowerShare = !!parsed.hardware.usbPowerShare
    base.hardware.ecDirectReady = !!parsed.hardware.ecDirectReady
    base.hardware.ecBackend = neutralizeMarkup(parsed.hardware.ecBackend || "wmi", 32)
  }

  if (parsed.drivers && typeof parsed.drivers === "object") {
    base.drivers.nvidiaOk = !!parsed.drivers.nvidiaOk
    base.drivers.nvidiaDetail = neutralizeMarkup(parsed.drivers.nvidiaDetail || "", 64)
    base.drivers.igpuOk = !!parsed.drivers.igpuOk
    base.drivers.igpuDetail = neutralizeMarkup(parsed.drivers.igpuDetail || "", 64)
    base.drivers.msiWmiOk = !!parsed.drivers.msiWmiOk
    base.drivers.msiWmiDetail = neutralizeMarkup(parsed.drivers.msiWmiDetail || "", 64)
    base.drivers.msiEcOk = !!parsed.drivers.msiEcOk
    base.drivers.msiEcDetail = neutralizeMarkup(parsed.drivers.msiEcDetail || "", 64)
    base.drivers.mysticOk = !!parsed.drivers.mysticOk
    base.drivers.mysticDetail = neutralizeMarkup(parsed.drivers.mysticDetail || "", 64)
    base.drivers.audioNetOk = !!parsed.drivers.audioNetOk
    base.drivers.audioNetDetail = neutralizeMarkup(parsed.drivers.audioNetDetail || "", 64)
  }

  return base
}

function scenarioIcon(scenario, coolerBoost) {
  if (coolerBoost) return "󰈐"
  if (scenario === "extreme") return "󰓅"
  if (scenario === "silent") return "󰖁"
  if (scenario === "super-battery") return "󰌪"
  return "󰍛"
}

function barLabelForState(state, showTemp, fmt) {
  if (!showTemp || !state) return ""
  var f = typeof fmt === "function" ? fmt : function(v) { return String(Math.round(v)) }
  var cpuT = state.cpu ? Math.round(state.cpu.tempC || 0) : 0
  if (cpuT <= 0) return ""
  return f(cpuT) + "°"
}

if (typeof module !== "undefined") {
  module.exports = {
    neutralizeMarkup: neutralizeMarkup,
    clampNumber: clampNumber,
    sanitizeHexColor: sanitizeHexColor,
    defaultState: defaultState,
    parseAndSanitizeState: parseAndSanitizeState,
    scenarioIcon: scenarioIcon,
    barLabelForState: barLabelForState
  }
}
