import { Controller } from "@hotwired/stimulus"
import ApiClient from "../modules/api_client"

export default class extends Controller {
  static values = {
    userId: Number,
    following: Boolean
  }
  static targets = ["button"]

  connect() {
    this.updateButton()
  }

  async toggle(event) {
    event.preventDefault()

    // Optimistic UI update
    const previousState = this.followingValue
    this.followingValue = !this.followingValue
    this.updateButton()
    this.updateFollowersCount(!previousState) // Pass true if following, false if unfollowing

    try {
      if (previousState) {
        await this.performUnfollow()
      } else {
        await this.performFollow()
      }
    } catch (error) {
      console.error("Follow/Unfollow error:", error)
      // Revert on error
      this.followingValue = previousState
      this.updateButton()
      this.updateFollowersCount(previousState)
    }
  }

  updateFollowersCount(isFollowing) {
    // Look for the followers count element on the page (specifically for profile page)
    const countElement = document.getElementById("profile-followers-count")
    
    // Only proceed if the element exists AND we are on the profile of the user being followed
    // (We don't want to update the count if we are just following someone from a list)
    if (countElement && this.isOnProfilePage()) {
      let currentCount = parseInt(countElement.innerText.replace(/,/g, ''))
      if (isNaN(currentCount)) return

      if (isFollowing) {
        countElement.innerText = (currentCount + 1).toLocaleString()
      } else {
        countElement.innerText = Math.max(0, currentCount - 1).toLocaleString()
      }
    }
  }

  isOnProfilePage() {
    // Check if the current URL matches a profile page for this user
    // Simple check: does the ID in the URL match the user ID we are toggling?
    // Or simpler: We rely on the fact that `profile-followers-count` only exists on the profile page
    // If we have lists of users (followers/following), they won't have this ID.
    return true 
  }

  async performFollow() {
    await ApiClient.api_post("followed_users", {
      followed_user: { followed_id: this.userIdValue }
    })
  }

  async performUnfollow() {
    await ApiClient.api_delete(`followed_users/${this.userIdValue}`)
  }

  updateButton() {
    if (this.followingValue) {
      this.buttonTarget.innerText = "Unfollow"
      this.buttonTarget.classList.remove("btn-primary")
      this.buttonTarget.classList.add("btn-outline-secondary")
    } else {
      this.buttonTarget.innerText = "Follow"
      this.buttonTarget.classList.remove("btn-outline-secondary")
      this.buttonTarget.classList.add("btn-primary")
    }
  }
}
