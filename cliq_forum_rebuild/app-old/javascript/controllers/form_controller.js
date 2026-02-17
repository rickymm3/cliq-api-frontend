import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Form controller connected")
  }

  disable(event) {
    event.preventDefault()
    this.element.requestSubmit()
    this.element.querySelector("input[type=submit]").setAttribute("disabled", true)
  }
}