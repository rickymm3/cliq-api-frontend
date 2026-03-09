import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapsed", "expanded", "trigger"]

  connect() {
    this.collapsedTarget.classList.remove("d-none")
    this.expandedTarget.classList.add("d-none")
  }

  expand(event) {
    event.preventDefault()
    this.collapsedTarget.classList.add("d-none")
    this.expandedTarget.classList.remove("d-none")
  }
}
