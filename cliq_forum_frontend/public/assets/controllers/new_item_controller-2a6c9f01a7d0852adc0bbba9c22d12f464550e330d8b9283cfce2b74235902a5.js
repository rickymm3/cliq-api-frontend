import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scrollIntoView()
    this.addHighlight()
  }

  scrollIntoView() {
    // Wait for render
    requestAnimationFrame(() => {
        this.element.scrollIntoView({ behavior: "smooth", block: "center" })
        
        // Force focus sequence
        this.element.focus()
        setTimeout(() => this.element.focus(), 100)
    })
  }

  addHighlight() {
    console.log("New Item: Highlighting", this.element.id)
    this.element.classList.add("flash-highlight")
    
    // Cleanup class after animation (approx 3s safely)
    setTimeout(() => {
      this.element.classList.remove("flash-highlight")
    }, 3000)
  }
};
