package com.caldova.clinicalweb.inventory;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(InventoryPageController.class)
class InventoryPageControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private InventoryService inventoryService;

    @Test
    void inventoryFiltersByQueryAndStatusAndBuildsSummaryMetrics() throws Exception {
        when(inventoryService.loadMaterials()).thenReturn(List.of(
                material("Caldovir 50 mg tablets", "Investigational drug", "CDV50", "In stock"),
                material("Comparator capsules", "Comparator", "CMP01", "Reorder")));

        mockMvc.perform(get("/").param("query", "comparator").param("status", "Reorder"))
                .andExpect(status().isOk())
                .andExpect(view().name("inventory"))
                .andExpect(model().attribute("catalogedCount", 2))
                .andExpect(model().attribute("readyCount", 1L))
                .andExpect(model().attribute("attentionCount", 1L))
                .andExpect(model().attribute("resultCount", 1))
                .andExpect(content().string(containsString("Comparator capsules")));
    }

    @Test
    void inventoryShowsAnActionableErrorWhenTheApiIsUnavailable() throws Exception {
        when(inventoryService.loadMaterials())
                .thenThrow(new InventoryUnavailableException("Unavailable", new IllegalStateException()));

        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Start CaldovaClinicalApiJava and try again")));
    }

    private Material material(String name, String category, String lotNumber, String status) {
        return new Material(
                1,
                name,
                category,
                lotNumber,
                20,
                "kits",
                status,
                "Pharmacy A",
                LocalDate.of(2027, 4, 30),
                "https://example.test/material.png");
    }
}