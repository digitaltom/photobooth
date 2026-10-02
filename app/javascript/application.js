import "@hotwired/turbo-rails"
import "controllers"

// The back/forward cache restores a frozen page without its Turbo Stream subscription
// (for example the gallery after a visit to /kiosk), so fetch it again.
addEventListener("pageshow", (event) => {
  if (event.persisted) Turbo.visit(location.href, { action: "replace" })
})
