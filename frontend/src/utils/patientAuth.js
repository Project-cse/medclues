import axios from 'axios'

export const TOKEN_KEY = 'token'
export const REFRESH_KEY = 'refresh_token'

let refreshPromise = null
let interceptorInstalled = false

export function savePatientSession(data) {
  if (!data) return
  const access = data.token || data.accessToken
  const refresh = data.refresh_token || data.refreshToken
  if (access) localStorage.setItem(TOKEN_KEY, access)
  if (refresh) localStorage.setItem(REFRESH_KEY, refresh)
}

export function clearPatientSession() {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(REFRESH_KEY)
}

function isAuthEndpoint(url = '') {
  return (
    url.includes('/api/auth/refresh') ||
    url.includes('/api/auth/logout') ||
    url.includes('/api/user/login') ||
    url.includes('/api/user/register')
  )
}

function usesPatientToken(config) {
  const headers = config?.headers || {}
  const normalized = Object.fromEntries(
    Object.entries(headers).map(([key, value]) => [key.toLowerCase(), value])
  )
  return Boolean(normalized.token)
}

function notifySessionExpired() {
  window.dispatchEvent(new CustomEvent('patient:sessionExpired'))
}

async function refreshPatientToken(backendUrl) {
  const refreshToken = localStorage.getItem(REFRESH_KEY)
  if (!refreshToken) {
    throw new Error('No refresh token')
  }

  let lastError = null
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const { data } = await axios.post(`${backendUrl}/api/auth/refresh`, {
        role: 'patient',
        refresh_token: refreshToken,
      })

      if (!data?.token) {
        throw new Error('Refresh failed')
      }

      savePatientSession(data)
      return data.token
    } catch (err) {
      lastError = err
      const status = err?.response?.status
      // Retry briefly when server is pool-busy (503) or network blip.
      if (status === 503 || !err?.response) {
        await new Promise((r) => setTimeout(r, 300 * (attempt + 1)))
        continue
      }
      throw err
    }
  }
  throw lastError || new Error('Refresh failed')
}

export function setupPatientAuthInterceptor(backendUrl, onTokenRefreshed) {
  if (interceptorInstalled) return
  interceptorInstalled = true

  axios.interceptors.response.use(
    (response) => response,
    async (error) => {
      const config = error.config
      if (!config || config._patientAuthRetry) return Promise.reject(error)
      if (error.response?.status !== 401) return Promise.reject(error)
      if (isAuthEndpoint(config.url)) return Promise.reject(error)
      if (!usesPatientToken(config)) return Promise.reject(error)

      const refreshToken = localStorage.getItem(REFRESH_KEY)
      if (!refreshToken) {
        clearPatientSession()
        notifySessionExpired()
        return Promise.reject(error)
      }

      try {
        if (!refreshPromise) {
          refreshPromise = refreshPatientToken(backendUrl).finally(() => {
            refreshPromise = null
          })
        }
        const newToken = await refreshPromise
        onTokenRefreshed?.(newToken)
        config._patientAuthRetry = true
        config.headers = config.headers || {}
        config.headers.token = newToken
        return axios(config)
      } catch {
        clearPatientSession()
        notifySessionExpired()
        return Promise.reject(error)
      }
    }
  )
}

/** Skip duplicate error toasts after the interceptor clears an expired session. */
export function isPatientAuthFailure(error) {
  return error?.response?.status === 401 && !localStorage.getItem(TOKEN_KEY)
}
