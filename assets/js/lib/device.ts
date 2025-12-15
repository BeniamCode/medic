import { useMediaQuery } from '@mantine/hooks'

/**
 * Hook to detect if the current device is mobile
 * Uses CSS media query for responsive detection
 */
export function useIsMobile(breakpoint = 768): boolean {
    const matches = useMediaQuery(`(max-width: ${breakpoint}px)`)
    return matches ?? false
}

/**
 * Detect if we're running in a Capacitor native app
 */
export function isCapacitorApp(): boolean {
    return typeof window !== 'undefined' &&
        window.Capacitor !== undefined &&
        window.Capacitor.isNativePlatform?.() === true
}

/**
 * Get the current platform
 */
export function getPlatform(): 'ios' | 'android' | 'web' {
    if (typeof window === 'undefined') return 'web'

    if (window.Capacitor?.getPlatform) {
        const platform = window.Capacitor.getPlatform()
        if (platform === 'ios' || platform === 'android') return platform
    }

    return 'web'
}

// Type declaration for Capacitor global
declare global {
    interface Window {
        Capacitor?: {
            isNativePlatform?: () => boolean
            getPlatform?: () => string
        }
    }
}
