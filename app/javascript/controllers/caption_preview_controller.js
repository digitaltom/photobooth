import { Controller } from "@hotwired/stimulus"

// Shows the caption on the sample polaroid while the admin types.
export default class extends Controller {
  static targets = ["input", "output"]

  update() {
    this.outputTarget.textContent = this.inputTarget.value
  }
}
