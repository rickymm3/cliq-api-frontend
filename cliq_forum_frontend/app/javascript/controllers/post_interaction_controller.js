import { Controller } from "@hotwired/stimulus"
import ApiClient from "../modules/api_client"

export default class extends Controller {
  connect() {
    this.setupEventListeners()
  }

  setupEventListeners() {
    document.querySelectorAll(".post-like-btn").forEach(btn => {
      btn.addEventListener("click", (e) => this.handleLike(e))
    })

    document.querySelectorAll(".post-dislike-btn").forEach(btn => {
      btn.addEventListener("click", (e) => this.handleDislike(e))
    })

    document.querySelectorAll(".post-signal-btn").forEach(btn => {
      btn.addEventListener("click", (e) => this.handleSignal(e))
    })
  }

  handleSignal(e) {
    e.stopPropagation()
    const btn = e.currentTarget
    const postId = btn.dataset.postId
    const isSignaled = btn.dataset.signaled === "true"

    if (isSignaled) {
      this.unsignal(postId, btn)
    } else {
      this.signal(postId, btn)
    }
  }

  signal(postId, button) {
    // Optimistic UI
    this.updateSignalButton(button, true)
    
    ApiClient.api_post(`posts/${postId}/signal`, {})
      .then(response => {
        if (response.status !== "success") {
           // If we get "Post already signaled" (likely 422), we should actually KEEP the state as true
           // because it means our optimistic UI was actually correct (the server just knew it before we did)
           if (response.status === "error" && (response.message.includes("taken") || response.message.includes("already"))) {
             console.log("Post already signaled, syncing state...");
             return; 
           }

           // Revert interaction if failed for other reasons
           this.updateSignalButton(button, false)
        }
      })
      .catch((error) => {
         // handle 422 or network errors
         // If returns 422, it's likely "already signaled"
         if (error.response && error.response.status === 422) {
            console.log("Post already signaled (422), syncing state...");
            return;
         }
         this.updateSignalButton(button, false)
      })
  }

  unsignal(postId, button) {
    // Optimistic UI
    this.updateSignalButton(button, false)
    
    ApiClient.api_delete(`posts/${postId}/unsignal`, {})
      .then(response => {
        if (response.status !== "success") {
           // Revert interaction if failed
           this.updateSignalButton(button, true)
        }
      })
      .catch(() => this.updateSignalButton(button, true))
  }

  updateSignalButton(button, isSignaled) {
    button.dataset.signaled = isSignaled.toString()
    const iconSpan = button.querySelector(".signal-icon-wrapper")
    const icon = iconSpan.querySelector("i")
    const text = iconSpan.querySelector("span")
    
    if (isSignaled) {
      iconSpan.classList.add("text-success")
      icon.className = "bi bi-pin-angle-fill" // Filled Pin
      text.innerText = "Signaled"
    } else {
      iconSpan.classList.remove("text-success")
      icon.className = "bi bi-pin-angle" // Outline Pin
      text.innerText = "Signal"
    }
  }

  handleLike(e) {
    e.stopPropagation()
    const postId = e.currentTarget.dataset.postId
    const currentInteraction = e.currentTarget.dataset.interaction

    if (currentInteraction === "like") {
      // Unlike
      this.unlike(postId, e.currentTarget)
    } else {
      // Like
      this.like(postId, e.currentTarget)
    }
  }

  handleDislike(e) {
    e.stopPropagation()
    const postId = e.currentTarget.dataset.postId
    const currentInteraction = e.currentTarget.dataset.interaction

    if (currentInteraction === "dislike") {
      // Unlike
      this.unlike(postId, e.currentTarget)
    } else {
      // Dislike
      this.dislike(postId, e.currentTarget)
    }
  }

  like(postId, button) {
    ApiClient.api_post(`posts/${postId}/like`, {})
      .then(response => {
        if (response.status === "success") {
          this.updateButton(button, "like")
          this.updateDislikeButton(postId, "neutral")
        }
      })
      .catch(error => console.error("Error liking post:", error))
  }

  dislike(postId, button) {
    ApiClient.api_post(`posts/${postId}/dislike`, {})
      .then(response => {
        if (response.status === "success") {
          this.updateButton(button, "dislike")
          this.updateLikeButton(postId, "neutral")
        }
      })
      .catch(error => console.error("Error disliking post:", error))
  }

  unlike(postId, button) {
    ApiClient.api_delete(`posts/${postId}/unlike`)
      .then(response => {
        if (response.status === "success") {
          this.updateButton(button, "neutral")
        }
      })
      .catch(error => console.error("Error removing interaction:", error))
  }

  updateButton(button, interaction) {
    button.dataset.interaction = interaction
    
    if (button.classList.contains("post-like-btn")) {
      const icon = button.querySelector(".like-icon")
      icon.textContent = interaction === "like" ? "❤️" : "👍"
    } else {
      const icon = button.querySelector(".dislike-icon")
      icon.textContent = interaction === "dislike" ? "👎" : "👎"
    }
  }

  updateLikeButton(postId, interaction) {
    const likeBtn = document.querySelector(`[data-post-id="${postId}"].post-like-btn`)
    if (likeBtn) {
      this.updateButton(likeBtn, interaction)
    }
  }

  updateDislikeButton(postId, interaction) {
    const dislikeBtn = document.querySelector(`[data-post-id="${postId}"].post-dislike-btn`)
    if (dislikeBtn) {
      this.updateButton(dislikeBtn, interaction)
    }
  }
}
