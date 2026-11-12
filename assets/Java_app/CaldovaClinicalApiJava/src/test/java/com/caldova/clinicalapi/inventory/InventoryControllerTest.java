package com.caldova.clinicalapi.inventory;

import com.caldova.clinicalapi.CaldovaClinicalApiApplication;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(InventoryController.class)
@ContextConfiguration(classes = CaldovaClinicalApiApplication.class)
class InventoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MaterialRepository materialRepository;

    @Test
    void liveReturnsAliveStatus() throws Exception {
        mockMvc.perform(get("/live"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("alive"));
    }

    @Test
    void healthReturnsRepositoryReadiness() throws Exception {
        when(materialRepository.health())
                .thenReturn(Map.of("status", "healthy", "data_mode", "demo"));

        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("healthy"))
                .andExpect(jsonPath("$.data_mode").value("demo"));
    }

    @Test
    void healthReturnsServiceUnavailableWhenRepositoryFails() throws Exception {
        when(materialRepository.health()).thenThrow(new IllegalStateException("unavailable"));

        mockMvc.perform(get("/health"))
                .andExpect(status().isServiceUnavailable());
    }

    @Test
    void materialsPreserveTheExistingJsonContract() throws Exception {
        when(materialRepository.findAll()).thenReturn(List.of(new Material(
                1,
                "Caldovir 50 mg tablets",
                "Investigational drug",
                "CDV50-24018",
                1240,
                "kits",
                "In stock",
                "Pharmacy A - Cold storage",
                LocalDate.of(2027, 4, 30),
                "https://example.test/material.png")));

        mockMvc.perform(get("/materials"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].lot_number").value("CDV50-24018"))
                .andExpect(jsonPath("$[0].expiry_date").value("2027-04-30"))
                .andExpect(jsonPath("$[0].image_url").value("https://example.test/material.png"));
    }
}