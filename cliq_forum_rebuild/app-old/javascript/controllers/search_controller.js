// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "dropdown"];

  connect() {
    this.timeout = null;
  }

  search() {
    const query = this.inputTarget.value.trim();
    if (!query.length) {
      clearTimeout(this.timeout);
      this.hideDropdown();
      return;
    }
    clearTimeout(this.timeout);
    this.timeout = setTimeout(() => {
      const form = this.element.querySelector("form");
      if (form) {
        form.requestSubmit();
      }
      this.showDropdown();
    }, 200);
  }

  clearFormAndHideDropdown(event) {
    event.preventDefault();
    // Clear the search input and force it to lose focus.
    this.inputTarget.value = "";
    this.inputTarget.blur();
    // Hide the dropdown.
    this.hideDropdown();
    // Trigger Turbo navigation to the link's href.
    const link = event.currentTarget;
    if (link && link.getAttribute("href")) {
      Turbo.visit(link.getAttribute("href"));
    }
  }

  hideDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.remove("show");
    }
  }

  showDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add("show");
    }
  }

  select() {
    this.hideDropdown();
    if (this.hasInputTarget) {
      this.inputTarget.value = "";
      this.inputTarget.blur();
    }
  }
}
