package com.caldova.clinicalapi.config;

import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.util.Objects;
import java.util.logging.Logger;
import javax.sql.DataSource;

final class EntraPostgresDataSource implements DataSource {

    private final DataSource delegate;
    private final String username;
    private final DatabaseAccessTokenProvider tokenProvider;

    EntraPostgresDataSource(
            DataSource delegate, String username, DatabaseAccessTokenProvider tokenProvider) {
        this.delegate = Objects.requireNonNull(delegate);
        this.username = Objects.requireNonNull(username);
        this.tokenProvider = Objects.requireNonNull(tokenProvider);
    }

    @Override
    public Connection getConnection() throws SQLException {
        try {
            return delegate.getConnection(username, tokenProvider.getToken());
        } catch (RuntimeException exception) {
            throw new SQLException("Unable to acquire a Microsoft Entra database token", exception);
        }
    }

    @Override
    public Connection getConnection(String ignoredUsername, String ignoredPassword) throws SQLException {
        return getConnection();
    }

    @Override
    public PrintWriter getLogWriter() throws SQLException {
        return delegate.getLogWriter();
    }

    @Override
    public void setLogWriter(PrintWriter out) throws SQLException {
        delegate.setLogWriter(out);
    }

    @Override
    public void setLoginTimeout(int seconds) throws SQLException {
        delegate.setLoginTimeout(seconds);
    }

    @Override
    public int getLoginTimeout() throws SQLException {
        return delegate.getLoginTimeout();
    }

    @Override
    public Logger getParentLogger() throws SQLFeatureNotSupportedException {
        return delegate.getParentLogger();
    }

    @Override
    public <T> T unwrap(Class<T> type) throws SQLException {
        return delegate.unwrap(type);
    }

    @Override
    public boolean isWrapperFor(Class<?> type) throws SQLException {
        return delegate.isWrapperFor(type);
    }
}

@FunctionalInterface
interface DatabaseAccessTokenProvider {
    String getToken();
}