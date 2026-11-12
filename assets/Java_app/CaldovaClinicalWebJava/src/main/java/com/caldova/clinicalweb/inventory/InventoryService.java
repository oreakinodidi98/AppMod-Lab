package com.caldova.clinicalweb.inventory;

import java.util.List;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class InventoryService {

    private final RestClient restClient;

    public InventoryService(RestClient.Builder restClientBuilder) {
        this.restClient = restClientBuilder.build();
    }

    public List<Material> loadMaterials() {
        try {
            List<Material> materials = restClient.get()
                    .uri("/materials")
                    .retrieve()
                    .body(new ParameterizedTypeReference<>() {
                    });
            return materials == null ? List.of() : materials;
        } catch (RestClientException exception) {
            throw new InventoryUnavailableException("The clinical API is unavailable.", exception);
        }
    }
}