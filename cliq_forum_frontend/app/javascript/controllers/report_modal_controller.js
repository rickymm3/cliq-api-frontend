import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener('show.bs.modal', this.populateData.bind(this));
  }

  disconnect() {
    this.element.removeEventListener('show.bs.modal', this.populateData.bind(this));
  }

  populateData(event) {
    const button = event.relatedTarget;
    if (!button) return;
    
    const targetId = button.getAttribute('data-report-target-id');
    const type = button.getAttribute('data-report-target-type');
    const cliqId = button.getAttribute('data-report-cliq-id');
    
    this.element.querySelector('#report_cliq_id').value = cliqId || '';
    
    if (type === 'post') {
      this.element.querySelector('#report_post_id').value = targetId;
      this.element.querySelector('#report_reply_id').value = '';
    } else if (type === 'reply') {
      this.element.querySelector('#report_reply_id').value = targetId;
      this.element.querySelector('#report_post_id').value = '';
    }
  }
}
