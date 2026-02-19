import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "idField", "results", "selectionDisplay", "selectionName"]

  connect() {
    this.searchUrl = "/api/cliqs/search?q="
  }

  // TODO: Debounce this function in production
  search(event) {
    const query = this.inputTarget.value.trim()
    
    if (query.length < 2) {
      this.resultsTarget.style.display = "none"
      return
    }

    // Call API (In frontend app, we might need a proxy or we can use the rails endpoint if it exists)
    // Here we are in frontend, so we can use a fetch to internal API or reconstruct the call
    // Assuming we can hit /search?q=... which we already have in frontend routes: get "search", to: "search#index"
    // Wait, the frontend search controller returns HTML by default. We want JSON.
    // The backend API is at localhost:3000/api/cliqs/search
    
    // For now, we'll assume we can use the same search endpoint used elsewhere or add one.
    // Let's rely on the existing autocomplete logic if any, or build a simple one.
    
    // We can fetch from /search?q=...&format=json if we updated the SearchController
    // But SearchController#index mainly searches posts.
    
    // Let's fetch directly from the backend API if possible, OR via a proxy action.
    // However, in this environment, CORS might be an issue if we fetch 3000 from 3001.
    // So we should proxy via the frontend rails server if needed.
    // But wait, the previous `create_child` form didn't need search.
    


    // Use the frontend proxy route to search for cliqs
    console.log(`Searching for: ${query}`)
    fetch(`/cliqs/search?q=${encodeURIComponent(query)}&per_page=20`, {
      method: "GET",
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
      .then(response => {
        if (!response.ok) {
           throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        console.log("Search results:", data)
        // The API returns { data: [...], pagination: ... }
        this.renderResults(data.data || [])
      })
      .catch(error => {
        console.error("Search error:", error)
      })
  }

  renderResults(cliqs) {
    if (!cliqs || cliqs.length === 0) {
      this.resultsTarget.style.display = "none"
      return
    }
    
    this.resultsTarget.innerHTML = ""
    this.resultsTarget.style.display = "block"

    cliqs.forEach(cliq => {
      const item = document.createElement("a")
      item.href = "#"
      item.classList.add("list-group-item", "list-group-item-action")
      item.innerHTML = `
        <div class="d-flex justify-content-between align-items-center">
          <span class="fw-bold">${cliq.name}</span>
          <span class="badge bg-light text-dark border">ID: ${cliq.id}</span>
        </div>
        <div class="text-muted small fst-italic my-1">
          ${cliq.hierarchy || "Root Level"}
        </div>
        <small class="text-muted d-block text-truncate" style="max-width: 100%;">${cliq.description || ""}</small>
      `
      
      item.addEventListener("click", (e) => {
        e.preventDefault()
        this.selectCliq(cliq)
      })
      
      this.resultsTarget.appendChild(item)
    })
  }

  selectCliq(cliq) {
    this.idFieldTarget.value = cliq.id
    this.inputTarget.value = ""
    this.resultsTarget.style.display = "none"
    
    this.selectionNameTarget.textContent = cliq.name
    this.selectionDisplayTarget.classList.remove("d-none")
    this.selectionDisplayTarget.classList.add("d-block")
  }
  
  clear() {
    this.idFieldTarget.value = ""
    this.selectionDisplayTarget.classList.add("d-none")
    this.selectionDisplayTarget.classList.remove("d-block")
    this.inputTarget.focus()
  }
}
