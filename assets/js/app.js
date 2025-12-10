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
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import { MapboxMap } from "./hooks/mapbox_map"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Custom Hooks
const Hooks = {
  Notifications: {
    mounted() {
      this.handleEvent("show_toast", ({ title, message, type }) => {
        console.log("Received show_toast event", { title, message, type });
        this.showToast(title, message, type);
      });
    },
    showToast(title, message, type) {
      const toastContainer = document.getElementById("toast-container") || this.createToastContainer();

      const toast = document.createElement("div");
      toast.className = `alert alert-${type || "info"} shadow-lg mb-2`;
      toast.innerHTML = `
        <div>
          <h3 class="font-bold text-sm">${title}</h3>
          <div class="text-xs">${message}</div>
        </div>
      `;

      toastContainer.appendChild(toast);

      // Remove after 5 seconds
      setTimeout(() => {
        toast.classList.add("opacity-0", "transition-opacity", "duration-500");
        setTimeout(() => toast.remove(), 500);
      }, 5000);
    },
    createToastContainer() {
      const container = document.createElement("div");
      container.id = "toast-container";
      container.className = "toast toast-end toast-bottom z-[1000]";
      document.body.appendChild(container);
      return container;
    }
  },
  CalEmbed: {
    mounted() {
      const username = this.el.dataset.username;
      if (!username) return;

      // Load Cal.com embed script
      if (!window.Cal) {
        const script = document.createElement('script');
        script.src = 'https://app.cal.com/embed/embed.js';
        script.async = true;
        script.onload = () => this.initCal(username);
        document.head.appendChild(script);
      } else {
        this.initCal(username);
      }
    },
    initCal(username) {
      Cal("init", { origin: "https://cal.com" });
      Cal("inline", {
        elementOrSelector: "#cal-embed",
        calLink: username
      });
    }
  },
  MapboxMap: MapboxMap
};

const getThemeColor = (variableName, fallbackVariable) => {
  const styles = getComputedStyle(document.documentElement)
  const fromTheme = styles.getPropertyValue(variableName)?.trim()
  if (fromTheme) return fromTheme

  if (fallbackVariable) {
    const fromFallback = styles.getPropertyValue(fallbackVariable)?.trim()
    if (fromFallback) return fromFallback
  }

  const probe = document.createElement("span")
  probe.className = "text-primary"
  probe.style.position = "absolute"
  probe.style.opacity = "0"
  probe.style.pointerEvents = "none"
  document.body.appendChild(probe)
  const computed = getComputedStyle(probe).color
  probe.remove()
  return computed || "currentColor"
}

const configureTopbar = () => {
  const primary = getThemeColor("--color-primary", "--fallback-p")
  const shadow = getThemeColor("--color-base-content", "--fallback-nc")
  topbar.config({ barColors: { 0: primary }, shadowColor: shadow })
}

configureTopbar()
window.addEventListener("phx:theme-changed", configureTopbar)

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) { window.Alpine.clone(from, to) }
    },
    render(_message, _root, patch) {
      patch()
    }
  }
})

// Show progress bar on live navigation and form submits
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
  window.addEventListener("phx:live_reload:attached", ({ detail: reloader }) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if (keyDown === "c") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if (keyDown === "d") {
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}
