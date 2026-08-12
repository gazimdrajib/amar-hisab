# Cloud Sync Service image (Architecture Book §11.5).
# Multi-stage: builds a static binary, ships in a minimal runtime.

FROM golang:1.21-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" \
    -o /out/sync-server ./cmd/server

FROM gcr.io/distroless/static-debian12
COPY --from=build /out/sync-server /sync-server
EXPOSE 9090
ENV GRPC_ADDR=:9090
USER nonroot
ENTRYPOINT ["/sync-server"]
