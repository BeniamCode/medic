CREATE MIGRATION m1ru7o2fsxjj6ozkjvekrrlikckgtfar7zpxahee3cfyg6thvqmcyq
    ONTO initial
{
  CREATE TYPE default::Profile {
      CREATE REQUIRED PROPERTY address_locality: std::str;
      CREATE PROPERTY district: std::str;
      CREATE PROPERTY email: std::str;
      CREATE PROPERTY mobile: std::str;
      CREATE REQUIRED PROPERTY name: std::str;
      CREATE PROPERTY phone: std::str;
      CREATE REQUIRED PROPERTY postal_code: std::str;
      CREATE REQUIRED PROPERTY region: std::str;
      CREATE REQUIRED PROPERTY street_address: std::str;
      CREATE PROPERTY website: std::str;
  };
};
