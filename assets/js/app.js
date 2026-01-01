// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/jamiec"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// TOC scroll sync hook - highlights current section, scrolls TOC, and fixes TOC on scroll
const TocScrollSync = {
  mounted() {
    this.setupTocFixing()
    this.observeHeadings()
  },

  setupTocFixing() {
    const tocNav = this.el.querySelector('[data-toc-nav]')
    if (!tocNav) return

    // Create a sentinel element to detect when TOC should become fixed
    this.sentinel = document.createElement('div')
    this.sentinel.style.height = '1px'
    this.sentinel.style.width = '100%'
    tocNav.parentNode.insertBefore(this.sentinel, tocNav)

    // Store original position info
    this.tocNav = tocNav
    this.isFixed = false
    this.isAbsolute = false
    this.isPastFooter = false

    // Use IntersectionObserver to detect when sentinel leaves viewport
    this.fixObserver = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (!entry.isIntersecting && entry.boundingClientRect.top < 0) {
          // Sentinel scrolled above viewport - fix the TOC (if not past footer)
          if (!this.isPastFooter) {
            this.fixToc()
          }
        } else if (entry.isIntersecting) {
          // Sentinel visible - unfix the TOC
          this.unfixToc()
        }
      })
    }, { threshold: 0 })

    this.fixObserver.observe(this.sentinel)

    // Observe footer to unfix TOC before overlap
    const footer = document.querySelector('footer')
    if (footer) {
      this.footerObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
          if (entry.isIntersecting) {
            // Footer is visible - anchor TOC to bottom of container for smooth scroll-away
            this.isPastFooter = true
            this.absoluteToc()
          } else {
            this.isPastFooter = false
            // Re-fix if sentinel is above viewport
            const sentinelRect = this.sentinel.getBoundingClientRect()
            if (sentinelRect.top < 0) {
              this.fixToc()
            }
          }
        })
      }, { threshold: 0, rootMargin: '0px 0px 0px 0px' })

      this.footerObserver.observe(footer)
    }
  },

  fixToc() {
    if (this.isFixed || this.isPastFooter) return
    this.isFixed = true
    this.isAbsolute = false
    this.tocNav.classList.remove('relative', 'absolute', 'bottom-0')
    this.tocNav.classList.add('fixed', 'top-8')
    // Clear any inline styles from absoluteToc()
    this.tocNav.style.top = ''
    this.tocNav.style.bottom = ''
  },

  unfixToc() {
    if (!this.isFixed && !this.isAbsolute) return
    this.isFixed = false
    this.isAbsolute = false
    this.tocNav.classList.remove('fixed', 'top-8', 'absolute', 'bottom-0')
    this.tocNav.classList.add('relative')
    // Clear any inline styles from absoluteToc()
    this.tocNav.style.top = ''
    this.tocNav.style.bottom = ''
  },

  absoluteToc() {
    if (this.isAbsolute) return

    // Calculate current position relative to container to avoid jump
    const tocRect = this.tocNav.getBoundingClientRect()
    const containerRect = this.tocNav.parentElement.getBoundingClientRect()
    const topOffset = tocRect.top - containerRect.top

    this.isFixed = false
    this.isAbsolute = true
    this.tocNav.classList.remove('fixed', 'top-8', 'relative')
    this.tocNav.classList.add('absolute')
    this.tocNav.style.top = `${topOffset}px`
    this.tocNav.style.bottom = 'auto'
  },

  observeHeadings() {
    const contentEl = this.el.querySelector('[data-toc-content]')
    const tocNav = this.el.querySelector('[data-toc-nav]')

    if (!contentEl || !tocNav) return

    const headings = contentEl.querySelectorAll('h2, h3, h4, h5, h6')
    if (headings.length === 0) return

    // Track which heading is currently active
    let activeId = null

    const observer = new IntersectionObserver((entries) => {
      // Find the topmost visible heading
      const visibleEntries = entries.filter(e => e.isIntersecting)

      if (visibleEntries.length > 0) {
        // Sort by position and take the topmost
        visibleEntries.sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)
        const topEntry = visibleEntries[0]
        const id = topEntry.target.querySelector('a[id]')?.id ||
                   topEntry.target.id ||
                   this.slugify(topEntry.target.textContent)

        if (id !== activeId) {
          activeId = id
          this.highlightTocItem(tocNav, id)
        }
      }
    }, {
      rootMargin: '-10% 0px -70% 0px',
      threshold: 0
    })

    headings.forEach(heading => observer.observe(heading))
    this.observer = observer
  },

  highlightTocItem(tocNav, id) {
    // Remove all active states
    tocNav.querySelectorAll('a').forEach(link => {
      link.classList.remove('font-bold', 'opacity-100')
      link.classList.add('opacity-70')
    })

    // Add active state to matching link
    const activeLink = tocNav.querySelector(`a[href="#${id}"]`)
    if (activeLink) {
      activeLink.classList.remove('opacity-70')
      activeLink.classList.add('font-bold', 'opacity-100')
    }
  },

  slugify(text) {
    return text.toLowerCase()
      .replace(/[^a-z0-9\s-]/g, '')
      .replace(/\s+/g, '-')
      .trim('-')
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect()
    }
    if (this.fixObserver) {
      this.fixObserver.disconnect()
    }
    if (this.footerObserver) {
      this.footerObserver.disconnect()
    }
    if (this.sentinel) {
      this.sentinel.remove()
    }
  }
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, TocScrollSync},
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

