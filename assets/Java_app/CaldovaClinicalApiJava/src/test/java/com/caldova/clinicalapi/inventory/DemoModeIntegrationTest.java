package com.caldova.clinicalapi.inventory;

import com.caldova.clinicalapi.CaldovaClinicalApiApplication;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(classes = CaldovaClinicalApiApplication.class, properties = {
        "caldova.data-mode=demo",
    "caldova.datasource.host=must-not-be-used.invalid"
})
@AutoConfigureMockMvc
class DemoModeIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Test
    void healthIsReadyWithoutPostgres() throws Exception {
        mockMvc.perform(get("/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("healthy"))
                .andExpect(jsonPath("$.data_mode").value("demo"));
    }

    @Test
    void materialsReturnsSeededInventoryWithoutPostgres() throws Exception {
        mockMvc.perform(get("/materials"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(6))
                .andExpect(jsonPath("$[0].lot_number").value("CDV50-24018"))
                .andExpect(jsonPath("$[5].lot_number").value("TDL-24007"));
    }
}