package com.caldova.clinicalapi.inventory;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;

public record Material(
        long id,
        String name,
        String category,
        @JsonProperty("lot_number") String lotNumber,
        int quantity,
        String unit,
        String status,
        String location,
        @JsonProperty("expiry_date") LocalDate expiryDate,
        @JsonProperty("image_url") String imageUrl) {
}