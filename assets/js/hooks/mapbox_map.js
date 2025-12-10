export const MapboxMap = {
    mounted() {
        this.initMap();
    },
    updated() {
        this.updateMarkers();
    },
    destroyed() {
        if (this.map) this.map.remove();
    },
    initMap() {
        mapboxgl.accessToken = 'pk.eyJ1IjoibWVkaWNnciIsImEiOiJjbWl6bnpubDcwMTk2M2VzaWZlNDlkeDh1In0.DFR6nJ1SOlC2HE5jSKaAHg';

        // Default center (Athens, Greece) if no doctors or specific center provided
        const defaultCenter = [23.7275, 37.9838];
        const defaultZoom = 11;

        this.map = new mapboxgl.Map({
            container: this.el,
            style: 'mapbox://styles/mapbox/streets-v12',
            center: defaultCenter,
            zoom: defaultZoom
        });

        this.map.on('load', () => {
            this.updateMarkers();
        });

        this.markers = [];
    },

    updateMarkers() {
        if (!this.map || !this.map.loaded()) return;

        // Clear existing markers
        this.markers.forEach(marker => marker.remove());
        this.markers = [];

        const doctors = JSON.parse(this.el.dataset.doctors || "[]");

        if (doctors.length === 0) return;

        const bounds = new mapboxgl.LngLatBounds();

        doctors.forEach(doctor => {
            if (doctor.location_lng && doctor.location_lat) {
                // Create popup content
                const popupContent = `
          <div class="p-2">
            <h3 class="font-bold text-sm">${doctor.first_name} ${doctor.last_name}</h3>
            <p class="text-xs text-gray-500">${doctor.specialty_name || ''}</p>
            <div class="mt-2">
              <span class="font-semibold text-primary">€${parseInt(doctor.consultation_fee || 0)}</span>
            </div>
          </div>
        `;

                const popup = new mapboxgl.Popup({ offset: 25 })
                    .setHTML(popupContent);

                const marker = new mapboxgl.Marker({ color: '#E1004C' }) // Medic primary color roughly
                    .setLngLat([doctor.location_lng, doctor.location_lat])
                    .setPopup(popup)
                    .addTo(this.map);

                this.markers.push(marker);
                bounds.extend([doctor.location_lng, doctor.location_lat]);
            }
        });

        // Fit map to bounds if we have markers
        if (this.markers.length > 0) {
            this.map.fitBounds(bounds, {
                padding: 50,
                maxZoom: 15
            });
        }
    }
};
