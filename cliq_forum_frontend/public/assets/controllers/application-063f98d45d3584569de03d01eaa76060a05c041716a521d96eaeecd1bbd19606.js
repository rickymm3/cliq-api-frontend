import { Application } from "@hotwired/stimulus"

console.log("Stimulus Application Initializing...")
const application = Application.start()

// Configure Stimulus development experience
application.debug = true // ENABLE DEBUG
window.Stimulus   = application

export { application };
