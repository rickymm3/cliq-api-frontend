import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }

document.addEventListener("turbo:frame-load", (event) => {
  console.log("Turbo Frame loaded, Stimulus should already be connected.");
  const frame = event.target; // The frame that was loaded
  if (frame.id === "cliq-search-results") {
    console.log("Turbo Frame 'cliq-search-results' content updated.");
    // You can run additional logic here if needed
  }
});

document.addEventListener('click', (e) => {
  document.querySelectorAll('.cliq-dropdown').forEach(drop => {
    if (!drop.contains(e.target)) {
      drop.querySelector('.cliq-dropdown__options').classList.remove('open');
    }
  });
});