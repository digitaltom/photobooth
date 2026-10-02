import { Controller } from "@hotwired/stimulus"

// Closes the surrounding dialog as soon as the job broadcasts this element.
export default class extends Controller {
  connect() {
    this.element.closest("dialog")?.close()
  }
}
