# Build Stage
FROM golang:1.24 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o main ./cmd/api/main.go

# Create uploads directory in builder stage (distroless doesn't have mkdir/chmod)
RUN mkdir -p uploads && chmod 777 uploads

# Run Stage
FROM gcr.io/distroless/static-debian12

WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /app/main .

# Copy the internal directory to include schema.sql
COPY --from=builder /app/internal ./internal

# Copy empty uploads directory from builder
COPY --from=builder /app/uploads ./uploads

EXPOSE 8080

CMD ["./main"]
