// Regression test suite for tumi.msi-center Model.js
// Covers markup neutralization, payload bounding/validation, and tooltip/hero sinks.

const assert = require("assert")
const Model = require("../Model.js")

// 1. Markup-shaped input neutralization (prevents RichText / AutoText injection)
const trackerInput = 'Sword 17 <img src="https://example.invalid/tracker"> <b>HX</b> &nbsp;'
const neutralized = Model.neutralizeMarkup(trackerInput, 160)
assert(!neutralized.includes("<"), "neutralizeMarkup must strip '<'")
assert(!neutralized.includes(">"), "neutralizeMarkup must strip '>'")
assert(!neutralized.includes("&nbsp;"), "neutralizeMarkup must neutralize HTML entities")
assert(neutralized.includes("‹img"), "neutralizeMarkup should replace angle brackets with safe guillemets")

// 2. Unclosed tag & control character neutralization
const malformed = "MSI\x00\x07 <script src='https://evil.invalid'"
const cleanMalformed = Model.neutralizeMarkup(malformed, 80)
assert(!cleanMalformed.includes("<"), "unclosed '<' must be neutralized")
assert(!cleanMalformed.includes("\x00"), "NUL bytes must be stripped")

// 3. Length bounding
const longInput = "A".repeat(300)
const bounded = Model.neutralizeMarkup(longInput, 40)
assert.strictEqual(bounded.length, 40, "neutralizeMarkup must bound string length to maxLen")

// 4. Full state sanitization against malicious / out-of-range JSON
const rawEvilJson = JSON.stringify({
  model: '<img src="https://example.invalid/pwn">MSI Sword',
  board: "<b>MS-17T2</b>",
  chassis: "spaceship",
  scenario: "over9000",
  coolerBoost: 1,
  fanMode: "invalid-mode",
  cpu: { tempC: 9999, usagePct: -50, freqGhz: 99, cores: 5000 },
  gpu: {
    present: true,
    name: '<a href="https://example.invalid">RTX 4060</a>',
    driverVersion: "<script>615.78</script>",
    tempC: 500,
    utilPct: 250,
    displays: ['<img src="x">eDP-1', "HDMI-A-1", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10"]
  },
  fans: { fan1Rpm: 99999, fan2Rpm: -200 },
  battery: { present: true, capacityPct: 150, chargeLimit: 58, status: "<b>Charging</b>" },
  mystic: { present: true, deviceName: "<img src=1>", mode: "hacked", colorHex: "not-a-color", brightnessPct: 900, speedPct: -20 },
  drivers: {
    nvidiaOk: true,
    nvidiaDetail: '<img src="https://tracker.invalid">v615.78.08'
  }
})

const state = Model.parseAndSanitizeState(rawEvilJson)
assert(!state.model.includes("<"), "model sink must neutralize markup")
assert(!state.board.includes("<"), "board sink must neutralize markup")
assert.strictEqual(state.chassis, "laptop", "invalid chassis must fall back to laptop")
assert.strictEqual(state.scenario, "balanced", "invalid scenario must fall back to balanced")
assert.strictEqual(state.fanMode, "auto", "invalid fanMode must fall back to auto")
assert.strictEqual(state.cpu.tempC, 130, "cpu.tempC must be clamped to 130")
assert.strictEqual(state.cpu.usagePct, 0, "cpu.usagePct must be clamped to >= 0")
assert.strictEqual(state.gpu.utilPct, 100, "gpu.utilPct must be clamped to <= 100")
assert(!state.gpu.name.includes("<"), "gpu.name must neutralize markup")
assert.strictEqual(state.gpu.displays.length, 8, "gpu.displays collection must be bounded to 8")
assert(!state.gpu.displays[0].includes("<"), "gpu.displays items must neutralize markup")
assert.strictEqual(state.fans.fan1Rpm, 12000, "fan1Rpm must be clamped to 12000")
assert.strictEqual(state.fans.fan2Rpm, 0, "fan2Rpm must be clamped to >= 0")
assert.strictEqual(state.battery.chargeLimit, 60, "chargeLimit 58 must normalize to 60")
assert.strictEqual(state.mystic.mode, "steady", "invalid mystic mode must fall back to steady")
assert.strictEqual(state.mystic.colorHex, "#FF1E1E", "invalid hex color must fall back to #FF1E1E")
assert.strictEqual(state.mystic.brightnessPct, 100, "brightness must clamp to 100")
assert.strictEqual(state.mystic.speedPct, 0, "speed must clamp to >= 0")
assert(!state.drivers.nvidiaDetail.includes("<"), "driver detail must neutralize markup")

console.log("All tumi.msi-center Model regression tests passed.")
