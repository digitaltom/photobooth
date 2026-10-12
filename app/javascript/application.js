import "@hotwired/turbo-rails"
import "controllers"

// The back/forward cache restores a frozen page without its Turbo Stream subscription
// (for example the gallery after a visit to a set), so fetch it again.
addEventListener("pageshow", (event) => {
  if (event.persisted) Turbo.visit(location.href, { action: "replace" })
})

// The Stream Deck keys (StreamDeck model): open a set, start the countdown.
// Away from the gallery, the shoot key goes back to it first.
Turbo.StreamActions.visit = function () {
  Turbo.visit(this.getAttribute("url"))
}
Turbo.StreamActions.shoot = function () {
  const shoot = () => document.querySelector(".shoot_button")?.click()
  if (document.querySelector(".shoot_button")) return shoot()

  addEventListener("turbo:load", shoot, { once: true })
  Turbo.visit("/")
}
