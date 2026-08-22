import ApexCharts from "https://cdn.jsdelivr.net/npm/apexcharts@3.45.1/dist/apexcharts.esm.js"

function integerLabel(value) {
  const number = Number(value)
  return Number.isFinite(number) ? String(Math.round(number)) : String(value)
}

function axesFrom(yaxis) {
  if (!yaxis) return []
  return Array.isArray(yaxis) ? yaxis : [yaxis]
}

function needsIntegerTicks(yaxis) {
  return axesFrom(yaxis).some((axis) => axis && (axis.decimalsInFloat === 0 || axis.stepSize === 1))
}

function integerizeAxis(yaxis) {
  if (Array.isArray(yaxis)) return yaxis.map(integerizeAxis)
  if (!yaxis) return yaxis

  return {
    ...yaxis,
    labels: {
      ...(yaxis.labels || {}),
      formatter: integerLabel
    }
  }
}

function withIntegerPageCounts(options = {}) {
  if (!needsIntegerTicks(options.yaxis)) return options

  const tooltip = { ...(options.tooltip || {}) }
  const tooltipY = { ...(tooltip.y || {}) }
  if (typeof tooltipY.formatter !== "function") tooltipY.formatter = integerLabel

  return {
    ...options,
    yaxis: integerizeAxis(options.yaxis),
    tooltip: { ...tooltip, y: tooltipY }
  }
}

function rewriteAxisLabels(element) {
  if (!element) return

  element.querySelectorAll(".apexcharts-yaxis-label tspan, .apexcharts-yaxis-label").forEach((node) => {
    const text = (node.textContent || "").trim()
    if (/^\d+\.0+$/.test(text)) node.textContent = String(Math.round(Number(text)))
  })
}

export default function WrappedApexCharts(el, options) {
  const chart = new ApexCharts(el, withIntegerPageCounts(options))
  if (!needsIntegerTicks(options?.yaxis)) return chart

  const originalRender = chart.render.bind(chart)
  chart.render = () => {
    const rendered = originalRender()
    const finish = (value) => {
      rewriteAxisLabels(el)
      return value
    }

    if (rendered && typeof rendered.then === "function") return rendered.then(finish)
    return finish(rendered)
  }

  return chart
}
