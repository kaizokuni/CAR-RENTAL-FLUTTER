# Build Stage
FROM golang:1.24 AS builder

WORKDIR /app

# Debian based image has git pre-installed usually, or we can install it via apt if needed.
# golang:1.21 comes with git.

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/main.go

# Run Stage
FROM gcr.io/distroless/static-debian12

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Copy the internal directory to include schema.sql
COPY --from=builder /app/internal ./internal

EXPOSE 8080

CMD ["./main"]
