import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["parents"]

  toggleParents(event) {
    event.preventDefault()
    this.parentsTarget.classList.toggle("hidden")
  }
}
