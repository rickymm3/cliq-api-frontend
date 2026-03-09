import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.cleanupAndShowSuccessModal();
  }

  cleanupAndShowSuccessModal() {
    if (typeof window.bootstrap === 'undefined') return;

    // 1. Clean up lingering backdrops from the previous modal
    // Turbo stream replacement destroys the old modal DOM element but NOT the backdrop element
    // attached to the body. We must manually remove it.
    const backdrops = document.querySelectorAll('.modal-backdrop');
    backdrops.forEach(backdrop => backdrop.remove());
    
    document.body.classList.remove('modal-open');
    document.body.style = '';

    // 2. Initialize and show the SUCCESS modal
    const modalEl = document.getElementById('reportModal');
    if (modalEl) {
        // Force cleanup of any old instance
        try {
            const oldModal = window.bootstrap.Modal.getInstance(modalEl);
            if (oldModal) {
                 oldModal.dispose();
            }
        } catch (e) { console.error('Error disposing modal', e); }
        
        // Remove class 'show' and style 'display' just to be clean
        modalEl.classList.remove('show');
        modalEl.style.display = 'none';
        modalEl.removeAttribute('aria-modal');
        modalEl.setAttribute('aria-hidden', 'true');
        modalEl.removeAttribute('role');

        let modal = new window.bootstrap.Modal(modalEl);
        modal.show();
        
        // 3. Auto-hide after 3 seconds
        setTimeout(() => {
            if (modalEl.classList.contains('show')) {
                // Use Bootstrap API to hide if possible
                const modalInstance = window.bootstrap.Modal.getInstance(modalEl);
                if (modalInstance) modalInstance.hide();
            }
        }, 3000);

        
        // Listen for when modal is hidden to remove the trigger element itself if needed
        modalEl.addEventListener('hidden.bs.modal', function () {
           // Optional cleanup if we want to remove the success modal from DOM
        });
    }
  }
  
  show() {
    // connect() runs automatically when the element is added to the DOM
    // But we can explicitly call this if needed.
  }
}
