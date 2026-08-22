import ApexCharts from "https://cdn.jsdelivr.net/npm/apexcharts@3.45.1/dist/apexcharts.esm.js"

function integerLabel(value) {
  const number = Number(value)
  return Number.isFinite(number) ? String(Math.round(number)) : String(value)
}

function integerizeAxis(yaxis) {
  if (Array.isArray(yaxis)) return yaxis.map(integerizeAxis)
  if (!yaxis) return yaxis
  if (yaxis.decimalsInFloat !== 0 && yaxis.stepSize !== 1) return yaxis

  return {
    ...yaxis,
    labels: {
      ...(yaxis.labels || {}),
      formatter: integerLabel
    }
  }
}

function withIntegerPageCounts(options = {}) {
  const next = {
    ...options,
    yaxis: integerizeAxis(options.yaxis)
  }
  const tooltip = { ...(options.tooltip || {}) }
  const tooltipY = { ...(tooltip.y || {}) }
  if (typeof tooltipY.formatter !== "function") tooltipY.formatter = integerLabel
  next.tooltip = { ...tooltip, y: tooltipY }
  return next
}

function rewriteAxisLabels(element) {
  if (!element) return

  element.querySelectorAll(".apexcharts-yaxis-label tspan, .apexcharts-yaxis-label").forEach((node) => {
    const text = (node.textContent || "").trim()
    if (/^\d+\.0+$/.test(text)) node.textContent = String(Math.round(Number(text)))
  })
}

export default class extends ApexCharts {
  constructor(el, options) {
    super(el, withIntegerPageCounts(options))
    this._sitemapsElement = el
  }

  render() {
    const rendered = super.render()
    const finish = (value) => {
      rewriteAxisLabels(this._sitemapsElement)
      return value
    }

    if (rendered && typeof rendered.then === "function") return rendered.then(finish)
    return finish(rendered)
  }
}
