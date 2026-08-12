// Package auth implements device authentication for the SyncService.
//
// Two mechanisms (Proto Contract Book §4.1):
//   - mTLS: the device presents a client certificate registered in
//     `device_registry.public_key` (verified at the TLS layer; the handler
//     additionally checks authorization state).
//   - Device JWT: `authorization: Bearer <jwt>` metadata, signed HS256 with
//     the per-device secret stored in `devices.jwt_secret`. Claims:
//     `device_id`, `business_id`, `exp`.
package auth

import (
	"errors"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

// DeviceClaims are the JWT claims the local server sends.
type DeviceClaims struct {
	DeviceID   string `json:"device_id"`
	BusinessID int64  `json:"business_id"`
	jwt.RegisteredClaims
}

// ErrUnauthorized is returned for any authentication / authorization failure.
var ErrUnauthorized = errors.New("unauthorized device")

// ParseBearer extracts and validates the device JWT.
// Returns (deviceID, businessID, error).
func ParseBearer(header string, secretLookup func(deviceID string) (int64, string, bool, error)) (string, int64, error) {
	if !strings.HasPrefix(strings.ToLower(header), "bearer ") {
		return "", 0, ErrUnauthorized
	}
	tokenString := strings.TrimSpace(header[len("bearer "):])

	// Peek at the unverified claims to learn the device_id, then verify
	// against that device's secret.
	claims := &DeviceClaims{}
	_, _, err := jwt.NewParser().ParseUnverified(tokenString, claims)
	if err != nil || claims.DeviceID == "" {
		return "", 0, ErrUnauthorized
	}

	businessID, secret, authorized, err := secretLookup(claims.DeviceID)
	if err != nil || !authorized || secret == "" {
		return "", 0, ErrUnauthorized
	}

	parsed, err := jwt.ParseWithClaims(tokenString, claims,
		func(t *jwt.Token) (any, error) {
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, ErrUnauthorized
			}
			return []byte(secret), nil
		},
		jwt.WithLeeway(30), // seconds of clock skew
	)
	if err != nil || parsed == nil || !parsed.Valid {
		return "", 0, ErrUnauthorized
	}
	if claims.BusinessID != businessID {
		return "", 0, ErrUnauthorized
	}
	// RegisteredClaims.Valid() via jwt.ParseWithClaims already checks exp.
	return claims.DeviceID, businessID, nil
}
