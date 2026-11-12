package com.caldova.clinicalapi.config;

import com.azure.core.credential.AccessToken;
import com.azure.core.credential.TokenCredential;
import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredentialBuilder;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.time.Duration;
import javax.sql.DataSource;
import org.postgresql.ds.PGSimpleDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

@Configuration(proxyBeanMethods = false)
@ConditionalOnProperty(name = "caldova.data-mode", havingValue = "database", matchIfMissing = true)
class EntraPostgresConfiguration {

    private static final String POSTGRES_SCOPE =
            "https://ossrdbms-aad.database.windows.net/.default";

    @Bean
    TokenCredential databaseTokenCredential() {
        return new DefaultAzureCredentialBuilder().build();
    }

    @Bean
    DataSource dataSource(
            TokenCredential credential,
            @Value("${caldova.datasource.host}") String host,
            @Value("${caldova.datasource.port}") int port,
            @Value("${caldova.datasource.database}") String database,
            @Value("${caldova.datasource.username}") String username) {
        requireSetting(host, "DATABASE_HOST");
        requireSetting(database, "DATABASE_NAME");
        requireSetting(username, "DATABASE_USER");

        PGSimpleDataSource postgresDataSource = new PGSimpleDataSource();
        postgresDataSource.setUrl(
                "jdbc:postgresql://%s:%d/%s?sslmode=require".formatted(host, port, database));

        TokenRequestContext tokenRequest = new TokenRequestContext().addScopes(POSTGRES_SCOPE);
        DatabaseAccessTokenProvider tokenProvider = () -> {
            AccessToken token = credential.getToken(tokenRequest).block(Duration.ofSeconds(30));
            if (token == null || !StringUtils.hasText(token.getToken())) {
                throw new IllegalStateException("Azure Identity returned an empty database token");
            }
            return token.getToken();
        };

        HikariConfig hikariConfig = new HikariConfig();
        hikariConfig.setDataSource(
                new EntraPostgresDataSource(postgresDataSource, username, tokenProvider));
        hikariConfig.setConnectionTimeout(Duration.ofSeconds(5).toMillis());
        return new HikariDataSource(hikariConfig);
    }

    private static void requireSetting(String value, String environmentVariable) {
        if (!StringUtils.hasText(value)) {
            throw new IllegalStateException(
                    environmentVariable + " is required when DATABASE_AUTH_MODE is 'entra'");
        }
    }
}