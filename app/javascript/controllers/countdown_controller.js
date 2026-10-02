import { Controller } from "@hotwired/stimulus"

// Shows the dialog and counts down on the client, then posts the form.
// From then on the CaptureJob broadcasts each step into #kiosk-status.
export default class extends Controller {
  static targets = ["form", "dialog", "text", "progress", "status"]
  static values = { delay: { type: Number, default: 2000 } }

  start() {
    if (this.dialogTarget.open) return

    document.getElementById("kiosk-status").replaceChildren(this.statusTarget.content.cloneNode(true))
    this.textTarget.textContent = "Take pose!"
    this.progressTarget.hidden = false
    this.progressTarget.value = 100
    this.dialogTarget.showModal()

    const steps = 20
    let step = 0
    const timer = setInterval(() => {
      this.progressTarget.value = 100 - (++step * 100) / steps
      if (step < steps) return

      clearInterval(timer)
      this.textTarget.textContent = ""
      this.progressTarget.hidden = true
      this.formTarget.requestSubmit()
    }, this.delayValue / steps)
  }
}
