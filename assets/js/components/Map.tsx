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
    focusedDoctorId?: string | null
}

export default function DoctorMap({ doctors, height = '100%', expanded = false, focusedDoctorId = null }: MapProps) {
    const mapContainer = useRef<HTMLDivElement>(null)
    const map = useRef<mapboxgl.Map | null>(null)
    const markers = useRef<{ [key: string]: mapboxgl.Marker }>({})

    // Initialize Map
    useEffect(() => {
        if (map.current || !mapContainer.current) return

        mapboxgl.accessToken = 'pk.eyJ1IjoibWVkaWNnciIsImEiOiJjbWl6bnpubDcwMTk2M2VzaWZlNDlkeDh1In0.DFR6nJ1SOlC2HE5jSKaAHg'

        map.current = new mapboxgl.Map({
            container: mapContainer.current,
            style: 'mapbox://styles/mapbox/light-v11',
            center: [23.7275, 37.9838], // Default to Athens
            zoom: 10,
            attributionControl: false
        })

        map.current.addControl(new mapboxgl.NavigationControl(), 'top-right')
    }, [])

    // Handle Expansion Animation (Padding Shift)
    useEffect(() => {
        if (!map.current) return

        map.current.easeTo({
            padding: { bottom: expanded ? 0 : 250 },
            duration: 300
        })
    }, [expanded])

    // Update Markers when doctors change
    useEffect(() => {
        if (!map.current) return

        // Clear existing markers
        Object.values(markers.current).forEach(marker => marker.remove())
        markers.current = {}

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

                // Create Popup with Button
                const popupHTML = `
                    <div style="font-family: Inter, sans-serif; min-width: 180px;">
                        <strong style="color: #111; font-size: 14px; display: block; margin-bottom: 2px;">${doctor.firstName} ${doctor.lastName}</strong>
                        <span style="color: #0D9488; font-size: 12px; font-weight: 600;">${doctor.specialtyName || ''}</span>
                        <div style="color: #666; font-size: 12px; margin-top: 4px; line-height: 1.4;">${doctor.address || ''}</div>
                        <a href="/doctors/${doctor.id}" 
                           style="display: block; margin-top: 8px; text-align: center; background: #14B8A6; color: white; padding: 6px 12px; border-radius: 4px; text-decoration: none; font-size: 12px; font-weight: 500;">
                           Book Appointment
                        </a>
                    </div>
                `

                const marker = new mapboxgl.Marker({ element: el })
                    .setLngLat([lng, lat])
                    .setPopup(new mapboxgl.Popup({ offset: 25, closeButton: false }).setHTML(popupHTML))
                    .addTo(map.current!)

                markers.current[doctor.id] = marker
                bounds.extend([lng, lat])
            }
        })

        // Fit bounds if we have markers
        if (Object.keys(markers.current).length > 0) {
            map.current.fitBounds(bounds, {
                padding: { top: 50, bottom: expanded ? 50 : 300, left: 50, right: 50 },
                maxZoom: 15,
                duration: 1000
            })
        }
    }, [doctors]) // Removed 'expanded' from deps to avoid re-fit on hover

    // Handle Focused Doctor (FlyTo)
    useEffect(() => {
        if (!map.current || !focusedDoctorId) return

        const doctor = doctors.find(d => d.id === focusedDoctorId)
        if (doctor && doctor.locationLat && doctor.locationLng) {
            // Fly to location
            map.current.flyTo({
                center: [doctor.locationLng, doctor.locationLat],
                zoom: 15,
                essential: true,
                padding: { bottom: expanded ? 0 : 250 }, // Maintain padding awareness
            })

            // Open popup if marker exists
            const marker = markers.current[focusedDoctorId]
            if (marker) {
                marker.togglePopup()
            }
        }
    }, [focusedDoctorId, doctors, expanded])


    // Resize map when container height changes
    useEffect(() => {
        if (!map.current) return
        map.current.resize()
    }, [height])

    return (
        <Box ref={mapContainer} h={height} w="100%" style={{ borderRadius: 0 }} />
    )
}
