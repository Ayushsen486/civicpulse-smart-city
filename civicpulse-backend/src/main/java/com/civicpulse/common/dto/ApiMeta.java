package com.civicpulse.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiMeta(
    Instant timestamp,
    PageMeta page
) {
    public static ApiMeta now() {
        return new ApiMeta(Instant.now(), null);
    }
}
