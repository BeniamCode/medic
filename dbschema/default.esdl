module default {
    type Profile {
        required property name -> str;
        required property street_address -> str;
        property district -> str;
        required property postal_code -> str;
        required property address_locality -> str;
        required property region -> str;
        property phone -> str;
        property mobile -> str;
        property website -> str;
        property email -> str;
    }
}
