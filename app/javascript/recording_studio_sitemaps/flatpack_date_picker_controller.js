import DatePicker from "recording_studio_sitemaps/flatpack_date_picker_original"

// Admin's last_30_days window is today minus 30 days. Flatpack's stock
// controller has no that key, so teach the same DateRangeInput widget.
export default class extends DatePicker {
  computePresetRange(key) {
    if (key === "last_30_days") {
      return { start: this.addDays(this.today, -30), end: this.today }
    }

    return super.computePresetRange(key)
  }
}
