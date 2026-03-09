ximport { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { id: String, kind: String }
  static targets = ["yesCount", "noCount", "status", "buttons", "result"]

  voteYes(event) {
    event.preventDefault()
    this.vote(true)
  }

  voteNo(event) {
    event.preventDefault()
    this.vote(false)
  }

  vote(value) {
    fetch(`/alliance_proposals/${this.idValue}/vote`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").getAttribute("content")
      },
      body: JSON.stringify({ value: value })
    })
    .then(response => response.json())
    .then(data => {
      // API returns { status: "success", yes_votes: N, no_votes: M, proposal_status: "approved" }
      if (data.status === "success") {
        this.updateUI(data)
      } else {
        alert(data.error || "Failed to vote")
      }
    })
    .catch(error => console.error("Error:", error))
  }

  updateUI(data) {
    if (this.hasYesCountTarget) this.yesCountTarget.textContent = data.yes_votes
    if (this.hasNoCountTarget) this.noCountTarget.textContent = data.no_votes

    if (data.proposal_status === "approved" || data.proposal_status === "rejected") {
      // Hide buttons
      if (this.hasButtonsTarget) {
        this.buttonsTarget.classList.add("d-none")
      }

      // Show Result
      if (this.hasResultTarget) {
        this.resultTarget.classList.remove("d-none")
        const isDisband = this.kindValue === "disband_alliance"
        
        if (data.proposal_status === "approved") {
          this.resultTarget.className = "alert alert-success py-2 mb-0"
          const message = isDisband ? "Alliance Dissolved" : "Alliance Formed"
          this.resultTarget.innerHTML = `<i class="bi bi-check-circle-fill me-2"></i>${message}`
        } else {
          this.resultTarget.className = "alert alert-danger py-2 mb-0"
          const message = isDisband ? "Dissolution Rejected" : "Alliance Rejected"
          this.resultTarget.innerHTML = `<i class="bi bi-x-circle-fill me-2"></i>${message}`
        }
      }

      // Update badge if present
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = data.proposal_status.charAt(0).toUpperCase() + data.proposal_status.slice(1)
        this.statusTarget.className = (data.proposal_status === "approved") ? "badge bg-success" : "badge bg-danger"
      }
    }
  }
}

