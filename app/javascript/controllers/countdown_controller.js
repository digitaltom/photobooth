import { Controller } from "@hotwired/stimulus"

// Shows the dialog and counts down on the client, then posts the form.
// From then on the CaptureJob broadcasts each step into #kiosk-status.
// The quit button only shows during the countdown, Escape also stops a running capture job.
export default class extends Controller {
  static targets = ["form", "dialog", "text", "progress", "status", "quit"]
  static values = { delay: { type: Number, default: 2000 }, text: { type: String, default: "Take pose!" } }

  start() {
    if (this.dialogTarget.open) return

    document.getElementById("kiosk-status").replaceChildren(this.statusTarget.content.cloneNode(true))
    this.textTarget.textContent = this.textValue
    this.progressTarget.hidden = false
    this.progressTarget.value = 100
    this.quitTarget.hidden = false
    this.dialogTarget.showModal()
    this.streamDeck(this.delayValue)

    const steps = 20
    let step = 0
    this.timer = setInterval(() => {
      this.progressTarget.value = 100 - (++step * 100) / steps
      if (step < steps) return

      clearInterval(this.timer)
      this.textTarget.textContent = ""
      this.progressTarget.hidden = true
      this.quitTarget.hidden = true
      this.formTarget.requestSubmit()
    }, this.delayValue / steps)
  }

  quit() {
    this.dialogTarget.close()
  }

  // a tap on the backdrop quits like the quit button, while the capture job runs it does nothing
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget && !this.quitTarget.hidden) this.quit()
  }

  // on every close of the dialog (quit button, Escape key, error, job done): no picture after it,
  // a running capture job stops (SetsController#countdown)
  stop() {
    clearInterval(this.timer)
    this.streamDeck(0)
  }

  // the Stream Deck counts down too and then shows the shoot, 0: the dialog closed
  // The token of the page: the token in the form only fits its own URL (per form CSRF tokens).
  streamDeck(delay) {
    const token = document.querySelector("meta[name=csrf-token]")?.content
    fetch("/countdown", { method: "POST", headers: { "X-CSRF-Token": token, "Content-Type": "application/json" },
                          body: JSON.stringify({ delay }) })
  }
}
