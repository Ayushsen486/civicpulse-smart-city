package com.civicpulse;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Tag;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
@Tag("integration")
@Disabled("Requires active PostgreSQL/PostGIS database instance or Docker daemon")
class CivicpulseBackendApplicationTests {

	@Test
	void contextLoads() {
	}

}
