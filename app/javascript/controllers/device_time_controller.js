import { Controller } from "@hotwired/stimulus"

// Sends the local time of the iPad, the Pi has no real-time clock.
// The button shows that time without seconds, the sent time keeps them.
export default class extends Controller {
  static targets = ["input", "label"]

  connect() {
    this.update()
    this.timer = setInterval(() => this.update(), 1000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  update() {
    this.labelTarget.textContent = new Date().toLocaleString(undefined, { dateStyle: "short", timeStyle: "short" })
  }

  use() {
    const now = new Date()
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset())
    this.inputTarget.value = now.toISOString().slice(0, 19)
    this.element.requestSubmit()
  }
}
