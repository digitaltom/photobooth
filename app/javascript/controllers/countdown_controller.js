import { Controller } from "@hotwired/stimulus"

// Shows the dialog and counts down on the client, then posts the form.
// From then on the CaptureJob broadcasts each step into #kiosk-status.
// The quit button only shows during the countdown: a running capture job cannot be stopped.
export default class extends Controller {
  static targets = ["form", "dialog", "text", "progress", "status", "quit"]
  static values = { delay: { type: Number, default: 2000 } }

  start() {
    if (this.dialogTarget.open) return

    document.getElementById("kiosk-status").replaceChildren(this.statusTarget.content.cloneNode(true))
    this.textTarget.textContent = "Take pose!"
    this.progressTarget.hidden = false
    this.progressTarget.value = 100
    this.quitTarget.hidden = false
    this.dialogTarget.showModal()

    const steps = 20
    let step = 0
    this.timer = setInterval(() => {
      this.progressTarget.value = 100 - (++step * 100) / steps
      if (step < steps) return

      this.stop()
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

  // on every close of the dialog (quit button, Escape key, job done): no picture after it
  stop() {
    clearInterval(this.timer)
  }
}
