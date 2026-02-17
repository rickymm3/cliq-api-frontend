import { Controller } from "@hotwired/stimulus"
import { Dropdown } from "bootstrap"

export default class extends Controller {
  connect() {
    // We initialize the dropdown on the element (the button)
    this.dropdown = new Dropdown(this.element)
  }

  disconnect() {
    if (this.dropdown) {
      this.dropdown.dispose()
    }
  }

  // Add a toggle method to be 100% sure the click works
  toggle(event) {
    event.preventDefault()
    this.dropdown.toggle()
  }
}