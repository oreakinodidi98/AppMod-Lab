package com.caldova.clinicalapi.config;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

import com.azure.core.credential.TokenCredential;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;

class EntraPostgresConfigurationTest {

    @ParameterizedTest(name = "missing {3}")
    @MethodSource("missingRequiredSettings")
    void missingRequiredSettingFailsBeforePoolConstruction(
            String host, String database, String username, String environmentVariable) {
        EntraPostgresConfiguration configuration = new EntraPostgresConfiguration();

        assertThatThrownBy(
                        () ->
                                configuration.dataSource(
                                        mock(TokenCredential.class),
                                        host,
                                        5432,
                                        database,
                                        username))
                .isInstanceOf(IllegalStateException.class)
                .hasMessage(
                        environmentVariable
                                + " is required when DATABASE_AUTH_MODE is 'entra'");
    }

    private static java.util.stream.Stream<Arguments> missingRequiredSettings() {
        return java.util.stream.Stream.of(
                Arguments.of("", "caldova", "aks-mi", "DATABASE_HOST"),
                Arguments.of("db.example", " ", "aks-mi", "DATABASE_NAME"),
                Arguments.of("db.example", "caldova", null, "DATABASE_USER"));
    }
}