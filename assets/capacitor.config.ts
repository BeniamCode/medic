import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
    appId: 'com.medic.app',
    appName: 'Medic',
    webDir: 'www',
    server: {
        // For development: connect to local Phoenix server
        // Comment this out for production builds
        url: 'http://localhost:4000',
        cleartext: true
    },
    ios: {
        contentInset: 'automatic',
        allowsLinkPreview: false
    }
};

export default config;
