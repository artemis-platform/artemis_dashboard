import ApexCharts from "apexcharts"

const ApexChartHelpers = {}

// Helpers - Instances

ApexChartHelpers.instances = {}

ApexChartHelpers.get_instance = function (id) {
  return ApexChartHelpers.instances[id]
}

ApexChartHelpers.register_instance = function (id, chart) {
  ApexChartHelpers.instances[id] = chart
}

// Helpers - Phoenix LiveView

ApexChartHelpers.live_view_hooks = {
  mounted() {
    var id = this.el.attributes["phx-socket-id"].value
    var chart = ApexChartHelpers.get_instance(id)

    chart.render()
  },
  updated() {
    var id = this.el.attributes["phx-socket-id"].value
    var chart = ApexChartHelpers.get_instance(id)
    var updates = JSON.parse(this.el.attributes["chart-updates"].value)

    chart.updateOptions(updates)
  }
}

// Global Assignments

global.ApexCharts = ApexCharts
global.ApexChartHelpers = ApexChartHelpers

// Exports

export default ApexChartHelpers
