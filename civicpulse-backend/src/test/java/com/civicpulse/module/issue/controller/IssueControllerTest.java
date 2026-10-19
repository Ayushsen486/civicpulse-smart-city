package com.civicpulse.module.issue.controller;

import com.civicpulse.common.exception.GlobalExceptionHandler;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.issue.dto.*;
import com.civicpulse.module.issue.entity.IssueStatus;
import com.civicpulse.module.issue.service.IssueService;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.security.CustomUserDetails;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.core.MethodParameter;
import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class IssueControllerTest {

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private IssueService issueService;

    @InjectMocks
    private IssueController issueController;

    private CustomUserDetails mockUserDetails;
    private IssueResponse mockResponse;

    @BeforeEach
    void setUp() {
        User user = new User();
        user.setId(UUID.randomUUID());
        user.setEmail("citizen@civicpulse.city");
        user.setPasswordHash("hash");
        user.setRole(UserRole.CITIZEN);
        user.setActive(true);
        mockUserDetails = new CustomUserDetails(user);

        mockResponse = new IssueResponse(
                UUID.randomUUID(),
                1001,
                "ISS-2026-0001",
                "Pothole on Main St",
                "Deep pothole near junction",
                IssueStatus.REPORTED,
                Priority.HIGH,
                3.0,
                UUID.randomUUID(),
                "Roads",
                "road",
                "#EF4444",
                mockUserDetails.getId(),
                "Rohan Sharma",
                null,
                null,
                UUID.randomUUID(),
                "Central Ward",
                28.61,
                77.21,
                "Main St",
                null,
                0,
                0,
                false,
                null,
                Instant.now().plusSeconds(86400),
                false,
                false,
                null,
                null,
                null,
                null,
                Instant.now(),
                Instant.now(),
                Collections.emptyList()
        );

        // Custom argument resolver to inject mockUserDetails for @AuthenticationPrincipal
        HandlerMethodArgumentResolver authPrincipalResolver = new HandlerMethodArgumentResolver() {
            @Override
            public boolean supportsParameter(MethodParameter parameter) {
                return parameter.hasParameterAnnotation(AuthenticationPrincipal.class);
            }

            @Override
            public Object resolveArgument(MethodParameter parameter, ModelAndViewContainer mavContainer, NativeWebRequest webRequest, WebDataBinderFactory binderFactory) {
                return mockUserDetails;
            }
        };

        mockMvc = MockMvcBuilders.standaloneSetup(issueController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .setCustomArgumentResolvers(authPrincipalResolver)
                .build();
    }

    @Test
    @DisplayName("POST /api/v1/issues: creates new issue and returns 201 Created")
    void createIssue_Returns201() throws Exception {
        CreateIssueRequest request = new CreateIssueRequest(
                "Pothole on Main St",
                "Deep pothole near junction",
                mockResponse.categoryId(),
                Priority.HIGH,
                28.61,
                77.21,
                "Main St",
                null
        );

        when(issueService.createIssue(any(CreateIssueRequest.class), eq(mockUserDetails.getId())))
                .thenReturn(mockResponse);

        mockMvc.perform(post("/api/v1/issues")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.title").value("Pothole on Main St"))
                .andExpect(jsonPath("$.data.status").value("REPORTED"))
                .andExpect(jsonPath("$.data.latitude").value(28.61))
                .andExpect(jsonPath("$.data.longitude").value(77.21))
                .andExpect(jsonPath("$.meta").exists());
    }

    @Test
    @DisplayName("GET /api/v1/issues/{id}: returns issue details")
    void getIssueById_Returns200() throws Exception {
        when(issueService.getIssueById(eq(mockResponse.id()), eq(mockUserDetails.getId())))
                .thenReturn(mockResponse);

        mockMvc.perform(get("/api/v1/issues/{id}", mockResponse.id()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(mockResponse.id().toString()))
                .andExpect(jsonPath("$.data.issueReference").value("ISS-2026-0001"));
    }

    @Test
    @DisplayName("GET /api/v1/issues/nearby: returns nearby issues")
    void getNearbyIssues_Returns200() throws Exception {
        when(issueService.getNearbyIssues(eq(28.61), eq(77.21), eq(1000.0), eq(20), eq(mockUserDetails.getId())))
                .thenReturn(List.of(mockResponse));

        mockMvc.perform(get("/api/v1/issues/nearby")
                        .param("lat", "28.61")
                        .param("lng", "77.21")
                        .param("radius", "1000"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].title").value("Pothole on Main St"));
    }

    @Test
    @DisplayName("PATCH /api/v1/issues/{id}/status: updates status")
    void updateStatus_Returns200() throws Exception {
        UpdateStatusRequest request = new UpdateStatusRequest(IssueStatus.ACKNOWLEDGED, "Under review");
        when(issueService.updateStatus(eq(mockResponse.id()), any(UpdateStatusRequest.class), eq(mockUserDetails.getId())))
                .thenReturn(mockResponse);

        mockMvc.perform(patch("/api/v1/issues/{id}/status", mockResponse.id())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());
    }

    @Test
    @DisplayName("POST /api/v1/issues/{id}/upvote: adds upvote successfully")
    void upvote_Returns200() throws Exception {
        mockMvc.perform(post("/api/v1/issues/{id}/upvote", mockResponse.id()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.message").value("Upvoted successfully"));
    }
}
