import maplibregl from 'maplibre-gl'
// CSS loaded via CDN in root.html.heex

// Free vector tile style from OpenFreeMap (Positron-like light theme)
const MAP_STYLE = 'https://tiles.openfreemap.org/styles/positron'

export const LeafletMap = {
    mounted() {
        this.initMap()
    },
    updated() {
        this.updateMarkers()
    },
    destroyed() {
        if (this.map) {
            this.map.remove()
            this.map = null
        }
    },
    initMap() {
        // Default center (Athens, Greece)
        const defaultCenter = [23.7275, 37.9838] // lng, lat for MapLibre
        const defaultZoom = 11

        this.map = new maplibregl.Map({
            container: this.el,
            style: MAP_STYLE,
            center: defaultCenter,
            zoom: defaultZoom,
            attributionControl: false
        })

        this.map.addControl(new maplibregl.NavigationControl(), 'top-right')
        this.map.addControl(new maplibregl.AttributionControl({ compact: true }), 'bottom-right')

        this.markers = []

        // Wait for map to be ready then update markers
        this.map.on('load', () => {
            this.updateMarkers()
        })
    },

    updateMarkers() {
        if (!this.map || !this.map.loaded()) return

        // Clear existing markers
        this.markers.forEach(marker => marker.remove())
        this.markers = []

        const doctors = JSON.parse(this.el.dataset.doctors || "[]")

        if (doctors.length === 0) return

        const validDoctors = doctors.filter(d => d.location_lng && d.location_lat)
        if (validDoctors.length === 0) return

        const bounds = new maplibregl.LngLatBounds()

        validDoctors.forEach(doctor => {
            // Create popup content
            const popupContent = `
                <div class="p-2">
                    <h3 class="font-bold text-sm">${doctor.first_name} ${doctor.last_name}</h3>
                    <p class="text-xs text-gray-500">${doctor.specialty_name || ''}</p>
                    <div class="mt-2">
                        <span class="font-semibold text-primary">€${parseInt(doctor.consultation_fee || 0)}</span>
                    </div>
                </div>
            `

            const popup = new maplibregl.Popup({ offset: 25 })
                .setHTML(popupContent)

            const marker = new maplibregl.Marker({ color: '#E1004C' })
                .setLngLat([doctor.location_lng, doctor.location_lat])
                .setPopup(popup)
                .addTo(this.map)

            this.markers.push(marker)
            bounds.extend([doctor.location_lng, doctor.location_lat])
        })

        // Fit map to bounds with smooth animation
        if (this.markers.length > 0) {
            this.map.fitBounds(bounds, {
                padding: 50,
                maxZoom: 15,
                duration: 1000
            })
        }
    }
}

// Keep backward compatibility - export as both names
export const MapboxMap = LeafletMap
