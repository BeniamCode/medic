defmodule Medic.MedicalTaxonomy do
  @moduledoc """
  Comprehensive medical specialty and organ taxonomy for intelligent search.

  This module provides:
  - Complete list of medical specialties (65+)
  - Complete list of body organs/parts (75+)
  - Specialty-to-organ mappings for body-part search
  - Organ-to-specialty lookup for "heart" → Cardiology

  Usage:
      MedicalTaxonomy.specialties()
      MedicalTaxonomy.organs()
      MedicalTaxonomy.specialties_for_organ("heart")
      MedicalTaxonomy.organs_for_specialty("Cardiology")
  """

  @specialties [
    %{
      id: "allergy-immunology",
      name: "Allergy & Immunology",
      name_el: "Αλλεργιολογία & Ανοσολογία",
      icon: "hero-shield-exclamation",
      description: "Diagnosis and treatment of allergies and immune system disorders"
    },
    %{
      id: "anesthesiology",
      name: "Anesthesiology",
      name_el: "Αναισθησιολογία",
      icon: "hero-beaker",
      description: "Anesthesia and pain management for surgery"
    },
    %{
      id: "andrology",
      name: "Andrology",
      name_el: "Ανδρολογία",
      icon: "hero-user",
      description: "Male reproductive health and fertility"
    },
    %{
      id: "audiology",
      name: "Audiology",
      name_el: "Ακοολογία",
      icon: "hero-speaker-wave",
      description: "Hearing and balance disorders"
    },
    %{
      id: "bariatric-surgery",
      name: "Bariatric Surgery",
      name_el: "Βαριατρική Χειρουργική",
      icon: "hero-scissors",
      description: "Weight loss surgery"
    },
    %{
      id: "cardiology",
      name: "Cardiology",
      name_el: "Καρδιολογία",
      icon: "hero-heart",
      description: "Heart and cardiovascular system"
    },
    %{
      id: "cardiac-surgery",
      name: "Cardiac Surgery",
      name_el: "Καρδιοχειρουργική",
      icon: "hero-heart",
      description: "Surgical treatment of heart conditions"
    },
    %{
      id: "cardiothoracic-surgery",
      name: "Cardiothoracic Surgery",
      name_el: "Καρδιοθωρακική Χειρουργική",
      icon: "hero-heart",
      description: "Surgery of heart and chest organs"
    },
    %{
      id: "colorectal-surgery",
      name: "Colorectal Surgery",
      name_el: "Χειρουργική Παχέος Εντέρου",
      icon: "hero-scissors",
      description: "Surgery of colon, rectum, and anus"
    },
    %{
      id: "critical-care",
      name: "Critical Care Medicine",
      name_el: "Εντατική Θεραπεία",
      icon: "hero-exclamation-triangle",
      description: "Care for critically ill patients"
    },
    %{
      id: "dentistry",
      name: "Dentistry",
      name_el: "Οδοντιατρική",
      icon: "hero-face-smile",
      description: "Teeth and oral health"
    },
    %{
      id: "dermatology",
      name: "Dermatology",
      name_el: "Δερματολογία",
      icon: "hero-hand-raised",
      description: "Skin, hair, and nail conditions"
    },
    %{
      id: "diabetology",
      name: "Diabetology",
      name_el: "Διαβητολογία",
      icon: "hero-beaker",
      description: "Diabetes management"
    },
    %{
      id: "emergency-medicine",
      name: "Emergency Medicine",
      name_el: "Επείγουσα Ιατρική",
      icon: "hero-bolt",
      description: "Acute injuries and emergency conditions"
    },
    %{
      id: "endocrinology",
      name: "Endocrinology",
      name_el: "Ενδοκρινολογία",
      icon: "hero-beaker",
      description: "Hormones and metabolic disorders"
    },
    %{
      id: "ent",
      name: "ENT (Otolaryngology)",
      name_el: "Ωτορινολαρυγγολογία",
      icon: "hero-speaker-wave",
      description: "Ears, nose, and throat"
    },
    %{
      id: "family-medicine",
      name: "Family Medicine",
      name_el: "Οικογενειακή Ιατρική",
      icon: "hero-home",
      description: "Comprehensive family healthcare"
    },
    %{
      id: "gastroenterology",
      name: "Gastroenterology",
      name_el: "Γαστρεντερολογία",
      icon: "hero-beaker",
      description: "Digestive system disorders"
    },
    %{
      id: "general-practice",
      name: "General Practice",
      name_el: "Γενική Ιατρική",
      icon: "hero-home",
      description: "Primary care and general health"
    },
    %{
      id: "general-surgery",
      name: "General Surgery",
      name_el: "Γενική Χειρουργική",
      icon: "hero-scissors",
      description: "General surgical procedures"
    },
    %{
      id: "geriatrics",
      name: "Geriatrics",
      name_el: "Γηριατρική",
      icon: "hero-user",
      description: "Healthcare for elderly patients"
    },
    %{
      id: "gynecology",
      name: "Gynecology",
      name_el: "Γυναικολογία",
      icon: "hero-heart",
      description: "Female reproductive health"
    },
    %{
      id: "gynecologic-oncology",
      name: "Gynecologic Oncology",
      name_el: "Γυναικολογική Ογκολογία",
      icon: "hero-shield-check",
      description: "Cancers of female reproductive system"
    },
    %{
      id: "hand-surgery",
      name: "Hand Surgery",
      name_el: "Χειρουργική Χεριού",
      icon: "hero-hand-raised",
      description: "Surgery of the hand and wrist"
    },
    %{
      id: "hematology",
      name: "Hematology",
      name_el: "Αιματολογία",
      icon: "hero-beaker",
      description: "Blood disorders"
    },
    %{
      id: "hepatology",
      name: "Hepatology",
      name_el: "Ηπατολογία",
      icon: "hero-beaker",
      description: "Liver diseases"
    },
    %{
      id: "infectious-diseases",
      name: "Infectious Diseases",
      name_el: "Λοιμώδη Νοσήματα",
      icon: "hero-bug-ant",
      description: "Infections and contagious diseases"
    },
    %{
      id: "internal-medicine",
      name: "Internal Medicine",
      name_el: "Παθολογία",
      icon: "hero-clipboard-document-list",
      description: "Internal organ diseases"
    },
    %{
      id: "interventional-cardiology",
      name: "Interventional Cardiology",
      name_el: "Επεμβατική Καρδιολογία",
      icon: "hero-heart",
      description: "Catheter-based heart treatments"
    },
    %{
      id: "interventional-radiology",
      name: "Interventional Radiology",
      name_el: "Επεμβατική Ακτινολογία",
      icon: "hero-photo",
      description: "Image-guided procedures"
    },
    %{
      id: "neonatology",
      name: "Neonatology",
      name_el: "Νεογνολογία",
      icon: "hero-face-smile",
      description: "Care for newborn infants"
    },
    %{
      id: "nephrology",
      name: "Nephrology",
      name_el: "Νεφρολογία",
      icon: "hero-beaker",
      description: "Kidney diseases"
    },
    %{
      id: "neuropsychiatry",
      name: "Neuropsychiatry",
      name_el: "Νευροψυχιατρική",
      icon: "hero-academic-cap",
      description: "Mental disorders with neurological basis"
    },
    %{
      id: "neurology",
      name: "Neurology",
      name_el: "Νευρολογία",
      icon: "hero-academic-cap",
      description: "Brain and nervous system disorders"
    },
    %{
      id: "neurosurgery",
      name: "Neurosurgery",
      name_el: "Νευροχειρουργική",
      icon: "hero-academic-cap",
      description: "Surgery of brain and nervous system"
    },
    %{
      id: "nuclear-medicine",
      name: "Nuclear Medicine",
      name_el: "Πυρηνική Ιατρική",
      icon: "hero-bolt",
      description: "Radioactive diagnostics and treatment"
    },
    %{
      id: "obstetrics",
      name: "Obstetrics",
      name_el: "Μαιευτική",
      icon: "hero-heart",
      description: "Pregnancy and childbirth"
    },
    %{
      id: "obgyn",
      name: "OB-GYN",
      name_el: "Μαιευτική-Γυναικολογία",
      icon: "hero-heart",
      description: "Obstetrics and gynecology"
    },
    %{
      id: "occupational-medicine",
      name: "Occupational Medicine",
      name_el: "Ιατρική Εργασίας",
      icon: "hero-briefcase",
      description: "Workplace health"
    },
    %{
      id: "oncology",
      name: "Oncology",
      name_el: "Ογκολογία",
      icon: "hero-shield-check",
      description: "Cancer diagnosis and treatment"
    },
    %{
      id: "ophthalmology",
      name: "Ophthalmology",
      name_el: "Οφθαλμολογία",
      icon: "hero-eye",
      description: "Eye diseases and surgery"
    },
    %{
      id: "optometry",
      name: "Optometry",
      name_el: "Οπτομετρία",
      icon: "hero-eye",
      description: "Vision care and correction"
    },
    %{
      id: "orthopedics",
      name: "Orthopedics",
      name_el: "Ορθοπεδική",
      icon: "hero-wrench",
      description: "Bones, joints, and musculoskeletal system"
    },
    %{
      id: "orthopedic-surgery",
      name: "Orthopedic Surgery",
      name_el: "Ορθοπεδική Χειρουργική",
      icon: "hero-wrench",
      description: "Surgical treatment of musculoskeletal conditions"
    },
    %{
      id: "palliative-medicine",
      name: "Palliative Medicine",
      name_el: "Παρηγορητική Ιατρική",
      icon: "hero-heart",
      description: "End-of-life and comfort care"
    },
    %{
      id: "pathology",
      name: "Pathology",
      name_el: "Παθολογοανατομία",
      icon: "hero-magnifying-glass",
      description: "Disease diagnosis through lab tests"
    },
    %{
      id: "pediatric-cardiology",
      name: "Pediatric Cardiology",
      name_el: "Παιδοκαρδιολογία",
      icon: "hero-heart",
      description: "Children's heart conditions"
    },
    %{
      id: "pediatric-surgery",
      name: "Pediatric Surgery",
      name_el: "Παιδοχειρουργική",
      icon: "hero-scissors",
      description: "Surgery for children"
    },
    %{
      id: "pediatrics",
      name: "Pediatrics",
      name_el: "Παιδιατρική",
      icon: "hero-face-smile",
      description: "Children's health and development"
    },
    %{
      id: "periodontology",
      name: "Periodontology",
      name_el: "Περιοδοντολογία",
      icon: "hero-face-smile",
      description: "Gum diseases"
    },
    %{
      id: "physical-rehab",
      name: "Physical Medicine & Rehabilitation",
      name_el: "Φυσική Ιατρική & Αποκατάσταση",
      icon: "hero-bolt",
      description: "Physical therapy and rehabilitation"
    },
    %{
      id: "plastic-surgery",
      name: "Plastic Surgery",
      name_el: "Πλαστική Χειρουργική",
      icon: "hero-scissors",
      description: "Reconstructive and cosmetic surgery"
    },
    %{
      id: "psychiatry",
      name: "Psychiatry",
      name_el: "Ψυχιατρική",
      icon: "hero-chat-bubble-left-right",
      description: "Mental health disorders"
    },
    %{
      id: "psychology",
      name: "Psychology",
      name_el: "Ψυχολογία",
      icon: "hero-chat-bubble-left-right",
      description: "Psychological therapy and counseling"
    },
    %{
      id: "pulmonology",
      name: "Pulmonology",
      name_el: "Πνευμονολογία",
      icon: "hero-cloud",
      description: "Lung and respiratory diseases"
    },
    %{
      id: "radiation-oncology",
      name: "Radiation Oncology",
      name_el: "Ακτινοθεραπευτική Ογκολογία",
      icon: "hero-bolt",
      description: "Radiation treatment for cancer"
    },
    %{
      id: "radiology",
      name: "Radiology",
      name_el: "Ακτινολογία",
      icon: "hero-photo",
      description: "Medical imaging and diagnostics"
    },
    %{
      id: "rheumatology",
      name: "Rheumatology",
      name_el: "Ρευματολογία",
      icon: "hero-hand-raised",
      description: "Arthritis and autoimmune diseases"
    },
    %{
      id: "sleep-medicine",
      name: "Sleep Medicine",
      name_el: "Ιατρική Ύπνου",
      icon: "hero-moon",
      description: "Sleep disorders"
    },
    %{
      id: "sports-medicine",
      name: "Sports Medicine",
      name_el: "Αθλητική Ιατρική",
      icon: "hero-trophy",
      description: "Sports injuries and performance"
    },
    %{
      id: "thoracic-surgery",
      name: "Thoracic Surgery",
      name_el: "Θωρακοχειρουργική",
      icon: "hero-scissors",
      description: "Surgery of chest organs"
    },
    %{
      id: "transplant-surgery",
      name: "Transplant Surgery",
      name_el: "Χειρουργική Μεταμοσχεύσεων",
      icon: "hero-arrows-right-left",
      description: "Organ transplantation"
    },
    %{
      id: "trauma-surgery",
      name: "Trauma Surgery",
      name_el: "Χειρουργική Τραύματος",
      icon: "hero-exclamation-triangle",
      description: "Emergency surgery for injuries"
    },
    %{
      id: "urology",
      name: "Urology",
      name_el: "Ουρολογία",
      icon: "hero-beaker",
      description: "Urinary tract and male reproductive system"
    },
    %{
      id: "vascular-surgery",
      name: "Vascular Surgery",
      name_el: "Αγγειοχειρουργική",
      icon: "hero-arrows-right-left",
      description: "Blood vessel surgery"
    },
    %{
      id: "virology",
      name: "Virology",
      name_el: "Ιολογία",
      icon: "hero-bug-ant",
      description: "Viral infections"
    }
  ]

  @organs [
    # Brain & Nervous System
    %{id: "brain", name: "Brain", name_el: "Εγκέφαλος", category: "nervous"},
    %{id: "cerebellum", name: "Cerebellum", name_el: "Παρεγκεφαλίδα", category: "nervous"},
    %{id: "brainstem", name: "Brainstem", name_el: "Εγκεφαλικό Στέλεχος", category: "nervous"},
    %{id: "spinal-cord", name: "Spinal Cord", name_el: "Νωτιαίος Μυελός", category: "nervous"},
    %{id: "nerves", name: "Nerves", name_el: "Νεύρα", category: "nervous"},

    # Sensory Organs
    %{id: "eyes", name: "Eyes", name_el: "Μάτια", category: "sensory"},
    %{id: "ears", name: "Ears", name_el: "Αυτιά", category: "sensory"},
    %{id: "nose", name: "Nose", name_el: "Μύτη", category: "sensory"},
    %{id: "sinuses", name: "Sinuses", name_el: "Ιγμόρεια", category: "sensory"},
    %{id: "tongue", name: "Tongue", name_el: "Γλώσσα", category: "sensory"},

    # Mouth & Throat
    %{id: "mouth", name: "Mouth", name_el: "Στόμα", category: "digestive"},
    %{id: "teeth", name: "Teeth", name_el: "Δόντια", category: "digestive"},
    %{id: "gums", name: "Gums", name_el: "Ούλα", category: "digestive"},
    %{id: "throat", name: "Throat", name_el: "Λαιμός", category: "respiratory"},
    %{
      id: "salivary-glands",
      name: "Salivary Glands",
      name_el: "Σιελογόνοι Αδένες",
      category: "digestive"
    },

    # Endocrine System
    %{id: "thyroid", name: "Thyroid", name_el: "Θυρεοειδής", category: "endocrine"},
    %{id: "parathyroid", name: "Parathyroid", name_el: "Παραθυρεοειδείς", category: "endocrine"},
    %{id: "pituitary-gland", name: "Pituitary Gland", name_el: "Υπόφυση", category: "endocrine"},
    %{id: "pineal-gland", name: "Pineal Gland", name_el: "Επίφυση", category: "endocrine"},
    %{id: "hypothalamus", name: "Hypothalamus", name_el: "Υποθάλαμος", category: "endocrine"},
    %{
      id: "adrenal-glands",
      name: "Adrenal Glands",
      name_el: "Επινεφρίδια",
      category: "endocrine"
    },

    # Digestive System
    %{id: "esophagus", name: "Esophagus", name_el: "Οισοφάγος", category: "digestive"},
    %{id: "stomach", name: "Stomach", name_el: "Στομάχι", category: "digestive"},
    %{id: "duodenum", name: "Duodenum", name_el: "Δωδεκαδάκτυλο", category: "digestive"},
    %{
      id: "small-intestine",
      name: "Small Intestine",
      name_el: "Λεπτό Έντερο",
      category: "digestive"
    },
    %{id: "jejunum", name: "Jejunum", name_el: "Νηστίδα", category: "digestive"},
    %{id: "ileum", name: "Ileum", name_el: "Ειλεός", category: "digestive"},
    %{
      id: "large-intestine",
      name: "Large Intestine",
      name_el: "Παχύ Έντερο",
      category: "digestive"
    },
    %{id: "colon", name: "Colon", name_el: "Κόλον", category: "digestive"},
    %{id: "rectum", name: "Rectum", name_el: "Ορθό Έντερο", category: "digestive"},
    %{id: "anus", name: "Anus", name_el: "Πρωκτός", category: "digestive"},
    %{id: "liver", name: "Liver", name_el: "Ήπαρ (Συκώτι)", category: "digestive"},
    %{id: "gallbladder", name: "Gallbladder", name_el: "Χοληδόχος Κύστη", category: "digestive"},
    %{id: "pancreas", name: "Pancreas", name_el: "Πάγκρεας", category: "digestive"},
    %{id: "appendix", name: "Appendix", name_el: "Σκωληκοειδής Απόφυση", category: "digestive"},

    # Urinary System
    %{id: "kidneys", name: "Kidneys", name_el: "Νεφρά", category: "urinary"},
    %{id: "ureters", name: "Ureters", name_el: "Ουρητήρες", category: "urinary"},
    %{id: "bladder", name: "Bladder", name_el: "Ουροδόχος Κύστη", category: "urinary"},
    %{id: "urethra", name: "Urethra", name_el: "Ουρήθρα", category: "urinary"},

    # Respiratory System
    %{id: "lungs", name: "Lungs", name_el: "Πνεύμονες", category: "respiratory"},
    %{id: "bronchi", name: "Bronchi", name_el: "Βρόγχοι", category: "respiratory"},
    %{id: "trachea", name: "Trachea", name_el: "Τραχεία", category: "respiratory"},
    %{id: "larynx", name: "Larynx", name_el: "Λάρυγγας", category: "respiratory"},
    %{id: "diaphragm", name: "Diaphragm", name_el: "Διάφραγμα", category: "respiratory"},

    # Cardiovascular System
    %{id: "heart", name: "Heart", name_el: "Καρδιά", category: "cardiovascular"},
    %{id: "arteries", name: "Arteries", name_el: "Αρτηρίες", category: "cardiovascular"},
    %{id: "veins", name: "Veins", name_el: "Φλέβες", category: "cardiovascular"},
    %{id: "capillaries", name: "Capillaries", name_el: "Τριχοειδή", category: "cardiovascular"},
    %{id: "aorta", name: "Aorta", name_el: "Αορτή", category: "cardiovascular"},

    # Lymphatic & Immune System
    %{id: "lymph-nodes", name: "Lymph Nodes", name_el: "Λεμφαδένες", category: "immune"},
    %{
      id: "lymphatic-vessels",
      name: "Lymphatic Vessels",
      name_el: "Λεμφαγγεία",
      category: "immune"
    },
    %{id: "spleen", name: "Spleen", name_el: "Σπλήνα", category: "immune"},
    %{id: "thymus", name: "Thymus", name_el: "Θύμος Αδένας", category: "immune"},
    %{id: "tonsils", name: "Tonsils", name_el: "Αμυγδαλές", category: "immune"},
    %{id: "bone-marrow", name: "Bone Marrow", name_el: "Μυελός Οστών", category: "immune"},
    %{id: "blood", name: "Blood", name_el: "Αίμα", category: "immune"},

    # Musculoskeletal System
    %{id: "bones", name: "Bones", name_el: "Οστά", category: "musculoskeletal"},
    %{id: "joints", name: "Joints", name_el: "Αρθρώσεις", category: "musculoskeletal"},
    %{id: "cartilage", name: "Cartilage", name_el: "Χόνδρος", category: "musculoskeletal"},
    %{id: "ligaments", name: "Ligaments", name_el: "Σύνδεσμοι", category: "musculoskeletal"},
    %{id: "tendons", name: "Tendons", name_el: "Τένοντες", category: "musculoskeletal"},
    %{id: "muscles", name: "Muscles", name_el: "Μύες", category: "musculoskeletal"},
    %{id: "spine", name: "Spine", name_el: "Σπονδυλική Στήλη", category: "musculoskeletal"},

    # Integumentary System
    %{id: "skin", name: "Skin", name_el: "Δέρμα", category: "integumentary"},
    %{id: "hair", name: "Hair", name_el: "Τρίχες", category: "integumentary"},
    %{id: "nails", name: "Nails", name_el: "Νύχια", category: "integumentary"},

    # Female Reproductive System
    %{id: "breast", name: "Breast", name_el: "Μαστός", category: "reproductive"},
    %{id: "uterus", name: "Uterus", name_el: "Μήτρα", category: "reproductive"},
    %{id: "endometrium", name: "Endometrium", name_el: "Ενδομήτριο", category: "reproductive"},
    %{id: "cervix", name: "Cervix", name_el: "Τράχηλος Μήτρας", category: "reproductive"},
    %{id: "ovaries", name: "Ovaries", name_el: "Ωοθήκες", category: "reproductive"},
    %{
      id: "fallopian-tubes",
      name: "Fallopian Tubes",
      name_el: "Σάλπιγγες",
      category: "reproductive"
    },
    %{id: "vagina", name: "Vagina", name_el: "Κόλπος", category: "reproductive"},
    %{id: "vulva", name: "Vulva", name_el: "Αιδοίο", category: "reproductive"},
    %{id: "placenta", name: "Placenta", name_el: "Πλακούντας", category: "reproductive"},

    # Male Reproductive System
    %{id: "prostate", name: "Prostate", name_el: "Προστάτης", category: "reproductive"},
    %{id: "testicles", name: "Testicles", name_el: "Όρχεις", category: "reproductive"},
    %{id: "epididymis", name: "Epididymis", name_el: "Επιδιδυμίδα", category: "reproductive"},
    %{
      id: "vas-deferens",
      name: "Vas Deferens",
      name_el: "Σπερματικός Πόρος",
      category: "reproductive"
    },
    %{
      id: "seminal-vesicles",
      name: "Seminal Vesicles",
      name_el: "Σπερματοδόχες Κύστεις",
      category: "reproductive"
    },
    %{id: "penis", name: "Penis", name_el: "Πέος", category: "reproductive"},

    # General/System-wide
    %{
      id: "immune-system",
      name: "Immune System",
      name_el: "Ανοσοποιητικό Σύστημα",
      category: "system"
    },
    %{
      id: "connective-tissue",
      name: "Connective Tissue",
      name_el: "Συνδετικός Ιστός",
      category: "system"
    }
  ]

  @specialty_to_organs %{
    "cardiology" => ["heart", "arteries", "veins", "capillaries", "aorta"],
    "cardiac-surgery" => ["heart", "aorta", "arteries", "veins"],
    "cardiothoracic-surgery" => ["heart", "lungs", "aorta", "trachea"],
    "interventional-cardiology" => ["heart", "arteries", "veins", "aorta"],
    "pediatric-cardiology" => ["heart", "arteries", "veins"],
    "vascular-surgery" => ["arteries", "veins", "capillaries", "aorta", "lymphatic-vessels"],
    "pulmonology" => ["lungs", "trachea", "bronchi", "larynx", "diaphragm"],
    "thoracic-surgery" => ["lungs", "esophagus", "trachea", "bronchi", "diaphragm"],
    "neurology" => ["brain", "cerebellum", "brainstem", "spinal-cord", "nerves"],
    "neurosurgery" => ["brain", "cerebellum", "brainstem", "spinal-cord", "nerves", "spine"],
    "neuropsychiatry" => ["brain", "nerves"],
    "gastroenterology" => [
      "esophagus",
      "stomach",
      "duodenum",
      "small-intestine",
      "jejunum",
      "ileum",
      "large-intestine",
      "colon",
      "rectum",
      "liver",
      "gallbladder",
      "pancreas",
      "appendix"
    ],
    "hepatology" => ["liver", "gallbladder"],
    "colorectal-surgery" => ["colon", "rectum", "anus", "large-intestine"],
    "bariatric-surgery" => ["stomach", "small-intestine", "duodenum"],
    "endocrinology" => [
      "thyroid",
      "parathyroid",
      "pituitary-gland",
      "pineal-gland",
      "hypothalamus",
      "adrenal-glands",
      "pancreas"
    ],
    "diabetology" => ["pancreas", "adrenal-glands"],
    "nephrology" => ["kidneys", "ureters"],
    "urology" => [
      "kidneys",
      "ureters",
      "bladder",
      "urethra",
      "prostate",
      "testicles",
      "epididymis",
      "vas-deferens",
      "seminal-vesicles",
      "penis"
    ],
    "andrology" => [
      "prostate",
      "testicles",
      "epididymis",
      "vas-deferens",
      "seminal-vesicles",
      "penis"
    ],
    "dermatology" => ["skin", "hair", "nails"],
    "plastic-surgery" => ["skin", "breast", "muscles", "connective-tissue"],
    "rheumatology" => ["joints", "connective-tissue", "immune-system", "muscles", "bones"],
    "orthopedics" => ["bones", "joints", "ligaments", "tendons", "muscles", "cartilage", "spine"],
    "orthopedic-surgery" => [
      "bones",
      "joints",
      "ligaments",
      "tendons",
      "muscles",
      "cartilage",
      "spine"
    ],
    "hand-surgery" => ["bones", "joints", "tendons", "muscles", "nerves"],
    "sports-medicine" => ["muscles", "joints", "bones", "tendons", "ligaments"],
    "physical-rehab" => ["muscles", "joints", "bones", "nerves", "spine"],
    "ophthalmology" => ["eyes"],
    "optometry" => ["eyes"],
    "ent" => ["ears", "nose", "sinuses", "throat", "larynx", "tonsils"],
    "audiology" => ["ears"],
    "hematology" => ["blood", "bone-marrow", "lymph-nodes", "spleen"],
    "allergy-immunology" => [
      "immune-system",
      "lymph-nodes",
      "spleen",
      "tonsils",
      "thymus",
      "skin",
      "lungs"
    ],
    "infectious-diseases" => ["immune-system", "blood", "lymph-nodes"],
    "virology" => ["immune-system", "blood"],
    "oncology" => ["all"],
    "radiation-oncology" => ["all"],
    "gynecologic-oncology" => [
      "uterus",
      "ovaries",
      "cervix",
      "fallopian-tubes",
      "vagina",
      "vulva"
    ],
    "gynecology" => [
      "uterus",
      "ovaries",
      "cervix",
      "fallopian-tubes",
      "vagina",
      "vulva",
      "breast"
    ],
    "obgyn" => [
      "uterus",
      "ovaries",
      "cervix",
      "fallopian-tubes",
      "vagina",
      "vulva",
      "breast",
      "placenta"
    ],
    "obstetrics" => ["uterus", "placenta", "cervix", "ovaries"],
    "pediatrics" => ["all-children"],
    "pediatric-surgery" => ["all-children"],
    "neonatology" => ["all-newborn"],
    "psychiatry" => ["brain", "nerves"],
    "psychology" => ["brain"],
    "dentistry" => ["teeth", "gums", "mouth", "tongue", "salivary-glands"],
    "periodontology" => ["gums", "teeth"],
    "general-practice" => ["all"],
    "family-medicine" => ["all"],
    "internal-medicine" => ["all-internal"],
    "geriatrics" => ["all-elderly"],
    "emergency-medicine" => ["all"],
    "critical-care" => ["all"],
    "palliative-medicine" => ["all"],
    "radiology" => ["all"],
    "nuclear-medicine" => ["all"],
    "interventional-radiology" => ["all"],
    "pathology" => ["all"],
    "anesthesiology" => ["nerves", "brain"],
    "general-surgery" => ["all"],
    "trauma-surgery" => ["all"],
    "transplant-surgery" => ["kidneys", "liver", "heart", "lungs", "pancreas", "bone-marrow"],
    "sleep-medicine" => ["brain", "lungs", "trachea"],
    "occupational-medicine" => ["all"]
  }

  # Build reverse mapping at compile time
  @organ_to_specialties @specialty_to_organs
                        |> Enum.flat_map(fn {specialty, organs} ->
                          Enum.map(organs, fn organ -> {organ, specialty} end)
                        end)
                        |> Enum.group_by(fn {organ, _} -> organ end, fn {_, specialty} ->
                          specialty
                        end)

  # Public API

  @doc """
  Returns all medical specialties.
  """
  def specialties, do: @specialties

  @doc """
  Returns all organs/body parts.
  """
  def organs, do: @organs

  @doc """
  Returns specialty count.
  """
  def specialty_count, do: length(@specialties)

  @doc """
  Returns organ count.
  """
  def organ_count, do: length(@organs)

  @doc """
  Gets a specialty by ID.
  """
  def get_specialty(id) do
    Enum.find(@specialties, fn s -> s.id == id end)
  end

  @doc """
  Gets an organ by ID.
  """
  def get_organ(id) do
    Enum.find(@organs, fn o -> o.id == id end)
  end

  @doc """
  Returns organ IDs for a specialty.
  """
  def organs_for_specialty(specialty_id) do
    Map.get(@specialty_to_organs, specialty_id, [])
  end

  @doc """
  Returns specialty IDs that treat a given organ.
  """
  def specialties_for_organ(organ_id) do
    direct = Map.get(@organ_to_specialties, organ_id, [])

    # Also include "all" specialties (oncology, radiology, etc.)
    all_specialties = Map.get(@organ_to_specialties, "all", [])

    Enum.uniq(direct ++ all_specialties)
  end

  @doc """
  Search specialties by organ name (partial match).
  Useful for "heart" → Cardiology, Cardiac Surgery, etc.
  """
  def search_specialties_by_organ(query) when is_binary(query) do
    query_lower = String.downcase(query)

    # Find matching organs
    matching_organs =
      @organs
      |> Enum.filter(fn organ ->
        String.contains?(String.downcase(organ.name), query_lower) ||
          String.contains?(String.downcase(organ.name_el), query_lower)
      end)
      |> Enum.map(& &1.id)

    # Get specialties for those organs
    matching_organs
    |> Enum.flat_map(&specialties_for_organ/1)
    |> Enum.uniq()
    |> Enum.map(&get_specialty/1)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Search specialties by name (partial match).
  """
  def search_specialties(query) when is_binary(query) do
    query_lower = String.downcase(query)

    @specialties
    |> Enum.filter(fn specialty ->
      String.contains?(String.downcase(specialty.name), query_lower) ||
        String.contains?(String.downcase(specialty.name_el), query_lower)
    end)
  end

  @doc """
  Combined search: search by specialty name OR organ name.
  Returns specialties that match either.
  """
  def search(query) when is_binary(query) do
    by_name = search_specialties(query)
    by_organ = search_specialties_by_organ(query)

    (by_name ++ by_organ)
    |> Enum.uniq_by(& &1.id)
    |> Enum.sort_by(& &1.name)
  end

  @doc """
  Returns organs grouped by category.
  """
  def organs_by_category do
    Enum.group_by(@organs, & &1.category)
  end

  @doc """
  Returns popular specialties for homepage display.
  """
  def popular_specialties do
    popular_ids = [
      "general-practice",
      "cardiology",
      "dermatology",
      "orthopedics",
      "pediatrics",
      "gynecology",
      "ophthalmology",
      "dentistry",
      "ent",
      "psychiatry",
      "gastroenterology",
      "neurology"
    ]

    popular_ids
    |> Enum.map(&get_specialty/1)
    |> Enum.reject(&is_nil/1)
  end
end
