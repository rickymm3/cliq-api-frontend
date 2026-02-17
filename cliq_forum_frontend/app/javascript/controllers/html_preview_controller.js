import { Controller } from "@hotwired/stimulus"

// This controller takes HTML content and renders it as plain text.
export default class extends Controller {
  static values = {
    html: String,
    length: { type: Number, default: 280 }
  }

  connect() {
    // Create a temporary div to parse the HTML
    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = this.htmlValue

    // Set the element's text content to the parsed text
    let text = tempDiv.textContent || tempDiv.innerText || ""
    
    // Truncate if necessary (leaving room for ellipsis)
    if (this.lengthValue > 0 && text.length > this.lengthValue) {
      text = text.substring(0, this.lengthValue).trim() + "..."
    }
    
    this.element.textContent = text
  }
}
