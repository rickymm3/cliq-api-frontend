import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    this.visible = false
    console.log("Toggle Controller Connected")
  }

  toggle(event) {
    console.log("Toggle Clicked")
    event.preventDefault()
    this.visible = !this.visible
    
    if (this.visible) {
      this.contentTarget.classList.remove("d-none")
      // Rotate icon if we had one, or simple state change
    } else {
      this.contentTarget.classList.add("d-none")
    }
  }
};
