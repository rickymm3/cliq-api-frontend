// app/javascript/controllers/image_lightbox_controller.js
import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

let modalElement = null;
let modalInstance = null;
let modalImage = null;

function ensureModal() {
  if (modalElement && document.body.contains(modalElement)) {
    console.log("[image-lightbox] Reusing existing modal element");
    return modalElement;
  }

  modalElement = document.getElementById("imageLightboxModal");
  if (!modalElement) {
    console.log("[image-lightbox] Creating modal element and injecting into DOM");
    modalElement = document.createElement("div");
    modalElement.id = "imageLightboxModal";
    modalElement.className = "modal fade";
    modalElement.setAttribute("tabindex", "-1");
    modalElement.setAttribute("aria-hidden", "true");
    modalElement.setAttribute("data-turbo-permanent", "true");
    modalElement.innerHTML = `
      <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content lightbox-modal">
          <div class="modal-body p-0">
            <button type="button" class="lightbox-modal__close" data-bs-dismiss="modal" aria-label="Close">×</button>
            <img class="lightbox-modal__image" src="" alt="">
          </div>
        </div>
      </div>
    `;
    document.body.appendChild(modalElement);
  }

  modalImage = modalElement.querySelector(".lightbox-modal__image");
  modalInstance = Modal.getOrCreateInstance(modalElement, {
    backdrop: true,
    focus: true
  });

  console.log("[image-lightbox] Bootstrap modal instance ready", { modalElement, modalInstance });

  if (!modalElement.dataset.lightboxReady) {
    console.log("[image-lightbox] Wiring cleanup handler on modal hide");
    modalElement.addEventListener("hidden.bs.modal", () => {
      if (modalImage) {
        console.log("[image-lightbox] Modal hidden, clearing image src");
        modalImage.src = "";
      }
    });
    modalElement.dataset.lightboxReady = "true";
  }

  return modalElement;
}

export default class extends Controller {
  static values = {
    url: String
  };

  connect() {
    console.log("[image-lightbox] Controller connected", this.element);
  }

  open(event) {
    event.preventDefault();
    console.log("[image-lightbox] Open requested", this.element);
    const url =
      this.urlValue ||
      this.element.dataset.lightboxUrlValue ||
      this.element.dataset.lightboxUrl;

    if (!url) {
      console.warn("[image-lightbox] No URL provided for lightbox image");
      return;
    }

    ensureModal();
    if (!modalInstance || !modalImage) {
      console.error("[image-lightbox] Modal instance not ready");
      return;
    }

    console.log("[image-lightbox] Showing image", url);
    modalImage.src = url;
    modalInstance.show();
  }
}
