import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

class AttachmentUpload {
  constructor(attachment, controller) {
    this.attachment = attachment
    this.controller = controller
    this.directUpload = new DirectUpload(attachment.file, controller.directUploadUrlValue, this)
  }

  start() {
    this.directUpload.create(this.directUploadDidComplete.bind(this))
  }

  directUploadWillStoreFileWithXHR(xhr) {
    xhr.upload.addEventListener("progress", event => {
      const progress = event.loaded / event.total * 100
      this.attachment.setUploadProgress(progress)
    })
  }

  directUploadDidComplete(error, blob) {
    if (error) {
      console.error("Direct upload failed:", error)
      alert("Upload failed. Please try again.")
      this.attachment.remove()
    } else {
      this.attachment.setAttributes({
        url: this.createBlobUrl(blob),
        sgid: blob.signed_id
      })
    }
  }

  createBlobUrl(blob) {
    const baseUrl = this.controller.directUploadUrlValue.replace(/\/rails\/active_storage\/direct_uploads$/, "")
    return `${baseUrl}/rails/active_storage/blobs/redirect/${blob.signed_id}/${encodeURIComponent(blob.filename)}`
  }
}

export default class extends Controller {
  static values = {
    directUploadUrl: String
  }

  connect() {
    const form = this.element.closest("form")
    if (form) {
      form.addEventListener("submit", this.syncContent.bind(this))
    }
    this.element.addEventListener("trix-attachment-add", this.upload.bind(this))
  }

  syncContent() {
    const trixEditor = this.element.querySelector("trix-editor")
    const hiddenField = this.element.querySelector("input[type='hidden']")
    
    if (trixEditor && hiddenField) {
      // Sync Trix content to hidden field
      hiddenField.value = trixEditor.value || ""
    }
  }

  upload(event) {
    const attachment = event.attachment
    if (attachment.file) {
      const upload = new AttachmentUpload(attachment, this)
      upload.start()
    }
  }
}


