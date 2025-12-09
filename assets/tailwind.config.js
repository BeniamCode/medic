// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
    content: [
        "./js/**/*.js",
        "../lib/medic_web.ex",
        "../lib/medic_web/**/*.*ex"
    ],
    theme: {
        extend: {},
    },
    plugins: [
        require("@tailwindcss/forms"),
        require("daisyui"),
        // Allows prefixing tailwind classes with LiveView classes to add rules
        // only when LiveView classes are applied, for example:
        //
        //     <div class="phx-click-loading:animate-ping">
        //
        plugin(({ addVariant }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
        plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
        plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
        plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

        // Embeds Heroicons (https://heroicons.com) into your app.css bundle
        // See your `CoreComponents.icon/1` for more information.
        //
        plugin(function ({ matchComponents, theme }) {
            let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
            let values = {}
            let icons = [
                ["", "/24/outline"],
                ["-solid", "/24/solid"],
                ["-mini", "/20/solid"],
                ["-micro", "/16/solid"]
            ]
            icons.forEach(([suffix, dir]) => {
                fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
                    let name = path.basename(file, ".svg") + suffix
                    values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
                })
            })
            matchComponents({
                "hero": ({ name, fullPath }) => {
                    let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
                    let size = theme("spacing.6")
                    if (name.endsWith("-mini")) {
                        size = theme("spacing.5")
                    } else if (name.endsWith("-micro")) {
                        size = theme("spacing.4")
                    }
                    return {
                        [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
                        "-webkit-mask": `var(--hero-${name})`,
                        "mask": `var(--hero-${name})`,
                        "mask-repeat": "no-repeat",
                        "background-color": "currentColor",
                        "vertical-align": "middle",
                        "display": "inline-block",
                        "width": size,
                        "height": size
                    }
                }
            }, { values })
        })
    ],
    daisyui: {
        themes: [
            {
                medic: {
                    "base-100": "oklch(100% 0 0)",
                    "base-200": "oklch(93% 0 0)",
                    "base-300": "oklch(86% 0 0)",
                    "base-content": "oklch(22.389% 0.031 278.072)",
                    "primary": "oklch(76% 0.177 163.223)",
                    "primary-content": "oklch(100% 0 0)",
                    "secondary": "oklch(55% 0.046 257.417)",
                    "secondary-content": "oklch(100% 0 0)",
                    "accent": "oklch(60% 0.118 184.704)",
                    "accent-content": "oklch(100% 0 0)",
                    "neutral": "oklch(0% 0 0)",
                    "neutral-content": "oklch(100% 0 0)",
                    "info": "oklch(70% 0.14 182.503)",
                    "info-content": "oklch(100% 0 0)",
                    "success": "oklch(62% 0.194 149.214)",
                    "success-content": "oklch(100% 0 0)",
                    "warning": "oklch(85% 0.199 91.936)",
                    "warning-content": "oklch(0% 0 0)",
                    "error": "oklch(70% 0.191 22.216)",
                    "error-content": "oklch(0% 0 0)",
                    "--radius-selector": "0.25rem",
                    "--radius-field": "0.5rem",
                    "--radius-box": "1rem",
                    "--size-selector": "0.25rem",
                    "--size-field": "0.25rem",
                    "--border": "1px",
                    "--depth": "1",
                    "--noise": "1",
                },
            },
        ],
    },
}
