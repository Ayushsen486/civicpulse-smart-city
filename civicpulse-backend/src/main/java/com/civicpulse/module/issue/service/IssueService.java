package com.civicpulse.module.issue.service;

import com.civicpulse.common.exception.BadRequestException;
import com.civicpulse.common.exception.ForbiddenException;
import com.civicpulse.common.exception.ResourceNotFoundException;
import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import com.civicpulse.module.category.repository.CategoryRepository;
import com.civicpulse.module.intelligence.service.IssueIntelligenceService;
import com.civicpulse.module.issue.dto.*;
import com.civicpulse.module.issue.entity.*;
import com.civicpulse.module.issue.repository.*;
import com.civicpulse.module.user.entity.User;
import com.civicpulse.module.user.entity.UserRole;
import com.civicpulse.module.user.repository.UserRepository;
import com.civicpulse.module.ward.entity.Ward;
import com.civicpulse.module.ward.repository.WardRepository;
import com.civicpulse.module.notification.service.NotificationService;
import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class IssueService {

    private final IssueRepository issueRepository;
    private final IssueAttachmentRepository attachmentRepository;
    private final IssueCommentRepository commentRepository;
    private final IssueUpvoteRepository upvoteRepository;
    private final IssueTimelineEventRepository timelineEventRepository;
    private final IssueAssignmentRepository assignmentRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final WardRepository wardRepository;
    private final IssueStateMachine stateMachine;
    private final FileStorageService fileStorageService;
    private IssueIntelligenceService intelligenceService;
    private NotificationService notificationService;

    private final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);

    public IssueService(
            IssueRepository issueRepository,
            IssueAttachmentRepository attachmentRepository,
            IssueCommentRepository commentRepository,
            IssueUpvoteRepository upvoteRepository,
            IssueTimelineEventRepository timelineEventRepository,
            IssueAssignmentRepository assignmentRepository,
            UserRepository userRepository,
            CategoryRepository categoryRepository,
            WardRepository wardRepository,
            IssueStateMachine stateMachine,
            FileStorageService fileStorageService
    ) {
        this.issueRepository = issueRepository;
        this.attachmentRepository = attachmentRepository;
        this.commentRepository = commentRepository;
        this.upvoteRepository = upvoteRepository;
        this.timelineEventRepository = timelineEventRepository;
        this.assignmentRepository = assignmentRepository;
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
        this.wardRepository = wardRepository;
        this.stateMachine = stateMachine;
        this.fileStorageService = fileStorageService;
    }

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    public void setIntelligenceService(IssueIntelligenceService intelligenceService) {
        this.intelligenceService = intelligenceService;
    }

    @org.springframework.beans.factory.annotation.Autowired(required = false)
    public void setNotificationService(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @Transactional
    public IssueResponse createIssue(CreateIssueRequest request, UUID reporterId) {
        User reporter = userRepository.findByIdAndDeletedAtIsNull(reporterId)
                .orElseThrow(() -> new ResourceNotFoundException("Reporter not found: " + reporterId));

        Category category = categoryRepository.findById(request.categoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found: " + request.categoryId()));

        validateCoordinates(request.latitude(), request.longitude());
        Point location = geometryFactory.createPoint(new Coordinate(request.longitude(), request.latitude()));

        // Spatial reverse-lookup for administrative ward jurisdiction
        Optional<Ward> matchedWard = wardRepository.findWardContainingPoint(request.latitude(), request.longitude());

        Priority priority = request.priority() != null ? request.priority() : category.getDefaultPriority();
        double priorityScore = computePriorityScore(priority);

        int slaHours = category.getSlaHoursOverride() != null ? category.getSlaHoursOverride() : 72;
        Instant slaDeadline = Instant.now().plus(slaHours, ChronoUnit.HOURS);

        Issue issue = new Issue();
        issue.setTitle(request.title().trim());
        issue.setDescription(request.description() != null ? request.description().trim() : null);
        issue.setStatus(IssueStatus.REPORTED);
        issue.setPriority(priority);
        issue.setPriorityScore(priorityScore);
        issue.setCategory(category);
        issue.setReporter(reporter);
        matchedWard.ifPresent(issue::setWard);
        issue.setLocation(location);
        issue.setAddress(request.address());
        issue.setLandmark(request.landmark());
        issue.setSlaDeadline(slaDeadline);
        issue.setIssueReference(generateReference());

        Issue savedIssue = issueRepository.save(issue);

        // Record initial timeline event
        recordTimelineEvent(savedIssue, reporter, TimelineEventType.CREATED, null, IssueStatus.REPORTED.name(), "Issue reported by citizen");

        // Non-blocking automated intelligence analysis (Phase 3)
        if (intelligenceService != null) {
            try {
                intelligenceService.analyzeSilently(savedIssue);
            } catch (Exception ignored) {
                // Guaranteed non-blocking: provider failure does not break issue reporting
            }
        }

        return IssueResponse.fromEntity(savedIssue);
    }

    @Transactional(readOnly = true)
    public IssueResponse getIssueById(UUID id, UUID currentUserId) {
        Issue issue = findActiveIssueById(id);
        boolean hasUpvoted = currentUserId != null && upvoteRepository.existsByIdIssueIdAndIdUserId(id, currentUserId);
        List<AttachmentResponse> attachments = attachmentRepository.findAllByIssueIdOrderByCreatedAtAsc(id).stream()
                .map(AttachmentResponse::fromEntity)
                .toList();

        return IssueResponse.fromEntity(issue, hasUpvoted, null, attachments);
    }

    @Transactional(readOnly = true)
    public Page<IssueResponse> listIssues(
            IssueStatus status,
            Priority priority,
            UUID categoryId,
            UUID wardId,
            UUID reporterId,
            UUID officerId,
            Pageable pageable
    ) {
        Specification<Issue> spec = (root, query, cb) -> {
            var predicate = cb.conjunction();
            predicate = cb.and(predicate, cb.isNull(root.get("deletedAt")));

            if (status != null) {
                predicate = cb.and(predicate, cb.equal(root.get("status"), status));
            }
            if (priority != null) {
                predicate = cb.and(predicate, cb.equal(root.get("priority"), priority));
            }
            if (categoryId != null) {
                predicate = cb.and(predicate, cb.equal(root.get("category").get("id"), categoryId));
            }
            if (wardId != null) {
                predicate = cb.and(predicate, cb.equal(root.get("ward").get("id"), wardId));
            }
            if (reporterId != null) {
                predicate = cb.and(predicate, cb.equal(root.get("reporter").get("id"), reporterId));
            }
            if (officerId != null) {
                predicate = cb.and(predicate, cb.equal(root.get("assignedOfficer").get("id"), officerId));
            }
            return predicate;
        };

        return issueRepository.findAll(spec, pageable).map(IssueResponse::fromEntity);
    }

    @Transactional
    public IssueResponse updateIssue(UUID id, UpdateIssueRequest request, UUID actorId, UserRole role) {
        Issue issue = findActiveIssueById(id);

        if (role == UserRole.CITIZEN) {
            if (!issue.getReporter().getId().equals(actorId)) {
                throw new ForbiddenException("You can only edit your own reported issues");
            }
            if (issue.getStatus() != IssueStatus.REPORTED && issue.getStatus() != IssueStatus.PENDING) {
                throw new BadRequestException("Citizens can only edit issues while in REPORTED status");
            }
        }

        if (request.title() != null && !request.title().isBlank()) {
            issue.setTitle(request.title().trim());
        }
        if (request.description() != null) {
            issue.setDescription(request.description().trim());
        }
        if (request.priority() != null) {
            if (role == UserRole.CITIZEN) {
                throw new ForbiddenException("Citizens cannot modify issue priority");
            }
            issue.setPriority(request.priority());
            issue.setPriorityScore(computePriorityScore(request.priority()));
        }
        if (request.address() != null) {
            issue.setAddress(request.address().trim());
        }
        if (request.landmark() != null) {
            issue.setLandmark(request.landmark().trim());
        }

        Issue updated = issueRepository.save(issue);
        User actor = userRepository.findByIdAndDeletedAtIsNull(actorId).orElse(null);
        recordTimelineEvent(updated, actor, TimelineEventType.DETAILS_UPDATED, null, null, "Issue details updated");

        return IssueResponse.fromEntity(updated);
    }

    @Transactional
    public IssueResponse updateStatus(UUID id, UpdateStatusRequest request, UUID actorId) {
        Issue issue = findActiveIssueById(id);
        User actor = userRepository.findByIdAndDeletedAtIsNull(actorId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + actorId));

        IssueStatus currentStatus = issue.getStatus();
        IssueStatus targetStatus = request.status();

        stateMachine.validateTransition(issue, targetStatus, actor);

        issue.setStatus(targetStatus);
        Instant now = Instant.now();

        if (targetStatus == IssueStatus.RESOLVED) {
            issue.setResolvedAt(now);
        } else if (targetStatus == IssueStatus.CLOSED) {
            issue.setClosedAt(now);
        } else if (targetStatus == IssueStatus.REOPENED) {
            issue.setReopenedAt(now);
            issue.setReopenedBy(actor);
        }

        Issue updated = issueRepository.save(issue);

        TimelineEventType eventType = stateMachine.determineEventType(targetStatus);
        recordTimelineEvent(updated, actor, eventType, currentStatus.name(), targetStatus.name(), request.remarks());

        if (notificationService != null) {
            try {
                notificationService.createNotification(
                        updated.getReporter(),
                        "Status Updated: " + targetStatus.name(),
                        "Your complaint #" + updated.getIssueReference() + " status is now " + targetStatus.name() + (request.remarks() != null && !request.remarks().isBlank() ? ". Note: " + request.remarks() : "."),
                        "STATUS_CHANGE",
                        "ISSUE",
                        updated.getId()
                );
                if (updated.getAssignedOfficer() != null && !updated.getAssignedOfficer().getId().equals(actor.getId())) {
                    notificationService.createNotification(
                            updated.getAssignedOfficer(),
                            "Status Updated: " + targetStatus.name(),
                            "Complaint #" + updated.getIssueReference() + " status updated to " + targetStatus.name(),
                            "STATUS_CHANGE",
                            "ISSUE",
                            updated.getId()
                    );
                }
            } catch (Exception ignored) {}
        }

        return IssueResponse.fromEntity(updated);
    }

    @Transactional
    public IssueResponse assignOfficer(UUID id, AssignIssueRequest request, UUID actorId) {
        Issue issue = findActiveIssueById(id);
        User actor = userRepository.findByIdAndDeletedAtIsNull(actorId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + actorId));

        if (actor.getRole() != UserRole.SUPERVISOR && actor.getRole() != UserRole.ADMIN) {
            throw new ForbiddenException("Only supervisors and admins can assign field officers");
        }

        User officer = userRepository.findByIdAndDeletedAtIsNull(request.officerId())
                .orElseThrow(() -> new ResourceNotFoundException("Officer not found: " + request.officerId()));

        if (officer.getRole() != UserRole.OFFICER) {
            throw new BadRequestException("Selected user is not a field officer");
        }

        // Deactivate previous assignment if present
        assignmentRepository.findFirstByIssueIdAndIsCurrentTrue(id).ifPresent(prev -> {
            prev.setCurrent(false);
            prev.setUnassignedAt(Instant.now());
            assignmentRepository.save(prev);
        });

        // Create new assignment ledger record
        IssueAssignment assignment = new IssueAssignment();
        assignment.setIssue(issue);
        assignment.setOfficer(officer);
        assignment.setAssignedBy(actor);
        assignment.setAssignedAt(Instant.now());
        assignment.setCurrent(true);
        assignmentRepository.save(assignment);

        String previousOfficer = issue.getAssignedOfficer() != null
                ? issue.getAssignedOfficer().getFirstName() + " " + issue.getAssignedOfficer().getLastName()
                : "None";
        String newOfficer = officer.getFirstName() + " " + officer.getLastName();

        issue.setAssignedOfficer(officer);
        if (issue.getStatus() == IssueStatus.REPORTED || issue.getStatus() == IssueStatus.PENDING || issue.getStatus() == IssueStatus.ACKNOWLEDGED) {
            issue.setStatus(IssueStatus.ASSIGNED);
        }

        Issue updated = issueRepository.save(issue);

        recordTimelineEvent(
                updated,
                actor,
                TimelineEventType.ASSIGNED,
                previousOfficer,
                newOfficer,
                request.remarks() != null ? request.remarks() : "Assigned to " + newOfficer
        );

        if (notificationService != null) {
            try {
                notificationService.createNotification(
                        officer,
                        "New Complaint Assigned",
                        "You have been assigned complaint #" + updated.getIssueReference() + ": " + updated.getTitle(),
                        "ASSIGNMENT",
                        "ISSUE",
                        updated.getId()
                );
                notificationService.createNotification(
                        updated.getReporter(),
                        "Officer Assigned",
                        "Your complaint #" + updated.getIssueReference() + " has been assigned to field officer " + newOfficer + ".",
                        "STATUS_CHANGE",
                        "ISSUE",
                        updated.getId()
                );
            } catch (Exception ignored) {}
        }

        return IssueResponse.fromEntity(updated);
    }

    @Transactional(readOnly = true)
    public List<IssueResponse> getNearbyIssues(double lat, double lng, double radiusMeters, int limit, UUID currentUserId) {
        validateCoordinates(lat, lng);
        double safeRadius = Math.max(10.0, Math.min(radiusMeters, 50000.0)); // Cap between 10m and 50km
        int safeLimit = Math.max(1, Math.min(limit, 100));

        List<Issue> nearby = issueRepository.findNearbyIssues(lat, lng, safeRadius, safeLimit);

        return nearby.stream().map(issue -> {
            boolean hasUpvoted = currentUserId != null && upvoteRepository.existsByIdIssueIdAndIdUserId(issue.getId(), currentUserId);
            double dist = computeHaversineDistance(lat, lng, issue.getLocation().getY(), issue.getLocation().getX());
            return IssueResponse.fromEntity(issue, hasUpvoted, dist, null);
        }).toList();
    }

    @Transactional
    public void upvoteIssue(UUID issueId, UUID userId) {
        Issue issue = findActiveIssueById(issueId);
        User user = userRepository.findByIdAndDeletedAtIsNull(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + userId));

        if (!upvoteRepository.existsByIdIssueIdAndIdUserId(issueId, userId)) {
            IssueUpvote upvote = new IssueUpvote(issue, user);
            upvoteRepository.save(upvote);

            issue.setUpvoteCount(issue.getUpvoteCount() + 1);
            issueRepository.save(issue);

            recordTimelineEvent(issue, user, TimelineEventType.UPVOTED, null, null, "Issue upvoted");
        }
    }

    @Transactional
    public void removeUpvote(UUID issueId, UUID userId) {
        Issue issue = findActiveIssueById(issueId);
        if (upvoteRepository.existsByIdIssueIdAndIdUserId(issueId, userId)) {
            upvoteRepository.deleteByIdIssueIdAndIdUserId(issueId, userId);

            issue.setUpvoteCount(Math.max(0, issue.getUpvoteCount() - 1));
            issueRepository.save(issue);
        }
    }

    @Transactional
    public CommentResponse addComment(UUID issueId, CreateCommentRequest request, UUID authorId) {
        Issue issue = findActiveIssueById(issueId);
        User author = userRepository.findByIdAndDeletedAtIsNull(authorId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + authorId));

        boolean isInternal = Boolean.TRUE.equals(request.isInternal());
        if (isInternal && author.getRole() == UserRole.CITIZEN) {
            throw new ForbiddenException("Citizens cannot author internal municipal notes");
        }

        String commentBody = request.getResolvedBody();
        if (commentBody.isBlank()) {
            throw new BadRequestException("Comment body cannot be blank");
        }

        IssueComment comment = new IssueComment();
        comment.setIssue(issue);
        comment.setAuthor(author);
        comment.setBody(commentBody);
        comment.setInternal(isInternal);

        IssueComment saved = commentRepository.save(comment);

        issue.setCommentCount(issue.getCommentCount() + 1);
        issueRepository.save(issue);

        recordTimelineEvent(issue, author, TimelineEventType.COMMENT_ADDED, null, null, isInternal ? "Internal note added" : "Public comment added");

        if (notificationService != null && !isInternal) {
            try {
                if (!author.getId().equals(issue.getReporter().getId())) {
                    notificationService.createNotification(
                            issue.getReporter(),
                            "New Comment",
                            author.getFirstName() + " commented on your complaint #" + issue.getIssueReference(),
                            "COMMENT",
                            "ISSUE",
                            issue.getId()
                    );
                }
                if (issue.getAssignedOfficer() != null && !author.getId().equals(issue.getAssignedOfficer().getId())) {
                    notificationService.createNotification(
                            issue.getAssignedOfficer(),
                            "New Comment",
                            author.getFirstName() + " commented on complaint #" + issue.getIssueReference(),
                            "COMMENT",
                            "ISSUE",
                            issue.getId()
                    );
                }
            } catch (Exception ignored) {}
        }

        return CommentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<CommentResponse> getComments(UUID issueId, UserRole callerRole) {
        findActiveIssueById(issueId); // verify exists

        List<IssueComment> comments;
        if (callerRole == UserRole.CITIZEN) {
            comments = commentRepository.findAllByIssueIdAndIsInternalFalseAndDeletedAtIsNullOrderByCreatedAtAsc(issueId);
        } else {
            comments = commentRepository.findAllByIssueIdAndDeletedAtIsNullOrderByCreatedAtAsc(issueId);
        }

        return comments.stream().map(CommentResponse::fromEntity).toList();
    }

    @Transactional
    public AttachmentResponse addAttachment(
            UUID issueId,
            MultipartFile file,
            AttachmentType attachmentType,
            boolean isBefore,
            UUID uploaderId
    ) {
        Issue issue = findActiveIssueById(issueId);
        User uploader = userRepository.findByIdAndDeletedAtIsNull(uploaderId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found: " + uploaderId));

        String storageKey = fileStorageService.storeFile(file, "issues/" + issueId);
        String fileType = determineFileType(file.getContentType());

        IssueAttachment attachment = new IssueAttachment();
        attachment.setIssue(issue);
        attachment.setUploadedBy(uploader);
        attachment.setFileUrl("/api/v1/attachments/" + storageKey);
        attachment.setStorageKey(storageKey);
        attachment.setOriginalFilename(file.getOriginalFilename());
        attachment.setMimeType(file.getContentType());
        attachment.setFileType(fileType);
        attachment.setFileSize((int) file.getSize());
        attachment.setAttachmentType(attachmentType != null ? attachmentType : AttachmentType.REPORT);
        attachment.setBefore(isBefore);

        IssueAttachment saved = attachmentRepository.save(attachment);

        recordTimelineEvent(issue, uploader, TimelineEventType.ATTACHMENT_ADDED, null, saved.getFileUrl(), "Attachment uploaded: " + saved.getOriginalFilename());

        return AttachmentResponse.fromEntity(saved);
    }

    @Transactional(readOnly = true)
    public List<AttachmentResponse> getAttachments(UUID issueId) {
        findActiveIssueById(issueId);
        return attachmentRepository.findAllByIssueIdOrderByCreatedAtAsc(issueId).stream()
                .map(AttachmentResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<TimelineEventResponse> getTimeline(UUID issueId) {
        findActiveIssueById(issueId);
        return timelineEventRepository.findAllByIssueIdOrderByCreatedAtAsc(issueId).stream()
                .map(TimelineEventResponse::fromEntity)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<IssueResponse> getAssignedToMe(UUID officerId, Pageable pageable) {
        return issueRepository.findAllByAssignedOfficerIdAndDeletedAtIsNull(officerId, pageable)
                .map(IssueResponse::fromEntity);
    }

    @Transactional(readOnly = true)
    public IssueStatisticsResponse getStatistics() {
        long total = issueRepository.countByDeletedAtIsNull();
        long reported = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.REPORTED);
        long acknowledged = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.ACKNOWLEDGED);
        long assigned = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.ASSIGNED);
        long inProgress = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.IN_PROGRESS);
        long resolved = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.RESOLVED);
        long closed = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.CLOSED);
        long rejected = issueRepository.countByStatusAndDeletedAtIsNull(IssueStatus.REJECTED);
        long highPriority = issueRepository.countByPriorityAndDeletedAtIsNull(Priority.CRITICAL)
                + issueRepository.countByPriorityAndDeletedAtIsNull(Priority.HIGH);
        long slaBreached = issueRepository.countBySlaDeadlineBeforeAndStatusNotInAndDeletedAtIsNull(
                Instant.now(),
                List.of(IssueStatus.RESOLVED, IssueStatus.CLOSED, IssueStatus.REJECTED)
        );

        List<User> officers = userRepository.findAllByRoleAndDeletedAtIsNull(UserRole.OFFICER);
        List<OfficerWorkloadResponse> workloads = officers.stream().map(o -> {
            long activeCount = issueRepository.countByAssignedOfficerIdAndStatusInAndDeletedAtIsNull(
                    o.getId(),
                    List.of(IssueStatus.ASSIGNED, IssueStatus.IN_PROGRESS, IssueStatus.ACKNOWLEDGED)
            );
            long resolvedCount = issueRepository.countByAssignedOfficerIdAndStatusInAndDeletedAtIsNull(
                    o.getId(),
                    List.of(IssueStatus.RESOLVED, IssueStatus.CLOSED)
            );
            return new OfficerWorkloadResponse(
                    o.getId(),
                    o.getFirstName() + " " + o.getLastName(),
                    o.getEmail(),
                    activeCount,
                    resolvedCount
            );
        }).toList();

        return new IssueStatisticsResponse(
                total,
                reported,
                acknowledged,
                assigned,
                inProgress,
                resolved,
                closed,
                rejected,
                slaBreached,
                highPriority,
                workloads
        );
    }

    private Issue findActiveIssueById(UUID id) {
        return issueRepository.findByIdAndDeletedAtIsNull(id)
                .orElseThrow(() -> new ResourceNotFoundException("Issue not found with id: " + id));
    }

    private void recordTimelineEvent(
            Issue issue,
            User actor,
            TimelineEventType eventType,
            String oldValue,
            String newValue,
            String remarks
    ) {
        IssueTimelineEvent event = new IssueTimelineEvent();
        event.setIssue(issue);
        event.setActor(actor);
        event.setEventType(eventType);
        event.setOldValue(oldValue);
        event.setNewValue(newValue);
        event.setRemarks(remarks);
        timelineEventRepository.save(event);
    }

    private void validateCoordinates(double lat, double lng) {
        if (lat < -90.0 || lat > 90.0) {
            throw new BadRequestException("Latitude must be between -90 and 90, got: " + lat);
        }
        if (lng < -180.0 || lng > 180.0) {
            throw new BadRequestException("Longitude must be between -180 and 180, got: " + lng);
        }
    }

    private double computePriorityScore(Priority priority) {
        return switch (priority) {
            case CRITICAL -> 4.0;
            case HIGH -> 3.0;
            case MEDIUM -> 2.0;
            case LOW -> 1.0;
        };
    }

    private String generateReference() {
        int year = java.time.Year.now().getValue();
        String randomSuffix = UUID.randomUUID().toString().substring(0, 6).toUpperCase();
        return "ISS-" + year + "-" + randomSuffix;
    }

    private String determineFileType(String contentType) {
        if (contentType == null) return "DOCUMENT";
        if (contentType.startsWith("image/")) return "IMAGE";
        if (contentType.startsWith("video/")) return "VIDEO";
        return "DOCUMENT";
    }

    private double computeHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371000; // Radius of earth in meters
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return Math.round((R * c) * 100.0) / 100.0;
    }
}
