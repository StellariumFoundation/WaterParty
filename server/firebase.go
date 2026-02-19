package main

import (
	"context"
	"log"
	"net/http"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

var firebaseAuth *auth.Client

func InitFirebase() {
	// If you have a service account key, use it. 
	// Otherwise, it will use Google Application Default Credentials.
	ctx := context.Background()
	
	var app *firebase.App
	var err error

	serviceAccountPath := getEnv("FIREBASE_SERVICE_ACCOUNT", "")
	if serviceAccountPath != "" {
		opt := option.WithCredentialsFile(serviceAccountPath)
		app, err = firebase.NewApp(ctx, nil, opt)
	} else {
		app, err = firebase.NewApp(ctx, nil)
	}

	if err != nil {
		log.Fatalf("error initializing app: %v\n", err)
	}

	firebaseAuth, err = app.Auth(ctx)
	if err != nil {
		log.Fatalf("error getting Auth client: %v\n", err)
	}
	log.Println("✅ Firebase Auth initialized")
}

// AuthMiddleware verifies the Firebase ID Token
func AuthMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// 1. Get token from Authorization header or Query param (for WS)
		idToken := r.Header.Get("Authorization")
		if idToken == "" {
			idToken = r.URL.Query().Get("token")
		}

		if idToken == "" {
			http.Error(w, "Unauthorized: No token provided", http.StatusUnauthorized)
			return
		}

		// Remove "Bearer " prefix if present
		idToken = strings.TrimPrefix(idToken, "Bearer ")

		// 2. Verify token with Firebase
		token, err := firebaseAuth.VerifyIDToken(r.Context(), idToken)
		if err != nil {
			log.Printf("error verifying ID token: %v\n", err)
			http.Error(w, "Unauthorized: Invalid token", http.StatusUnauthorized)
			return
		}

		// 3. Add UID to context
		ctx := context.WithValue(r.Context(), "uid", token.UID)
		next.ServeHTTP(w, r.WithContext(ctx))
	}
}
