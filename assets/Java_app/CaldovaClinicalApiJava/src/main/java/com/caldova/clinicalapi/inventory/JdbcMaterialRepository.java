package com.caldova.clinicalapi.inventory;

import java.util.List;
import java.util.Map;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
@ConditionalOnProperty(name = "caldova.data-mode", havingValue = "database", matchIfMissing = true)
final class JdbcMaterialRepository implements MaterialRepository {

    private static final String MATERIALS_QUERY = """
            SELECT m.id,
                   m.name,
                   c.name AS category,
                   i.lot_number,
                   i.quantity,
                   m.unit,
                   i.status,
                   l.name AS location,
                   i.expiry_date,
                   m.image_url
              FROM pharmacy.materials m
              JOIN pharmacy.categories c ON c.id = m.category_id
              JOIN pharmacy.inventory_lots i ON i.material_id = m.id
              JOIN pharmacy.locations l ON l.id = i.location_id
             ORDER BY m.name, i.expiry_date
            """;

    private final JdbcClient jdbcClient;

    JdbcMaterialRepository(JdbcClient jdbcClient) {
        this.jdbcClient = jdbcClient;
    }

    @Override
    public List<Material> findAll() {
        return jdbcClient.sql(MATERIALS_QUERY)
                .query((resultSet, rowNumber) -> new Material(
                        resultSet.getLong("id"),
                        resultSet.getString("name"),
                        resultSet.getString("category"),
                        resultSet.getString("lot_number"),
                        resultSet.getInt("quantity"),
                        resultSet.getString("unit"),
                        resultSet.getString("status"),
                        resultSet.getString("location"),
                        resultSet.getObject("expiry_date", java.time.LocalDate.class),
                        resultSet.getString("image_url")))
                .list();
    }

    @Override
    public Map<String, String> health() {
        jdbcClient.sql("SELECT 1").query(Integer.class).single();
        return Map.of("status", "healthy", "database", "connected");
    }
}