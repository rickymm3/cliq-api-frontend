import { Controller } from "@hotwired/stimulus"
import ApiClient from "../modules/api_client"

export default class extends Controller {
  static values = {
    postId: String,
    initialVote: String // API returns as stringified enum key or int?
  }
  
  static targets = ["keepButton", "removeButton"]

  initialize() {
    this.syncVote = this.syncVote.bind(this)
  }
  
  // Clean up duplicate connect method
  connect() {
    this.restoreState()
    this.channel = new BroadcastChannel("moderation_channel")
    
    // Listen for local events
    window.addEventListener("moderation:voted", this.syncVote)
    
    // Listen for cross-tab events via BroadcastChannel
    this.channel.onmessage = (event) => {
      // Avoid duplicate processing if this tab also fired the local event
      // However, since BroadcastChannel doesn't fire for the sender, this is safe for self.
      // For other components on the SAME page, they will receive both Window event and Broadcast event.
      // We can deduplicate or just let it replace content twice (idempotent UI update).
      // Given updateUI is idempotent, we'll keep it simple.
      if (String(event.data.postId) === String(this.postIdValue)) {
         this.updateUI(event.data.voteType)
      }
    }
  }

  restoreState() {
    let vote = this.initialVoteValue
    
    // Safety check - handle potential "null" string or actual null
    if (!vote || vote === "null") return

    // Convert stringified "keep"/"remove" to expected format if necessary
    if (vote === "keep" || vote === "1" || vote == 1) {
      this.updateUI(1)
    } else if (vote === "remove" || vote === "0" || vote == 0) {
      this.updateUI(0)
    }
  }

  disconnect() {
    window.removeEventListener("moderation:voted", this.syncVote)
    if (this.channel) this.channel.close()
  }

  syncVote(event) {
    if (String(event.detail.postId) === String(this.postIdValue)) {
       this.updateUI(event.detail.voteType)
    }
  }

  voteKeep(event) {
    this.submitVote(1, event.currentTarget)
  }

  voteRemove(event) {
    this.submitVote(0, event.currentTarget)
  }

  async submitVote(voteType, button) {
    const originalText = button.innerHTML
    button.disabled = true
    button.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>'

    try {
      // Create request payload
      // In ApiClient.api_post(path, data), `data` is the JSON body
      const payload = {
        vote_type: voteType
      }
      
      const response = await ApiClient.api_post(`posts/${this.postIdValue}/moderation_vote`, payload)

      if (response.status === "created" || response.status === 201 || (response.status === "success")) {
        // Dispatch custom global event to notify other controllers
        const event = new CustomEvent("moderation:voted", { 
          detail: { 
            postId: this.postIdValue, 
            voteType: voteType 
          } 
        });
        window.dispatchEvent(event);
        
        // Broadcast to other tabs
        if (this.channel) {
          this.channel.postMessage({
            postId: this.postIdValue,
            voteType: voteType
          })
        }
      } else {
        console.error("Vote failed:", response)
        button.innerHTML = originalText
        button.disabled = false
        alert("Failed to submit vote: " + (response.error || "Unknown error"))
      }
    } catch (error) {
      // This ensures errors are logged but doesn't break the UI immediately if it's just a duplicate
      console.error("Vote error context:", error)
      button.innerHTML = originalText
      button.disabled = false
      alert("An error occurred. Please try again.")
    }
  }
  
  updateUI(voteType) {
    // 1 = Keep, 0 = Remove
    if (voteType === 1) {
       // Check if innerHTML replacement is safe/desired - for democracy console buttons it might need different text
       // But the controller is shared, so we should keep it consistent or check if customized text needed.
       // The original buttons had "Vote to Keep". The replacement is "Voted to Keep". This seems fine.
       this.keepButtonTarget.innerHTML = '<i class="bi bi-check-circle-fill me-1"></i> Voted to Keep'
       this.keepButtonTarget.classList.replace("btn-outline-success", "btn-success")
       this.disableAll()
    } else {
       this.removeButtonTarget.innerHTML = '<i class="bi bi-x-circle-fill me-1"></i> Voted to Remove'
       this.removeButtonTarget.classList.replace("btn-outline-danger", "btn-danger")
       this.disableAll()
    }
  }
  
  disableAll() {
    [this.keepButtonTarget, this.removeButtonTarget].forEach(btn => {
      btn.disabled = true
      if (!btn.classList.contains("btn-success") && !btn.classList.contains("btn-danger")) {
        btn.classList.add("opacity-50")
      }
    })
  }
}
