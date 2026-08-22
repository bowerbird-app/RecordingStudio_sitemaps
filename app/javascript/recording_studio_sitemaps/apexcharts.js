import ApexCharts from "https://cdn.jsdelivr.net/npm/apexcharts@3.45.1/dist/apexcharts.esm.js"

function integerLabel(value) {
  const number = Number(value)
  return Number.isFinite(number) ? String(Math.round(number)) : String(value)
}

function decorateYAxis(yaxis) {
  if (Array.isArray(yaxis)) return yaxis.map(decorateYAxis)
  if (!yaxis || yaxis.decimalsInFloat !== 0) return yaxis
  if (typeof yaxis.labels?.formatter === "function") return yaxis

  return {
    ...yaxis,
    labels: {
      ...(yaxis.labels || {}),
      formatter: integerLabel
    }
  }
}

function withIntegerPageCounts(options = {}) {
  return {
    ...options,
    yaxis: decorateYAxis(options.yaxis)
  }
}

export default class extends ApexCharts {
  constructor(el, options) {
    super(el, withIntegerPageCounts(options))
  }
}
