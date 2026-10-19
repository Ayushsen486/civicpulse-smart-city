package com.civicpulse.module.intelligence.provider;

public interface IssueIntelligenceProvider {

    IssueAnalysisResult analyze(IssueAnalysisContext context);

    String getProviderName();

    String getProviderVersion();
}
