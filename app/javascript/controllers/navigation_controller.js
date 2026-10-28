import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop", "toggle"]

  connect() {
    this.close()
  }

  toggle() {
    const expanded = this.toggleTarget.getAttribute("aria-expanded") !== "true"
    this.sidebarTarget.classList.toggle("is-open", expanded)
    this.backdropTarget.hidden = !expanded
    this.toggleTarget.setAttribute("aria-expanded", String(expanded))
    document.body.classList.toggle("menu-open", expanded)
  }

  close() {
    this.sidebarTarget.classList.remove("is-open")
    this.backdropTarget.hidden = true
    this.toggleTarget.setAttribute("aria-expanded", "false")
    document.body.classList.remove("menu-open")
  }

  disconnect() {
    document.body.classList.remove("menu-open")
  }
}
