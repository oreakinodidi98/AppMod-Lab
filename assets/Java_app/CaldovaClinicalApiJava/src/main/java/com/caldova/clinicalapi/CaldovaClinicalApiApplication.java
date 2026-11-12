package com.caldova.clinicalapi;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;

@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)
public class CaldovaClinicalApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(CaldovaClinicalApiApplication.class, args);
    }
}