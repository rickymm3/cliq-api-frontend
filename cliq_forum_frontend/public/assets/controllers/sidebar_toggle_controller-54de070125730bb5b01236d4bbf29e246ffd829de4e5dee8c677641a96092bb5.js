import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  connect() {
    document.addEventListener("keydown", (e) => this.closeOnEscape(e))
  }

  disconnect() {
    document.removeEventListener("keydown", (e) => this.closeOnEscape(e))
  }

  toggle(event) {
    event?.preventDefault()
    const sidebar = this.sidebarTarget
    const isExpanded = sidebar.classList.contains("expanded")
    
    if (isExpanded) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.sidebarTarget.classList.add("expanded")
    this.overlayTarget.classList.add("visible")
    document.body.style.overflow = "hidden"
  }

  close() {
    this.sidebarTarget.classList.remove("expanded")
    this.overlayTarget.classList.remove("visible")
    document.body.style.overflow = ""
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }
}
;
