import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: String }
  static targets = ["yesCount", "noCount", "status"]

  voteYes(event) {
    event.preventDefault()
    this.submitVote(true)
  }

  voteNo(event) {
    event.preventDefault()
    this.submitVote(false)
  }

  submitVote(value) {
    fetch(`/merge_proposals/${this.idValue}/vote`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content")
      },
      body: JSON.stringify({ value: value })
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === "success" || data.status === "ok") {
        this.updateCounts(data.data)
      } else {
        alert(data.message || "Voting failed")
      }
    })
    .catch(error => {
      console.error("Error voting:", error)
    })
  }

  updateCounts(data) {
    if (this.hasYesCountTarget) this.yesCountTarget.textContent = data.yes_votes
    if (this.hasNoCountTarget) this.noCountTarget.textContent = data.no_votes
    if (this.hasStatusTarget && data.status) this.statusTarget.textContent = data.status
  }
}
