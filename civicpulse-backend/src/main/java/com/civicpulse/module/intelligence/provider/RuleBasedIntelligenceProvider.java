package com.civicpulse.module.intelligence.provider;

import com.civicpulse.module.category.entity.Category;
import com.civicpulse.module.category.entity.Priority;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class RuleBasedIntelligenceProvider implements IssueIntelligenceProvider {

    public static final String PROVIDER_NAME = "CivicPulse-RuleEngine";
    public static final String PROVIDER_VERSION = "1.0.0";

    // Category Keyword Dictionaries
    private static final Map<String, List<String>> CATEGORY_KEYWORDS = new LinkedHashMap<>();

    // Department Mapping by Category Slug Prefix / Keyword
    private static final Map<String, String> CATEGORY_DEPARTMENT_MAP = new LinkedHashMap<>();

    // Safety Hazard Signals
    private static final List<String> SAFETY_HAZARD_KEYWORDS = List.of(
            "gas leak", "live wire", "open manhole", "exposed cable", "electric shock",
            "fire", "sinkhole", "bridge collapse", "deep trench", "structural hazard",
            "hanging transformer", "electrocution", "sparking wire", "open drain"
    );

    // Public Scale / Disruption Signals
    private static final List<String> SCALE_DISRUPTION_KEYWORDS = List.of(
            "main road", "arterial road", "highway", "hospital", "school", "intersection",
            "entire locality", "ward-wide", "flooding", "hundreds of residents", "major traffic",
            "ambulance route", "subway", "bus stop"
    );

    // Urgency Signals
    private static final List<String> URGENCY_KEYWORDS = List.of(
            "immediate", "urgent", "danger", "accident", "injury", "emergency",
            "hazardous", "severe", "life threatening", "critical", "peril"
    );

    // Low Severity Signals
    private static final List<String> LOW_SEVERITY_KEYWORDS = List.of(
            "minor", "cosmetic", "small", "scratch", "faded", "paint", "informational",
            "trivial", "slight"
    );

    static {
        // Granular category keyword definitions
        CATEGORY_KEYWORDS.put("potholes", List.of("pothole", "crater", "road surface", "broken road", "rut", "bump"));
        CATEGORY_KEYWORDS.put("broken-footpath", List.of("footpath", "sidewalk", "pavement", "curb", "pedestrian", "paver block"));
        CATEGORY_KEYWORDS.put("roads-traffic", List.of("road", "traffic", "signal", "speed breaker", "zebra crossing", "carriageway", "asphalt", "tarmac"));

        CATEGORY_KEYWORDS.put("garbage-dump", List.of("garbage", "trash", "waste", "dump", "litter", "debris", "rubbish", "refuse"));
        CATEGORY_KEYWORDS.put("drain-blockage", List.of("drain", "drainage", "sewage", "blocked drain", "overflow", "stagnant water", "gutter", "manhole", "sewer"));
        CATEGORY_KEYWORDS.put("sanitation-waste", List.of("sanitation", "cleanliness", "stench", "smell", "filth", "hygiene", "sweeping"));

        CATEGORY_KEYWORDS.put("water-pipe-leak", List.of("pipe leak", "pipeline burst", "burst pipe", "water gushing", "pipe broken", "leaking line"));
        CATEGORY_KEYWORDS.put("no-water-supply", List.of("no water", "low pressure", "water cut", "dry tap", "tanker", "water shortage"));
        CATEGORY_KEYWORDS.put("water-supply", List.of("drinking water", "water contamination", "dirty water", "water pipeline", "water valve", "supply"));

        CATEGORY_KEYWORDS.put("broken-streetlight", List.of("streetlight", "street light", "lamp post", "broken bulb", "dark pole", "flickering light"));
        CATEGORY_KEYWORDS.put("street-lighting", List.of("lighting", "darkness", "illumination", "blackout", "electric pole", "light fixture"));

        CATEGORY_KEYWORDS.put("damaged-playground", List.of("playground", "swing", "slide", "seesaw", "play equipment", "broken bench"));
        CATEGORY_KEYWORDS.put("public-parks", List.of("park", "garden", "lawn", "fallen tree", "overgrown grass", "horticulture", "walking track", "pruning"));

        // Department mappings
        CATEGORY_DEPARTMENT_MAP.put("roads-traffic", "Roads & Public Works Department");
        CATEGORY_DEPARTMENT_MAP.put("potholes", "Roads & Public Works Department");
        CATEGORY_DEPARTMENT_MAP.put("broken-footpath", "Roads & Public Works Department");

        CATEGORY_DEPARTMENT_MAP.put("sanitation-waste", "Sanitation & Waste Management Department");
        CATEGORY_DEPARTMENT_MAP.put("garbage-dump", "Sanitation & Waste Management Department");
        CATEGORY_DEPARTMENT_MAP.put("drain-blockage", "Sanitation & Waste Management Department");

        CATEGORY_DEPARTMENT_MAP.put("water-supply", "Water Supply & Sewerage Board");
        CATEGORY_DEPARTMENT_MAP.put("water-pipe-leak", "Water Supply & Sewerage Board");
        CATEGORY_DEPARTMENT_MAP.put("no-water-supply", "Water Supply & Sewerage Board");

        CATEGORY_DEPARTMENT_MAP.put("street-lighting", "Electrical & Lighting Department");
        CATEGORY_DEPARTMENT_MAP.put("broken-streetlight", "Electrical & Lighting Department");

        CATEGORY_DEPARTMENT_MAP.put("public-parks", "Horticulture & Parks Department");
        CATEGORY_DEPARTMENT_MAP.put("damaged-playground", "Horticulture & Parks Department");
    }

    @Override
    public String getProviderName() {
        return PROVIDER_NAME;
    }

    @Override
    public String getProviderVersion() {
        return PROVIDER_VERSION;
    }

    @Override
    public IssueAnalysisResult analyze(IssueAnalysisContext context) {
        String title = context.title() != null ? context.title() : "";
        String description = context.description() != null ? context.description() : "";
        String textToAnalyze = (title + " " + description).toLowerCase();

        // 1. Suggest Category
        CategoryMatch categoryMatch = matchCategory(title.toLowerCase(), description.toLowerCase(), context.availableCategories());

        // 2. Determine Priority & Signals
        PriorityMatch priorityMatch = evaluatePriority(textToAnalyze, categoryMatch.suggestedCategory());

        // 3. Determine Department Routing
        DepartmentMatch departmentMatch = determineDepartment(categoryMatch.suggestedCategory(), context.wardCode(), categoryMatch.confidence());

        // 4. Calculate Overall Confidence
        double overallConfidence = Math.round((
                0.40 * categoryMatch.confidence() +
                0.30 * priorityMatch.confidence() +
                0.30 * departmentMatch.confidence()
        ) * 100.0) / 100.0;

        // 5. Determine Human Review Requirement
        // Needs review if:
        // - overall confidence is low (< 0.70)
        // - priority is CRITICAL
        // - safety signal detected without corroborated scale/urgency
        // - category was ambiguous
        boolean needsReview = overallConfidence < 0.70
                || priorityMatch.priority() == Priority.CRITICAL
                || priorityMatch.unverifiedSafetySignal()
                || categoryMatch.isAmbiguous();

        // 6. Build Explanation
        String explanation = buildExplanation(categoryMatch, priorityMatch, departmentMatch, needsReview);

        // 7. Assemble Structured Factors
        Map<String, Object> factors = new LinkedHashMap<>();
        factors.put("categoryKeywords", categoryMatch.matchedKeywords());
        factors.put("safetySignals", priorityMatch.safetySignals());
        factors.put("scaleSignals", priorityMatch.scaleSignals());
        factors.put("urgencySignals", priorityMatch.urgencySignals());
        factors.put("lowSeveritySignals", priorityMatch.lowSeveritySignals());
        factors.put("wardJurisdiction", context.wardCode() != null ? context.wardCode() : "N/A");
        factors.put("confidenceBreakdown", Map.of(
                "category", categoryMatch.confidence(),
                "priority", priorityMatch.confidence(),
                "routing", departmentMatch.confidence(),
                "overall", overallConfidence
        ));

        UUID categoryId = categoryMatch.suggestedCategory() != null ? categoryMatch.suggestedCategory().getId() : null;
        String categoryName = categoryMatch.suggestedCategory() != null ? categoryMatch.suggestedCategory().getName() : "General Civic Issue";

        return new IssueAnalysisResult(
                categoryId,
                categoryName,
                priorityMatch.priority(),
                departmentMatch.department(),
                categoryMatch.confidence(),
                priorityMatch.confidence(),
                departmentMatch.confidence(),
                overallConfidence,
                explanation,
                factors,
                needsReview,
                PROVIDER_NAME,
                PROVIDER_VERSION
        );
    }

    private CategoryMatch matchCategory(String titleLower, String descLower, List<Category> availableCategories) {
        if (availableCategories == null || availableCategories.isEmpty()) {
            return new CategoryMatch(null, 0.40, Collections.emptyList(), true);
        }

        Category bestCategory = null;
        double highestScore = 0.0;
        List<String> matchedKeywords = new ArrayList<>();

        for (Category category : availableCategories) {
            String slug = category.getSlug() != null ? category.getSlug().toLowerCase() : "";
            List<String> keywords = CATEGORY_KEYWORDS.getOrDefault(slug, Collections.emptyList());

            double score = 0.0;
            List<String> currentMatches = new ArrayList<>();

            for (String kw : keywords) {
                if (titleLower.contains(kw)) {
                    score += 2.0; // Title match has double weight
                    currentMatches.add(kw + " (title)");
                }
                if (descLower.contains(kw)) {
                    score += 1.0;
                    currentMatches.add(kw + " (desc)");
                }
            }

            // Also check category name direct containment
            String nameLower = category.getName().toLowerCase();
            if (titleLower.contains(nameLower)) {
                score += 2.5;
                currentMatches.add(nameLower);
            }

            if (score > highestScore) {
                highestScore = score;
                bestCategory = category;
                matchedKeywords = currentMatches;
            }
        }

        if (bestCategory == null || highestScore == 0.0) {
            // Fallback to first available category or null
            Category fallback = availableCategories.get(0);
            return new CategoryMatch(fallback, 0.35, Collections.emptyList(), true);
        }

        double confidence;
        boolean isAmbiguous = false;
        if (highestScore >= 3.0) {
            confidence = 0.90;
        } else if (highestScore >= 2.0) {
            confidence = 0.80;
        } else {
            confidence = 0.65;
            isAmbiguous = true;
        }

        return new CategoryMatch(bestCategory, confidence, matchedKeywords, isAmbiguous);
    }

    private PriorityMatch evaluatePriority(String text, Category category) {
        List<String> detectedSafety = findMatchingKeywords(text, SAFETY_HAZARD_KEYWORDS);
        List<String> detectedScale = findMatchingKeywords(text, SCALE_DISRUPTION_KEYWORDS);
        List<String> detectedUrgency = findMatchingKeywords(text, URGENCY_KEYWORDS);
        List<String> detectedLow = findMatchingKeywords(text, LOW_SEVERITY_KEYWORDS);

        Priority defaultPriority = (category != null && category.getDefaultPriority() != null)
                ? category.getDefaultPriority()
                : Priority.MEDIUM;

        boolean unverifiedSafetySignal = false;
        Priority recommendedPriority;
        double confidence;

        // Rule: Avoid assigning CRITICAL on keyword alone. Combine safety with scale or urgency signals.
        if (!detectedSafety.isEmpty()) {
            if (!detectedScale.isEmpty() || !detectedUrgency.isEmpty()) {
                // High safety hazard + corroborated scale or urgency -> CRITICAL
                recommendedPriority = Priority.CRITICAL;
                confidence = 0.92;
            } else {
                // Safety hazard keyword appears alone without corroborating scale/urgency factor.
                // Escalate to HIGH (not CRITICAL) and mark for human review verification.
                recommendedPriority = Priority.HIGH;
                confidence = 0.72;
                unverifiedSafetySignal = true;
            }
        } else if (!detectedScale.isEmpty() || !detectedUrgency.isEmpty()) {
            recommendedPriority = Priority.HIGH;
            confidence = 0.82;
        } else if (!detectedLow.isEmpty()) {
            recommendedPriority = Priority.LOW;
            confidence = 0.80;
        } else {
            recommendedPriority = defaultPriority;
            confidence = 0.80;
        }

        return new PriorityMatch(
                recommendedPriority,
                confidence,
                detectedSafety,
                detectedScale,
                detectedUrgency,
                detectedLow,
                unverifiedSafetySignal
        );
    }

    private DepartmentMatch determineDepartment(Category category, String wardCode, double categoryConfidence) {
        String baseDepartment = "Municipal Administration & Citizen Services";

        if (category != null && category.getSlug() != null) {
            String slug = category.getSlug().toLowerCase();
            for (Map.Entry<String, String> entry : CATEGORY_DEPARTMENT_MAP.entrySet()) {
                if (slug.contains(entry.getKey())) {
                    baseDepartment = entry.getValue();
                    break;
                }
            }
        }

        String routedDepartment = baseDepartment;
        if (wardCode != null && !wardCode.isBlank()) {
            routedDepartment = baseDepartment + " (" + wardCode.trim() + ")";
        }

        double confidence = categoryConfidence >= 0.75 ? 0.90 : 0.60;
        return new DepartmentMatch(routedDepartment, confidence);
    }

    private String buildExplanation(CategoryMatch catMatch, PriorityMatch prioMatch, DepartmentMatch deptMatch, boolean needsReview) {
        StringBuilder sb = new StringBuilder();

        if (catMatch.suggestedCategory() != null) {
            sb.append("Categorized as '").append(catMatch.suggestedCategory().getName()).append("' ");
            if (!catMatch.matchedKeywords().isEmpty()) {
                sb.append("based on matched keywords: ").append(String.join(", ", catMatch.matchedKeywords())).append(". ");
            } else {
                sb.append("based on taxonomy fallback rules. ");
            }
        } else {
            sb.append("Category could not be matched with high confidence. ");
        }

        sb.append("Recommended priority: ").append(prioMatch.priority()).append(". ");
        if (prioMatch.priority() == Priority.CRITICAL) {
            sb.append("Assigned CRITICAL priority due to confirmed safety hazard signals (")
                    .append(String.join(", ", prioMatch.safetySignals()))
                    .append(") combined with disruption/urgency indicators. ");
        } else if (prioMatch.unverifiedSafetySignal()) {
            sb.append("Safety risk detected (")
                    .append(String.join(", ", prioMatch.safetySignals()))
                    .append("), assigned HIGH priority pending human officer verification. ");
        } else if (!prioMatch.scaleSignals().isEmpty() || !prioMatch.urgencySignals().isEmpty()) {
            sb.append("Assigned HIGH priority due to public disruption or urgency indicators. ");
        } else if (!prioMatch.lowSeveritySignals().isEmpty()) {
            sb.append("Assigned LOW priority based on minor/cosmetic characteristics. ");
        }

        sb.append("Routed to ").append(deptMatch.department()).append(".");

        if (needsReview) {
            sb.append(" Marked for human triage and officer confirmation.");
        }

        return sb.toString();
    }

    private List<String> findMatchingKeywords(String text, List<String> dictionary) {
        List<String> matches = new ArrayList<>();
        for (String phrase : dictionary) {
            if (text.contains(phrase)) {
                matches.add(phrase);
            }
        }
        return matches;
    }

    // Helper carrier records
    private record CategoryMatch(Category suggestedCategory, double confidence, List<String> matchedKeywords, boolean isAmbiguous) {}
    private record PriorityMatch(
            Priority priority,
            double confidence,
            List<String> safetySignals,
            List<String> scaleSignals,
            List<String> urgencySignals,
            List<String> lowSeveritySignals,
            boolean unverifiedSafetySignal
    ) {}
    private record DepartmentMatch(String department, double confidence) {}
}
