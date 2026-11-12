package com.caldova.clinicalapi.inventory;

import java.util.List;
import java.util.Map;

public interface MaterialRepository {

    List<Material> findAll();

    Map<String, String> health();
}