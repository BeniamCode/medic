import React, { useEffect, useRef, useMemo } from 'react'
import maplibregl from 'maplibre-gl'
import i18next from 'i18next'

interface MapDoctor {
    id: string
    firstName: string
    lastName: string
    specialtyName: string | null
    address: string | null
    locationLat: number | null
    locationLng: number | null
}

interface MapProps {
    doctors: MapDoctor[]
    height?: number | string
    expanded?: boolean
    focusedDoctorId?: string | null
}

// Free vector tile style from OpenFreeMap (Positron-like light theme)
const MAP_STYLE = 'https://tiles.openfreemap.org/styles/positron'

export default function DoctorMap({
    doctors,
    height = '100%',
    expanded = false,
    focusedDoctorId = null
}: MapProps) {
    const mapContainer = useRef<HTMLDivElement>(null)
    const map = useRef<maplibregl.Map | null>(null)
    const markers = useRef<{ [key: string]: maplibregl.Marker }>({})

    const validDoctors = useMemo(
        () => doctors.filter(d => d.locationLat && d.locationLng),
        [doctors]
    )

    // Lazy load CSS to avoid blocking initial page load
    useEffect(() => {
        const href = 'https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css'
        if (!document.querySelector(`link[href="${href}"]`)) {
            const link = document.createElement('link')
            link.rel = 'stylesheet'
            link.href = href
            document.head.appendChild(link)
        }
    }, [])

    // Initialize Map
    useEffect(() => {
        if (map.current || !mapContainer.current) return

        map.current = new maplibregl.Map({
            container: mapContainer.current,
            style: MAP_STYLE,
            center: [23.7275, 37.9838], // Athens (lng, lat for MapLibre)
            zoom: 10,
            attributionControl: false
        })

        map.current.addControl(new maplibregl.NavigationControl(), 'top-right')
        map.current.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right')

        return () => {
            if (map.current) {
                map.current.remove()
                map.current = null
            }
        }
    }, [])

    // Update Markers when doctors change
    useEffect(() => {
        if (!map.current) return

        // Clear existing markers
        Object.values(markers.current).forEach(marker => marker.remove())
        markers.current = {}

        if (validDoctors.length === 0) return

        const bounds = new maplibregl.LngLatBounds()

        validDoctors.forEach(doctor => {
            const lat = doctor.locationLat!
            const lng = doctor.locationLng!

            // Create Popup with Button
            const popupHTML = `
                <div style="font-family: Inter, sans-serif; min-width: 180px;">
                    <strong style="color: #111; font-size: 14px; display: block; margin-bottom: 2px;">${doctor.firstName} ${doctor.lastName}</strong>
                    <span style="color: #0D9488; font-size: 12px; font-weight: 600;">${doctor.specialtyName || ''}</span>
                    <div style="color: #666; font-size: 12px; margin-top: 4px; line-height: 1.4;">${doctor.address || ''}</div>
                    <a href="/doctors/${doctor.id}" 
                       style="display: block; margin-top: 8px; text-align: center; background: #14B8A6; color: white; padding: 6px 12px; border-radius: 4px; text-decoration: none; font-size: 12px; font-weight: 500;">
                       View Profile
                    </a>
                </div>
            `

            const popup = new maplibregl.Popup({ offset: 25, closeButton: false })
                .setHTML(popupHTML)

            const marker = new maplibregl.Marker({ color: '#14B8A6' })
                .setLngLat([lng, lat])
                .setPopup(popup)
                .addTo(map.current!)

            markers.current[doctor.id] = marker
            bounds.extend([lng, lat])
        })

        // Fit bounds if we have markers
        if (Object.keys(markers.current).length > 0) {
            map.current.fitBounds(bounds, {
                padding: 50,
                maxZoom: 15,
                duration: 1000 // Smooth animation
            })
        }
    }, [validDoctors])

    // Handle Focused Doctor (FlyTo with smooth animation)
    useEffect(() => {
        if (!map.current || !focusedDoctorId) return

        const doctor = doctors.find(d => d.id === focusedDoctorId)
        if (doctor?.locationLat && doctor?.locationLng) {
            // Smooth fly to location
            map.current.flyTo({
                center: [doctor.locationLng, doctor.locationLat],
                zoom: 15,
                duration: 1500,
                essential: true
            })

            // Open popup if marker exists
            const marker = markers.current[focusedDoctorId]
            if (marker) {
                marker.togglePopup()
            }
        }
    }, [focusedDoctorId, doctors])

    // Handle resize when container changes
    useEffect(() => {
        if (!map.current) return
        setTimeout(() => map.current?.resize(), 100)
    }, [expanded, height])

    return (
        <div
            ref={mapContainer}
            style={{ height, width: '100%', borderRadius: 16 }}
        />
    )
}
