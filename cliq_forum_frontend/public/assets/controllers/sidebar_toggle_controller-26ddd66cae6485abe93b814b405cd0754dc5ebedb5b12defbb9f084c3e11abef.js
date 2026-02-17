import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay", "toggle"]

  toggle() {
    this.sidebarTarget.classList.toggle("expanded")
    this.overlayTarget?.classList.toggle("visible")
    document.body.style.overflow = this.sidebarTarget.classList.contains("expanded") ? "hidden" : ""
  }

  close() {
    this.sidebarTarget.classList.remove("expanded")
    this.overlayTarget?.classList.remove("visible")
    document.body.style.overflow = ""
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  connect() {
    document.addEventListener("keydown", (e) => this.closeOnEscape(e))
  }

  disconnect() {
    document.removeEventListener("keydown", (e) => this.closeOnEscape(e))
  }
};
