package com.caldova.clinicalweb.inventory;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Locale;

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

    private static final DateTimeFormatter DISPLAY_DATE = DateTimeFormatter.ofPattern("MMM dd, uuuu");

    public String formattedExpiryDate() {
        return expiryDate.format(DISPLAY_DATE);
    }

    public String statusClass() {
        return status.toLowerCase(Locale.ROOT).replace(' ', '-');
    }
}