import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "banner", "label", "editor", "container"]

  connect() {
    console.log("Reply Linker Connected")
  }

  setTarget(event) {
    event.preventDefault() // Ensure link clicks don't navigate
    console.log("Reply Linker: setTarget triggered")
    try {
      const button = event.currentTarget
      const replyId = button.dataset.id
      const author = button.dataset.author

      // Show the container first
      if (this.hasContainerTarget) {
        console.log("Reply Linker: Showing container")
        this.containerTarget.style.display = "block"
        this.containerTarget.classList.remove("d-none") 
      } else {
        console.error("Reply Linker: Container target missing!")
      }

      // Set hidden input
      if (this.hasInputTarget) {
        this.inputTarget.value = replyId
      } else {
         console.error("Reply Linker: Input target missing!")
      }

      // Update banner UI if replying to specific person
      if (replyId) {
        if (this.hasLabelTarget) this.labelTarget.textContent = `Replying to @${author}`
        if (this.hasBannerTarget) this.bannerTarget.classList.remove("d-none")
      } else {
        // General reply to topic
        if (this.hasBannerTarget) this.bannerTarget.classList.add("d-none")
      }

      // Scroll to editor
      if (this.hasEditorTarget) {
        this.editorTarget.scrollIntoView({ behavior: "smooth", block: "center" })
        // Focus the trix editor
        requestAnimationFrame(() => {
          const trixEditor = this.editorTarget.querySelector("trix-editor")
          if (trixEditor) {
            trixEditor.focus()
            
            // Double check focus incase of transition lag
            setTimeout(() => {
              if (document.activeElement !== trixEditor) {
                trixEditor.focus()
              }
            }, 100)
          }
        })
      }
    } catch (e) {
      console.error("Reply Linker Error:", e)
    }
  }

  clearTarget(event) {
    if (event) event.preventDefault()
    
    // Clear input
    this.inputTarget.value = ""
    
    // Hide banner
    this.bannerTarget.classList.add("d-none")
    
    // Hide container (close the drawer)
    if (this.hasContainerTarget) {
      this.containerTarget.style.display = "none"
    }
  }
};
