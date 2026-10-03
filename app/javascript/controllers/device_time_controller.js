import { Controller } from "@hotwired/stimulus"

// Sends the local time of the iPad, the Pi has no real-time clock.
export default class extends Controller {
  static targets = ["input"]

  use() {
    const now = new Date()
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset())
    this.inputTarget.value = now.toISOString().slice(0, 19)
    this.element.requestSubmit()
  }
}
