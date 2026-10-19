package com.civicpulse.module.intelligence.provider;

import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class RuleBasedIntelligenceProviderTest {

    private RuleBasedIntelligenceProvider provider;
    private List<Category> sampleCategories;

    @BeforeEach
    void setUp() {
        provider = new RuleBasedIntelligenceProvider();

        Category roads = new Category();
        roads.setId(UUID.randomUUID());
        roads.setName("Roads & Traffic");
        roads.setSlug("roads-traffic");
        roads.setDefaultPriority(Priority.MEDIUM);

        Category potholes = new Category();
        potholes.setId(UUID.randomUUID());
        potholes.setName("Potholes");
        potholes.setSlug("potholes");
        potholes.setDefaultPriority(Priority.HIGH);
        potholes.setParent(roads);

        Category sanitation = new Category();
        sanitation.setId(UUID.randomUUID());
        sanitation.setName("Sanitation & Waste");
        sanitation.setSlug("sanitation-waste");
        sanitation.setDefaultPriority(Priority.MEDIUM);

        Category garbageDump = new Category();
        garbageDump.setId(UUID.randomUUID());
        garbageDump.setName("Garbage Dump");
        garbageDump.setSlug("garbage-dump");
        garbageDump.setDefaultPriority(Priority.MEDIUM);
        garbageDump.setParent(sanitation);

        Category waterSupply = new Category();
        waterSupply.setId(UUID.randomUUID());
        waterSupply.setName("Water Supply");
        waterSupply.setSlug("water-supply");
        waterSupply.setDefaultPriority(Priority.HIGH);

        Category waterLeak = new Category();
        waterLeak.setId(UUID.randomUUID());
        waterLeak.setName("Water Pipe Leak");
        waterLeak.setSlug("water-pipe-leak");
        waterLeak.setDefaultPriority(Priority.HIGH);
        waterLeak.setParent(waterSupply);

        Category lighting = new Category();
        lighting.setId(UUID.randomUUID());
        lighting.setName("Street Lighting");
        lighting.setSlug("street-lighting");
        lighting.setDefaultPriority(Priority.MEDIUM);

        Category brokenStreetlight = new Category();
        brokenStreetlight.setId(UUID.randomUUID());
        brokenStreetlight.setName("Broken Streetlight");
        brokenStreetlight.setSlug("broken-streetlight");
        brokenStreetlight.setDefaultPriority(Priority.MEDIUM);
        brokenStreetlight.setParent(lighting);

        Category parks = new Category();
        parks.setId(UUID.randomUUID());
        parks.setName("Public Parks");
        parks.setSlug("public-parks");
        parks.setDefaultPriority(Priority.LOW);

        sampleCategories = List.of(
                roads, potholes,
                sanitation, garbageDump,
                waterSupply, waterLeak,
                lighting, brokenStreetlight,
                parks
        );
    }

    @Test
    @DisplayName("Should suggest Potholes category and Roads department for road damage reports")
    void shouldSuggestPotholeCategoryAndRoadsDepartment() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Deep pothole on arterial road",
                "Large crater on asphalt tarmac causing traffic congestion",
                null, null, null,
                "Central Ward", "WARD-01",
                28.61, 77.20,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.suggestedCategoryName()).containsAnyOf("Potholes", "Roads & Traffic");
        assertThat(result.recommendedDepartment()).contains("Roads & Public Works Department");
        assertThat(result.recommendedDepartment()).contains("WARD-01");
        assertThat(result.categoryConfidence()).isGreaterThanOrEqualTo(0.80);
        assertThat(result.explanation()).contains("Categorized as");
    }

    @Test
    @DisplayName("Should suggest Garbage category and Sanitation department for waste overflow")
    void shouldSuggestSanitationForGarbageDump() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Piled up garbage dump",
                "Waste overflow and terrible stench in residential colony",
                null, null, null,
                "North Ward", "WARD-02",
                28.65, 77.22,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.suggestedCategoryName()).containsAnyOf("Garbage Dump", "Sanitation & Waste");
        assertThat(result.recommendedDepartment()).contains("Sanitation & Waste Management Department");
    }

    @Test
    @DisplayName("Should suggest Water Board for pipe burst and leak reports")
    void shouldSuggestWaterSupplyForPipeLeak() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Burst water pipe leak",
                "Drinking water supply pipeline gushing onto street",
                null, null, null,
                "South Ward", "WARD-03",
                28.58, 77.23,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.suggestedCategoryName()).containsAnyOf("Water Pipe Leak", "Water Supply");
        assertThat(result.recommendedDepartment()).contains("Water Supply & Sewerage Board");
    }

    @Test
    @DisplayName("Should suggest Electrical department for broken streetlights")
    void shouldSuggestElectricalForStreetlight() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Broken streetlight lamp post",
                "Total blackout due to flickering dark pole on lane 4",
                null, null, null,
                "West Ward", "WARD-05",
                28.63, 77.15,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.suggestedCategoryName()).containsAnyOf("Broken Streetlight", "Street Lighting");
        assertThat(result.recommendedDepartment()).contains("Electrical & Lighting Department");
    }

    @Test
    @DisplayName("Should assign CRITICAL priority when safety hazard is combined with scale or urgency")
    void shouldEscalateToCriticalWhenSafetyHazardCombinedWithScaleOrUrgency() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Live wire sparking near school",
                "Immediate danger of electric shock on main road intersection",
                null, null, null,
                "Central Ward", "WARD-01",
                28.61, 77.21,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.suggestedPriority()).isEqualTo(Priority.CRITICAL);
        assertThat(result.needsHumanReview()).isTrue();
        assertThat(result.explanation()).contains("CRITICAL");
        assertThat(result.factors()).containsKey("safetySignals");
    }

    @Test
    @DisplayName("Should assign HIGH (not unverified CRITICAL) when safety keyword appears alone without scale")
    void shouldEscalateToHighWhenSafetyHazardAppearsAloneWithoutScale() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Open manhole observed",
                "Cover missing on small back lane",
                null, null, null,
                "Central Ward", "WARD-01",
                28.61, 77.21,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        // Prevents unverified critical false alarms per AGENTS.md / Phase 3 spec
        assertThat(result.suggestedPriority()).isEqualTo(Priority.HIGH);
        assertThat(result.needsHumanReview()).isTrue();
        assertThat(result.explanation()).contains("Safety risk detected");
    }

    @Test
    @DisplayName("Should suggest LOW priority for minor cosmetic issues")
    void shouldSuggestLowPriorityForCosmeticIssues() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Minor paint scratch on park bench",
                "Slight cosmetic fading in garden area",
                null, null, null,
                "East Ward", "WARD-04",
                28.60, 77.28,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.suggestedPriority()).isEqualTo(Priority.LOW);
    }

    @Test
    @DisplayName("Should flag uncertain issues with low confidence for human review")
    void shouldFlagUncertainCategoryForHumanReview() {
        IssueAnalysisContext context = new IssueAnalysisContext(
                "Vague unknown matter",
                "Something strange occurred please check",
                null, null, null,
                "Central Ward", "WARD-01",
                28.61, 77.21,
                sampleCategories
        );

        IssueAnalysisResult result = provider.analyze(context);

        assertThat(result.overallConfidence()).isLessThan(0.70);
        assertThat(result.needsHumanReview()).isTrue();
        assertThat(result.explanation()).contains("Marked for human triage");
    }
}
