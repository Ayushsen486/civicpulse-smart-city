import 'package:flutter_test/flutter_test.dart';
import 'package:civicpulse_app/features/auth/domain/user_model.dart';
import 'package:civicpulse_app/features/issue/domain/category_model.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';
import 'package:civicpulse_app/features/issue/domain/intelligence_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson creates valid UserModel', () {
      final json = {
        'id': 'user-123',
        'email': 'citizen@civicpulse.org',
        'firstName': 'Aarav',
        'lastName': 'Sharma',
        'phone': '+919876543210',
        'role': 'CITIZEN',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'citizen@civicpulse.org');
      expect(user.fullName, 'Aarav Sharma');
      expect(user.role, 'CITIZEN');
      expect(user.phone, '+919876543210');
      expect(user.toJson()['email'], 'citizen@civicpulse.org');
    });
  });

  group('CategoryModel', () {
    test('fromJson handles valid category map', () {
      final json = {
        'id': 'cat-1',
        'name': 'Potholes & Road Damage',
        'slug': 'potholes-road-damage',
        'description': 'Road maintenance issues',
        'icon': 'road',
        'defaultPriority': 'HIGH',
      };

      final cat = CategoryModel.fromJson(json);

      expect(cat.id, 'cat-1');
      expect(cat.name, 'Potholes & Road Damage');
      expect(cat.slug, 'potholes-road-damage');
      expect(cat.defaultPriority, 'HIGH');
    });
  });

  group('IssueModel', () {
    test('fromJson handles full issue map with coordinates and upvotes', () {
      final json = {
        'id': 'issue-456',
        'title': 'Dangerous Open Manhole',
        'description': 'Near central market crossing',
        'status': 'OPEN',
        'priority': 'CRITICAL',
        'categoryId': 'cat-1',
        'categoryName': 'Roads',
        'reporterId': 'user-123',
        'reporterName': 'Aarav Sharma',
        'latitude': 28.6139,
        'longitude': 77.2090,
        'address': 'Connaught Place Block B',
        'landmark': 'Near metro gate 3',
        'upvotesCount': 42,
        'hasUpvoted': true,
        'createdAt': '2026-10-10T12:00:00Z',
      };

      final issue = IssueModel.fromJson(json);

      expect(issue.id, 'issue-456');
      expect(issue.title, 'Dangerous Open Manhole');
      expect(issue.status, 'OPEN');
      expect(issue.priority, 'CRITICAL');
      expect(issue.upvotesCount, 42);
      expect(issue.hasUpvoted, true);
      expect(issue.latitude, 28.6139);
      expect(issue.longitude, 77.2090);
    });
  });

  group('IntelligenceModel', () {
    test('fromJson parses AI recommendations', () {
      final json = {
        'suggestedCategoryName': 'Potholes & Road Damage',
        'suggestedCategoryId': 'cat-road-1',
        'suggestedPriority': 'HIGH',
        'priorityConfidence': 0.92,
        'recommendedDepartment': 'Road Maintenance & Infrastructure',
        'overallConfidence': 0.88,
        'explanation': 'Hazardous road condition requiring immediate patching.',
        'needsHumanReview': false,
      };

      final intelligence = IntelligenceModel.fromJson(json);

      expect(intelligence.suggestedCategoryName, 'Potholes & Road Damage');
      expect(intelligence.suggestedCategoryId, 'cat-road-1');
      expect(intelligence.suggestedPriority, 'HIGH');
      expect(intelligence.priorityConfidence, 0.92);
      expect(intelligence.recommendedDepartment, 'Road Maintenance & Infrastructure');
      expect(intelligence.explanation, 'Hazardous road condition requiring immediate patching.');
    });
  });
}
