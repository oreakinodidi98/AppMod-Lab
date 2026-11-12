package com.caldova.clinicalapi.inventory;

import java.util.List;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class InventoryController {

    private final MaterialRepository materialRepository;

    public InventoryController(MaterialRepository materialRepository) {
        this.materialRepository = materialRepository;
    }

    @GetMapping("/live")
    public Map<String, String> live() {
        return Map.of("status", "alive");
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        try {
            return materialRepository.health();
        } catch (RuntimeException exception) {
            throw new ResponseStatusException(
                    HttpStatus.SERVICE_UNAVAILABLE, "Inventory data source failed", exception);
        }
    }

    @GetMapping("/materials")
    public List<Material> materials() {
        return materialRepository.findAll();
    }
}