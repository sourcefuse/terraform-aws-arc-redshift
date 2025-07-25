# Stage 1: Builder
FROM composer:2.7 AS builder

# Add a non-root user
RUN addgroup -S nonroot && adduser -S nonroot -G nonroot

# Clone the repo to a known path and clean lock files
RUN git clone --depth 1 https://github.com/aquasecurity/trivy-ci-test.git /trivy-ci-test \
    && rm -f /trivy-ci-test/Cargo.lock /trivy-ci-test/Pipfile.lock

# Install MySQL client
RUN apk add --no-cache mysql-client

# Stage 2: Runtime
FROM composer:2.7 AS runtime

# Copy user and group info
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

# Copy the cloned and cleaned repo
COPY --from=builder /trivy-ci-test /trivy-ci-test

# Switch to non-root user
USER nonroot

WORKDIR /trivy-ci-test

ENTRYPOINT ["sh"]