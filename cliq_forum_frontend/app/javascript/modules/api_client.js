const API_BASE = "http://localhost:3000/api"

class ApiClient {
  static getAuthToken() {
    return localStorage.getItem("auth_token")
  }

  static getHeaders(includeContentType = true) {
    const headers = {}
    const token = this.getAuthToken()
    
    // Also try to get token from meta tag if not in localStorage (fallback)
    const metaToken = document.querySelector('meta[name="auth-token"]')?.content
    const finalToken = token || metaToken
    
    if (finalToken) {
      headers["Authorization"] = `Bearer ${finalToken}`
    }
    
    if (includeContentType) {
      headers["Content-Type"] = "application/json"
    }
    
    return headers
  }

  static async api_get(path, params = {}) {
    const url = new URL(`${API_BASE}/${path}`)
    Object.keys(params).forEach(key => url.searchParams.append(key, params[key]))
    
    const response = await fetch(url.toString(), {
      method: "GET",
      headers: this.getHeaders(false)
    })
    
    return response.json()
  }

  static async api_post(path, data) {
    const url = `${API_BASE}/${path}`
    
    const response = await fetch(url, {
      method: "POST",
      headers: this.getHeaders(true),
      body: JSON.stringify(data)
    })
    
    return response.json()
  }

  static async api_delete(path) {
    const url = `${API_BASE}/${path}`
    
    const response = await fetch(url, {
      method: "DELETE",
      headers: this.getHeaders(true)
    })
    
    if (response.status === 204) {
      return null
    }
    
    return response.json()
  }

  static async api_patch(path, data) {
    const url = `${API_BASE}/${path}`
    
    const response = await fetch(url, {
      method: "PATCH",
      headers: this.getHeaders(true),
      body: JSON.stringify(data)
    })
    
    return response.json()
  }
}

export default ApiClient
