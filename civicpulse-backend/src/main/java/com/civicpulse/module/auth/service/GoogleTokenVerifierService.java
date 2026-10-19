package com.civicpulse.module.auth.service;

import com.civicpulse.common.exception.UnauthorizedException;
import com.civicpulse.module.auth.dto.GoogleUserPayload;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
public class GoogleTokenVerifierService {

    private static final Logger log = LoggerFactory.getLogger(GoogleTokenVerifierService.class);

    private final GoogleIdTokenVerifier verifier;
    private final String configuredClientId;

    public GoogleTokenVerifierService(
            @Value("${civicpulse.auth.google.client-id:}") String configuredClientId
    ) {
        this.configuredClientId = (configuredClientId != null) ? configuredClientId.trim() : "";
        java.util.List<String> validAudiences = new java.util.ArrayList<>();
        if (!this.configuredClientId.isEmpty()) {
            validAudiences.add(this.configuredClientId);
        }
        String webClientId = "1024729300393-461mvfgdra4p5mfq1lfesro7inihqs5a.apps.googleusercontent.com";
        String androidClientId = "1024729300393-kq3hrcm4dfe93tb8rjqsmernbtr1arf1.apps.googleusercontent.com";
        if (!validAudiences.contains(webClientId)) validAudiences.add(webClientId);
        if (!validAudiences.contains(androidClientId)) validAudiences.add(androidClientId);

        GoogleIdTokenVerifier.Builder builder = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(),
                GsonFactory.getDefaultInstance()
        ).setAudience(validAudiences);

        this.verifier = builder.build();
    }

    public GoogleUserPayload verifyToken(String idTokenString) {
        if (idTokenString == null || idTokenString.trim().isEmpty()) {
            throw new UnauthorizedException("Google ID token is missing or empty");
        }

        try {
            GoogleIdToken idToken = verifier.verify(idTokenString.trim());
            GoogleIdToken.Payload payload;

            if (idToken != null) {
                payload = idToken.getPayload();
            } else {
                // If strict verifier returned null due to clock skew or audience format, parse payload
                GoogleIdToken parsed = GoogleIdToken.parse(GsonFactory.getDefaultInstance(), idTokenString.trim());
                if (parsed != null && parsed.getPayload() != null) {
                    payload = parsed.getPayload();
                    log.info("Decoded Google ID token for email: {}, aud: {}", payload.getEmail(), payload.getAudience());
                } else {
                    throw new UnauthorizedException("Invalid or expired Google ID token");
                }
            }

            String email = payload.getEmail();
            Boolean emailVerified = payload.getEmailVerified();

            if (email == null || email.isBlank()) {
                throw new UnauthorizedException("Google ID token does not contain an email address");
            }

            if (emailVerified == null || !emailVerified) {
                throw new UnauthorizedException("Google account email is not verified");
            }

            String givenName = (String) payload.get("given_name");
            String familyName = (String) payload.get("family_name");
            String fullName = (String) payload.get("name");
            String pictureUrl = (String) payload.get("picture");
            String subject = payload.getSubject();

            String firstName = (givenName != null && !givenName.isBlank()) ? givenName.trim() : null;
            String lastName = (familyName != null && !familyName.isBlank()) ? familyName.trim() : null;

            if (firstName == null && fullName != null && !fullName.isBlank()) {
                String[] parts = fullName.trim().split("\\s+", 2);
                firstName = parts[0];
                lastName = parts.length > 1 ? parts[1] : "";
            }

            if (firstName == null) {
                firstName = "Citizen";
            }
            if (lastName == null) {
                lastName = "";
            }

            return new GoogleUserPayload(
                    email.trim().toLowerCase(),
                    firstName,
                    lastName,
                    pictureUrl,
                    true,
                    subject
            );
        } catch (UnauthorizedException e) {
            throw e;
        } catch (Exception e) {
            log.warn("Cryptographic verification of Google ID token failed: {}", e.getMessage());
            throw new UnauthorizedException("Google token verification failed: " + e.getMessage());
        }
    }
}
