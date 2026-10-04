import { Controller } from "@hotwired/stimulus"

// A modal dialog that a tap on the backdrop closes.
// Unlike a popover, the modal dialog gets that tap, so the button behind it does not.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  // the backdrop belongs to the dialog element, the content is in a child element
  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.dialogTarget.close()
  }
}
