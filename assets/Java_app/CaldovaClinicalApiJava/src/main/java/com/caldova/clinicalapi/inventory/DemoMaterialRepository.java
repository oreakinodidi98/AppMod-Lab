package com.caldova.clinicalapi.inventory;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Repository;

@Repository
@ConditionalOnProperty(name = "caldova.data-mode", havingValue = "demo")
class DemoMaterialRepository implements MaterialRepository {

    private static final List<Material> MATERIALS = List.of(
            new Material(1, "Caldovir 50 mg tablets", "Investigational drug", "CDV50-24018", 1240,
                    "kits", "In stock", "Pharmacy A · Cold storage", LocalDate.of(2027, 4, 30),
                    "https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=900&q=80"),
            new Material(2, "Caldovir 100 mg tablets", "Investigational drug", "CDV100-24009", 186,
                    "kits", "Low stock", "Pharmacy A · Secure vault", LocalDate.of(2027, 1, 31),
                    "https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=900&q=80"),
            new Material(3, "Placebo tablets", "Comparator", "PCB-24021", 980,
                    "kits", "In stock", "Pharmacy A · Cold storage", LocalDate.of(2027, 5, 31),
                    "https://images.unsplash.com/photo-1550572017-edd951aa8f72?auto=format&fit=crop&w=900&q=80"),
            new Material(4, "Comparator capsules", "Comparator", "CMP-23114", 42,
                    "bottles", "Reorder", "Depot B · Ambient", LocalDate.of(2026, 10, 31),
                    "https://images.unsplash.com/photo-1559757175-0eb30cd8c063?auto=format&fit=crop&w=900&q=80"),
            new Material(5, "Sterile dosing syringes", "Ancillary supply", "SDS-24032", 3200,
                    "units", "In stock", "Clinic 04 · Supply room", LocalDate.of(2029, 12, 31),
                    "https://images.unsplash.com/photo-1576671081837-49000212a370?auto=format&fit=crop&w=900&q=80"),
            new Material(6, "Temperature data loggers", "Ancillary supply", "TDL-24007", 74,
                    "units", "Low stock", "Depot B · Ambient", LocalDate.of(2030, 6, 30),
                    "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&w=900&q=80"));

    @Override
    public List<Material> findAll() {
        return MATERIALS;
    }

    @Override
    public Map<String, String> health() {
        return Map.of("status", "healthy", "data_mode", "demo");
    }
}