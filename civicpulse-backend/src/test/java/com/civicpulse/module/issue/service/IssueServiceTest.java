package com.civicpulse.module.issue.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.category.repository.CategoryRepository;
import com.civicpulse.module.issue.dto.*;
import com.civicpulse.module.issue.entity.*;
import com.civicpulse.module.issue.repository.*;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.module.ward.entity.Ward;
import com.civicpulse.module.ward.repository.WardRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.PrecisionModel;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class IssueServiceTest {

    @Mock
    private IssueRepository issueRepository;
    @Mock
    private IssueAttachmentRepository attachmentRepository;
    @Mock
    private IssueCommentRepository commentRepository;
    @Mock
    private IssueUpvoteRepository upvoteRepository;
    @Mock
    private IssueTimelineEventRepository timelineEventRepository;
    @Mock
    private IssueAssignmentRepository assignmentRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private CategoryRepository categoryRepository;
    @Mock
    private WardRepository wardRepository;
    @Mock
    private IssueStateMachine stateMachine;
    @Mock
    private FileStorageService fileStorageService;
    @Mock
    private com.civicpulse.module.notification.service.NotificationService notificationService;

    @InjectMocks
    private IssueService issueService;

    private User citizen;
    private User officer;
    private User supervisor;
    private Category category;
    private Ward ward;
    private Issue sampleIssue;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    @BeforeEach
    void setUp() {
        citizen = new User();
        citizen.setId(UUID.randomUUID());
        citizen.setEmail("citizen@civicpulse.city");
        citizen.setFirstName("Rohan");
        citizen.setLastName("Sharma");
        citizen.setRole(UserRole.CITIZEN);

        officer = new User();
        officer.setId(UUID.randomUUID());
        officer.setEmail("officer@civicpulse.city");
        officer.setFirstName("Vikram");
        officer.setLastName("Singh");
        officer.setRole(UserRole.OFFICER);

        supervisor = new User();
        supervisor.setId(UUID.randomUUID());
        supervisor.setRole(UserRole.SUPERVISOR);

        category = new Category();
        category.setId(UUID.randomUUID());
        category.setName("Roads & Traffic");
        category.setSlug("roads");
        category.setDefaultPriority(Priority.MEDIUM);
        category.setSlaHoursOverride(48);

        ward = new Ward();
        ward.setId(UUID.randomUUID());
        ward.setName("Central Ward");
        ward.setCode("WARD-01");

        sampleIssue = new Issue();
        sampleIssue.setId(UUID.randomUUID());
        sampleIssue.setTitle("Deep pothole on MG Road");
        sampleIssue.setStatus(IssueStatus.REPORTED);
        sampleIssue.setPriority(Priority.HIGH);
        sampleIssue.setCategory(category);
        sampleIssue.setReporter(citizen);
        sampleIssue.setWard(ward);
        sampleIssue.setLocation(geometryFactory.createPoint(new Coordinate(77.21, 28.61)));
    }

    @Test
    @DisplayName("createIssue: creates issue with spatial point and ward association")
    void createIssue_Success() {
        CreateIssueRequest request = new CreateIssueRequest(
                "Deep pothole on MG Road",
                "Dangerous pothole near metro station",
                category.getId(),
                Priority.HIGH,
                28.61,
                77.21,
                "MG Road, Connaught Place",
                "Metro Gate 2"
        );

        when(userRepository.findByIdAndDeletedAtIsNull(citizen.getId())).thenReturn(Optional.of(citizen));
        when(categoryRepository.findById(category.getId())).thenReturn(Optional.of(category));
        when(wardRepository.findWardContainingPoint(28.61, 77.21)).thenReturn(Optional.of(ward));
        when(issueRepository.save(any(Issue.class))).thenAnswer(inv -> {
            Issue i = inv.getArgument(0);
            i.setId(UUID.randomUUID());
            return i;
        });

        IssueResponse response = issueService.createIssue(request, citizen.getId());

        assertThat(response).isNotNull();
        assertThat(response.title()).isEqualTo("Deep pothole on MG Road");
        assertThat(response.priority()).isEqualTo(Priority.HIGH);
        assertThat(response.wardName()).isEqualTo("Central Ward");
        assertThat(response.latitude()).isEqualTo(28.61);
        assertThat(response.longitude()).isEqualTo(77.21);
        assertThat(response.status()).isEqualTo(IssueStatus.REPORTED);

        verify(issueRepository).save(any(Issue.class));
        verify(timelineEventRepository).save(any(IssueTimelineEvent.class));
    }

    @Test
    @DisplayName("createIssue: throws BadRequestException on invalid coordinates")
    void createIssue_InvalidCoordinates_ThrowsBadRequest() {
        CreateIssueRequest request = new CreateIssueRequest(
                "Title", "Desc", category.getId(), Priority.LOW,
                95.0, // Invalid latitude > 90
                77.21, null, null
        );

        when(userRepository.findByIdAndDeletedAtIsNull(citizen.getId())).thenReturn(Optional.of(citizen));
        when(categoryRepository.findById(category.getId())).thenReturn(Optional.of(category));

        assertThatThrownBy(() -> issueService.createIssue(request, citizen.getId()))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Latitude must be between -90 and 90");
    }

    @Test
    @DisplayName("assignOfficer: supervisor assigns field officer and updates status to ASSIGNED")
    void assignOfficer_Success() {
        AssignIssueRequest request = new AssignIssueRequest(officer.getId(), "Dispatched for inspection");

        when(issueRepository.findByIdAndDeletedAtIsNull(sampleIssue.getId())).thenReturn(Optional.of(sampleIssue));
        when(userRepository.findByIdAndDeletedAtIsNull(supervisor.getId())).thenReturn(Optional.of(supervisor));
        when(userRepository.findByIdAndDeletedAtIsNull(officer.getId())).thenReturn(Optional.of(officer));
        when(issueRepository.save(any(Issue.class))).thenReturn(sampleIssue);

        IssueResponse response = issueService.assignOfficer(sampleIssue.getId(), request, supervisor.getId());

        assertThat(response).isNotNull();
        assertThat(sampleIssue.getAssignedOfficer()).isEqualTo(officer);
        assertThat(sampleIssue.getStatus()).isEqualTo(IssueStatus.ASSIGNED);

        verify(assignmentRepository).save(any(IssueAssignment.class));
        verify(timelineEventRepository).save(any(IssueTimelineEvent.class));
    }

    @Test
    @DisplayName("assignOfficer: forbidden when non-supervisor attempts dispatch")
    void assignOfficer_CitizenForbidden() {
        AssignIssueRequest request = new AssignIssueRequest(officer.getId(), "Dispatch");

        when(issueRepository.findByIdAndDeletedAtIsNull(sampleIssue.getId())).thenReturn(Optional.of(sampleIssue));
        when(userRepository.findByIdAndDeletedAtIsNull(citizen.getId())).thenReturn(Optional.of(citizen));

        assertThatThrownBy(() -> issueService.assignOfficer(sampleIssue.getId(), request, citizen.getId()))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Only supervisors and admins can assign field officers");
    }

    @Test
    @DisplayName("upvoteIssue: increments upvote count once")
    void upvoteIssue_Success() {
        when(issueRepository.findByIdAndDeletedAtIsNull(sampleIssue.getId())).thenReturn(Optional.of(sampleIssue));
        when(userRepository.findByIdAndDeletedAtIsNull(citizen.getId())).thenReturn(Optional.of(citizen));
        when(upvoteRepository.existsByIdIssueIdAndIdUserId(sampleIssue.getId(), citizen.getId())).thenReturn(false);

        issueService.upvoteIssue(sampleIssue.getId(), citizen.getId());

        assertThat(sampleIssue.getUpvoteCount()).isEqualTo(1);
        verify(upvoteRepository).save(any(IssueUpvote.class));
        verify(issueRepository).save(sampleIssue);
    }

    @Test
    @DisplayName("addComment: citizen cannot post internal operational note")
    void addComment_CitizenInternalNote_Forbidden() {
        CreateCommentRequest request = new CreateCommentRequest("Confidential note", true);

        when(issueRepository.findByIdAndDeletedAtIsNull(sampleIssue.getId())).thenReturn(Optional.of(sampleIssue));
        when(userRepository.findByIdAndDeletedAtIsNull(citizen.getId())).thenReturn(Optional.of(citizen));

        assertThatThrownBy(() -> issueService.addComment(sampleIssue.getId(), request, citizen.getId()))
                .isInstanceOf(ForbiddenException.class)
                .hasMessageContaining("Citizens cannot author internal municipal notes");
    }

    @Test
    @DisplayName("getNearbyIssues: calls PostGIS repository query with radius and coordinates")
    void getNearbyIssues_Success() {
        when(issueRepository.findNearbyIssues(eq(28.61), eq(77.21), eq(1000.0), eq(20)))
                .thenReturn(List.of(sampleIssue));

        List<IssueResponse> nearby = issueService.getNearbyIssues(28.61, 77.21, 1000.0, 20, citizen.getId());

        assertThat(nearby).hasSize(1);
        assertThat(nearby.get(0).title()).isEqualTo("Deep pothole on MG Road");
    }
}
