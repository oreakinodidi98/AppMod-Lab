package com.caldova.clinicalapi.config;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.sql.Connection;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;

class EntraPostgresDataSourceTest {

    @Test
    void eachPhysicalConnectionUsesTheConfiguredUsernameAndAFreshToken() throws Exception {
        DataSource delegate = mock(DataSource.class);
        Connection firstConnection = mock(Connection.class);
        Connection secondConnection = mock(Connection.class);
        DatabaseAccessTokenProvider tokenProvider = mock(DatabaseAccessTokenProvider.class);
        when(tokenProvider.getToken()).thenReturn("first-token", "second-token");
        when(delegate.getConnection("aks-mi", "first-token")).thenReturn(firstConnection);
        when(delegate.getConnection("aks-mi", "second-token")).thenReturn(secondConnection);
        EntraPostgresDataSource dataSource =
                new EntraPostgresDataSource(delegate, "aks-mi", tokenProvider);

        dataSource.getConnection();
        dataSource.getConnection();

        InOrder calls = inOrder(tokenProvider, delegate);
        calls.verify(tokenProvider).getToken();
        calls.verify(delegate).getConnection("aks-mi", "first-token");
        calls.verify(tokenProvider).getToken();
        calls.verify(delegate).getConnection("aks-mi", "second-token");
    }

    @Test
    void tokenAcquisitionFailureIsReportedAsASqlConnectionFailure() {
        DataSource delegate = mock(DataSource.class);
        DatabaseAccessTokenProvider tokenProvider = mock(DatabaseAccessTokenProvider.class);
        when(tokenProvider.getToken()).thenThrow(new IllegalStateException("token unavailable"));
        EntraPostgresDataSource dataSource =
                new EntraPostgresDataSource(delegate, "aks-mi", tokenProvider);

        assertThatThrownBy(dataSource::getConnection)
                .isInstanceOf(java.sql.SQLException.class)
                .hasMessage("Unable to acquire a Microsoft Entra database token")
                .hasRootCauseMessage("token unavailable");
    }
}