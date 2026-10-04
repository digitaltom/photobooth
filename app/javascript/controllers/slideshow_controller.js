import { Controller } from "@hotwired/stimulus"

// Shows the next set when the progress bar is full: the CSS animation sets the time.
// Not a <meta http-equiv="refresh">: Turbo keeps the document, so its timer would still fire on other pages.
export default class extends Controller {
  static values = { next: String }

  next() {
    Turbo.visit(this.nextValue)
  }
}
