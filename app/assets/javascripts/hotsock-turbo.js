import { HotsockClient } from "@hotsock/hotsock-js"

function createHotsockClient() {
  return new HotsockClient(
    document
      .querySelector('meta[name="hotsock:wss-url"]')
      ?.getAttribute("content"),
    {
      connectTokenFn: async () => {
        const connectTokenPath = document.querySelector(
          'meta[name="hotsock:connect-token-path"]'
        ).content
        const csrfToken = document.querySelector(
          'meta[name="csrf-token"]'
        ).content
        const response = await fetch(connectTokenPath, {
          method: "POST",
          headers: {
            "x-csrf-token": csrfToken,
          },
        })
        const data = await response.json()
        return data.token
      },
      lazyConnection: true,
      logLevel: document.querySelector('meta[name="hotsock:log-level"]')
        ?.content,
    }
  )
}

const hotsockClient = window.Hotsock || createHotsockClient()
window.Hotsock = hotsockClient

// Track active subscriptions by channel
const subscriptions = new Map() // channel -> { binding, elements: Set, unsubscribeTimer }
const UNSUBSCRIBE_DELAY_MS = 250

class HotsockTurboStreamSourceElement extends HTMLElement {
  #channel = null

  connectedCallback() {
    this.#subscribe()
  }

  disconnectedCallback() {
    this.#unsubscribe()
  }

  #subscribe() {
    const { channel, token } = this.dataset

    if (!channel || !token) {
      return
    }

    this.#channel = channel

    if (typeof window === "undefined" || !window.Turbo) {
      console.warn("hotsock-turbo-stream-source: Turbo is not available")
      return
    }

    let sub = subscriptions.get(channel)

    if (sub) {
      // Cancel unsubscribe if pending
      if (sub.unsubscribeTimer) {
        clearTimeout(sub.unsubscribeTimer)
        sub.unsubscribeTimer = null
      }
      // Add this element to the subscription's element set
      sub.elements.add(this)
    } else {
      const { Turbo } = window
      const binding = hotsockClient.bind(
        "turbo_stream",
        ({ data }) => {
          if (!data?.html) return
          try {
            Turbo.renderStreamMessage(data.html)
          } catch (error) {
            console.error("Failed to render Turbo Stream message:", error)
          }
        },
        { channel, subscribeTokenFn: () => token }
      )

      sub = { binding, elements: new Set([this]), unsubscribeTimer: null }
      subscriptions.set(channel, sub)
    }

    this.subscriptionConnected()
  }

  #unsubscribe() {
    const channel = this.#channel
    if (!channel) {
      return
    }

    const sub = subscriptions.get(channel)
    if (!sub) {
      this.subscriptionDisconnected()
      return
    }

    // Remove this element from the subscription
    sub.elements.delete(this)

    // If no elements remain, schedule delayed unsubscribe
    if (sub.elements.size === 0 && !sub.unsubscribeTimer) {
      sub.unsubscribeTimer = setTimeout(() => {
        // Double-check no elements have reconnected
        if (sub.elements.size === 0) {
          sub.binding.unbind()
          subscriptions.delete(channel)
        }
      }, UNSUBSCRIBE_DELAY_MS)
    }

    this.subscriptionDisconnected()
    this.#channel = null
  }

  subscriptionConnected() {
    this.setAttribute("connected", "")
  }

  subscriptionDisconnected() {
    this.removeAttribute("connected")
  }
}

if (customElements.get("hotsock-turbo-stream-source") === undefined) {
  customElements.define(
    "hotsock-turbo-stream-source",
    HotsockTurboStreamSourceElement
  )
}

export { hotsockClient }
