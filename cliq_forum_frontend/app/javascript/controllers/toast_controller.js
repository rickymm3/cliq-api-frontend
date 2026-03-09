import { Controller } from "@hotwired/stimulus"
import { Toast } from "bootstrap"

export default class extends Controller {
  connect() {
    // Auto-show
    const toast = new Toast(this.element, { delay: 5000 });
    toast.show();
    
    // Cleanup modal backdrops if any exist (fix for freezing reports)
    document.querySelectorAll('.modal-backdrop').forEach(el => el.remove());
    document.body.classList.remove('modal-open');
    document.body.style = '';
    
    // Cleanup DOM on hide
    this.element.addEventListener('hidden.bs.toast', () => {
      this.element.remove();
    });
  }
}
