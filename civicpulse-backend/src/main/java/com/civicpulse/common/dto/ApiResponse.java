package com.civicpulse.common.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.Collections;
import java.util.List;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiResponse<T>(
    T data,
    ApiMeta meta,
    List<String> errors
) {
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(data, ApiMeta.now(), Collections.emptyList());
    }

    public static <T> ApiResponse<T> success(T data, PageMeta page) {
        return new ApiResponse<>(data, new ApiMeta(Instant.now(), page), Collections.emptyList());
    }

    public static <T> ApiResponse<T> error(List<String> errors) {
        return new ApiResponse<>(null, ApiMeta.now(), errors);
    }

    public static <T> ApiResponse<T> error(String error) {
        return new ApiResponse<>(null, ApiMeta.now(), List.of(error));
    }
}
