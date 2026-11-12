package com.caldova.clinicalweb.inventory;

import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class InventoryPageController {

    private final InventoryService inventoryService;

    public InventoryPageController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping("/")
    public String inventory(
            @RequestParam(defaultValue = "") String query,
            @RequestParam(defaultValue = "All statuses") String status,
            Model model) {
        model.addAttribute("query", query);
        model.addAttribute("status", status);

        try {
            List<Material> materials = inventoryService.loadMaterials();
            List<Material> filteredMaterials = filter(materials, query, status);

            model.addAttribute("materials", filteredMaterials);
            model.addAttribute("catalogedCount", materials.size());
            model.addAttribute("readyCount", countByStatus(materials, "In stock"));
            model.addAttribute("attentionCount", materials.size() - countByStatus(materials, "In stock"));
            model.addAttribute("resultCount", filteredMaterials.size());
        } catch (InventoryUnavailableException exception) {
            model.addAttribute(
                    "error",
                    "The clinical API is unavailable. Start CaldovaClinicalApiJava and try again.");
        }

        return "inventory";
    }

    private List<Material> filter(List<Material> materials, String query, String status) {
        String normalizedQuery = query.strip().toLowerCase(Locale.ROOT);
        return materials.stream()
                .filter(material -> searchableText(material).contains(normalizedQuery))
                .filter(material -> "All statuses".equals(status) || material.status().equals(status))
                .toList();
    }

    private String searchableText(Material material) {
        return String.join(" ", material.name(), material.category(), material.lotNumber())
                .toLowerCase(Locale.ROOT);
    }

    private long countByStatus(List<Material> materials, String status) {
        return materials.stream().filter(material -> material.status().equals(status)).count();
    }
}