import React, { useEffect, useRef } from 'react'
import mapboxgl from 'mapbox-gl'
import 'mapbox-gl/dist/mapbox-gl.css'
import { Box } from '@mantine/core'
// Define local interface to avoid circular imports
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
}

export default function DoctorMap({ doctors, height = '100%', expanded = false }: MapProps) {
    const mapContainer = useRef<HTMLDivElement>(null)
    const map = useRef<mapboxgl.Map | null>(null)
    const markers = useRef<mapboxgl.Marker[]>([])

    // Initialize Map
    // Debug removed for brevity, trust logic now.

    useEffect(() => {
        if (map.current || !mapContainer.current) return

        mapboxgl.accessToken = 'pk.eyJ1IjoibWVkaWNnciIsImEiOiJjbWl6bnpubDcwMTk2M2VzaWZlNDlkeDh1In0.DFR6nJ1SOlC2HE5jSKaAHg'

        map.current = new mapboxgl.Map({
            container: mapContainer.current,
            style: 'mapbox://styles/mapbox/light-v11',
            center: [23.7275, 37.9838], // Default to Athens
            zoom: 10,
            attributionControl: false
            // Padding set via effect below to avoid TS error
        })

        map.current.addControl(new mapboxgl.NavigationControl(), 'top-right')
    }, [])

    // Handle Expansion Animation (Padding Shift)
    useEffect(() => {
        if (!map.current) return

        map.current.easeTo({
            padding: { bottom: expanded ? 0 : 250 },
            duration: 300 // Match CSS transition
        })
    }, [expanded])

    // Update Markers when doctors change
    useEffect(() => {
        if (!map.current) return

        // Clear existing markers
        markers.current.forEach(marker => marker.remove())
        markers.current = []

        if (doctors.length === 0) return

        const bounds = new mapboxgl.LngLatBounds()

        doctors.forEach(doctor => {
            const lat = doctor.locationLat
            const lng = doctor.locationLng

            if (lat && lng) {
                const el = document.createElement('div')
                el.className = 'marker'
                el.style.backgroundColor = '#14B8A6'
                el.style.width = '24px'
                el.style.height = '24px'
                el.style.borderRadius = '50%'
                el.style.border = '2px solid white'
                el.style.boxShadow = '0 2px 4px rgba(0,0,0,0.3)'
                el.style.cursor = 'pointer'

                const marker = new mapboxgl.Marker({ element: el })
                    .setLngLat([lng, lat])
                    .setPopup(
                        new mapboxgl.Popup({ offset: 25 })
                            .setHTML(
                                `<div style="font-family: Inter, sans-serif;">
                  <strong style="color: #111;">${doctor.firstName} ${doctor.lastName}</strong><br/>
                  <span style="color: #666; font-size: 13px;">${doctor.specialtyName || ''}</span><br/>
                  <span style="color: #888; font-size: 12px; margin-top: 4px; display: block;">${doctor.address || ''}</span>
                 </div>`
                            )
                    )
                    .addTo(map.current!)

                markers.current.push(marker)
                bounds.extend([lng, lat])
            }
        })

        // Fit bounds if we have markers
        if (markers.current.length > 0) {
            map.current.fitBounds(bounds, {
                padding: { top: 50, bottom: expanded ? 50 : 300, left: 50, right: 50 }, // Add extra bottom padding if collapsed
                maxZoom: 15
            })
        }
    }, [doctors, expanded]) // Re-fit if expansion allows more room? Maybe better to just let easeTo handle view.
    // Actually, fitBounds respects the CURRENT padding of the map instance automatically.
    // Converting this effect to just run on [doctors] is safer to avoid re-fitting on hover.
    // But wait, if padding changes, the center changes automatically via easeTo.
    // We don't need to call fitBounds again on expansion.

    // Resize map when container height changes
    useEffect(() => {
        if (!map.current) return
        map.current.resize()
    }, [height])

    return (
        <Box ref={mapContainer} h={height} w="100%" style={{ borderRadius: 0 }} />
    )
}
