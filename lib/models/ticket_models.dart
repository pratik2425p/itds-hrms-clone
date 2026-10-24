import 'package:flutter/material.dart';

class ClientTicket {
  final int id;
  final String ticketNumber;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String clientName;
  final String clientEmail;
  final String status;
  final String managerCode;
  final String managerName;
  final String csPersonCode;
  final String csPersonName;
  final String developerCode;
  final String developerName;
  final String testerCode;
  final String testerName;
  final String currentOwnerCode;
  final String currentOwnerName;
  final String currentStageName;
  final String? activeTimerRole;
  final DateTime? activeTimerStartTime;
  final int totalDevMinutes;
  final int totalTestingMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  // ITDS Specific Fields
  final int dtd;
  final String ticketType;
  final String ticketSubType;
  final String toughness;
  final String adminAssigned;
  final String tags;
  final String dropletUrl;
  final String module;
  final String subModule;
  final int estimatedMinutes;
  final String pullRequestLink;
  final bool isCritical;
  final String criticalComment;
  final String docketNo;
  final String invoiceNo;
  final String creatorPhone;
  final String issueType;
  final String softwareName;

  ClientTicket({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.clientName,
    required this.clientEmail,
    required this.status,
    required this.managerCode,
    required this.managerName,
    required this.csPersonCode,
    required this.csPersonName,
    required this.developerCode,
    required this.developerName,
    required this.testerCode,
    required this.testerName,
    required this.currentOwnerCode,
    required this.currentOwnerName,
    required this.currentStageName,
    this.activeTimerRole,
    this.activeTimerStartTime,
    required this.totalDevMinutes,
    required this.totalTestingMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.dtd = 1,
    this.ticketType = 'SOFTWARE USERS',
    this.ticketSubType = 'PERMISSIONS',
    this.toughness = 'MEDIUM',
    this.adminAssigned = 'KKOTIAN',
    this.tags = 'SOFTWARE ISSUE / BUG',
    this.dropletUrl = 'HTTP://167.71.117.182/ COMPANY ID : 2',
    this.module = 'SOFTWARE USERS',
    this.subModule = 'PERMISSIONS',
    this.estimatedMinutes = 300,
    this.pullRequestLink = '',
    this.isCritical = false,
    this.criticalComment = '',
    this.docketNo = 'DOC-88291',
    this.invoiceNo = 'INV-44102',
    this.creatorPhone = '+91 98200 12345',
    this.issueType = 'NON ITD ISSUE',
    this.softwareName = 'TRACKMATE',
  });

  factory ClientTicket.fromJson(Map<String, dynamic> json) {
    return ClientTicket(
      id: (json['id'] as num?)?.toInt() ?? 0,
      ticketNumber: json['ticketNumber']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: (json['priority']?.toString() ?? 'MEDIUM').toUpperCase(),
      category: json['category']?.toString() ?? 'General',
      clientName: json['clientName']?.toString() ?? 'Valued Client',
      clientEmail: json['clientEmail']?.toString() ?? '',
      status: json['status']?.toString() ?? 'CREATED',
      managerCode: json['managerCode']?.toString() ?? '',
      managerName: json['managerName']?.toString() ?? '',
      csPersonCode: json['csPersonCode']?.toString() ?? '',
      csPersonName: json['csPersonName']?.toString() ?? '',
      developerCode: json['developerCode']?.toString() ?? '',
      developerName: json['developerName']?.toString() ?? '',
      testerCode: json['testerCode']?.toString() ?? '',
      testerName: json['testerName']?.toString() ?? '',
      currentOwnerCode: json['currentOwnerCode']?.toString() ?? '',
      currentOwnerName: json['currentOwnerName']?.toString() ?? '',
      currentStageName: json['currentStageName']?.toString() ?? 'Manager Review',
      activeTimerRole: json['activeTimerRole']?.toString(),
      activeTimerStartTime: json['activeTimerStartTime'] != null && json['activeTimerStartTime'].toString().isNotEmpty
          ? DateTime.tryParse(json['activeTimerStartTime'].toString())
          : null,
      totalDevMinutes: (json['totalDevMinutes'] as num?)?.toInt() ?? 0,
      totalTestingMinutes: (json['totalTestingMinutes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null && json['createdAt'].toString().isNotEmpty
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null && json['updatedAt'].toString().isNotEmpty
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: json['resolvedAt'] != null && json['resolvedAt'].toString().isNotEmpty
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      dtd: (json['dtd'] as num?)?.toInt() ?? 1,
      ticketType: json['ticketType']?.toString() ?? 'SOFTWARE USERS',
      ticketSubType: json['ticketSubType']?.toString() ?? 'PERMISSIONS',
      toughness: json['toughness']?.toString() ?? 'MEDIUM',
      adminAssigned: json['adminAssigned']?.toString() ?? 'KKOTIAN',
      tags: json['tags']?.toString() ?? 'SOFTWARE ISSUE / BUG',
      dropletUrl: json['dropletUrl']?.toString() ?? 'HTTP://167.71.117.182/ COMPANY ID : 2',
      module: json['module']?.toString() ?? 'SOFTWARE USERS',
      subModule: json['subModule']?.toString() ?? 'PERMISSIONS',
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 300,
      pullRequestLink: json['pullRequestLink']?.toString() ?? '',
      isCritical: json['isCritical'] == true || (json['priority']?.toString().toUpperCase() == 'CRITICAL'),
      criticalComment: json['criticalComment']?.toString() ?? '',
      docketNo: json['docketNo']?.toString() ?? 'DOC-88291',
      invoiceNo: json['invoiceNo']?.toString() ?? 'INV-44102',
      creatorPhone: json['creatorPhone']?.toString() ?? '+91 98200 12345',
      issueType: json['issueType']?.toString() ?? 'NON ITD ISSUE',
      softwareName: json['softwareName']?.toString() ?? 'TRACKMATE',
    );
  }

  bool get isTimerRunning => activeTimerRole != null && activeTimerStartTime != null;

  Color get priorityColor {
    switch (priority) {
      case 'CRITICAL':
        return const Color(0xFFDC2626);
      case 'HIGH':
        return const Color(0xFFEA580C);
      case 'MEDIUM':
        return const Color(0xFFD97706);
      case 'LOW':
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color get statusColor {
    final s = status.toUpperCase().replaceAll('_', ' ');
    if (s.contains('DEVELOPMENT IN PROGRESS') || s.contains('DEV IN PROGRESS')) {
      return const Color(0xFFE53E3E); // Red pill
    }
    if (s.contains('HOLD')) {
      return const Color(0xFFD69E2E); // Amber pill
    }
    if (s.contains('PULL REQUEST') || s.contains('PR RAISED')) {
      return const Color(0xFFDD6B20); // Orange pill
    }
    if (s.contains('TEST FAILED')) {
      return const Color(0xFFC53030); // Crimson pill
    }
    if (s.contains('DEVELOPMENT') || s.contains('ASSIGNED TO DEV')) {
      return const Color(0xFF319795); // Teal pill
    }
    if (s.contains('TESTING') || s.contains('READY FOR TESTING')) {
      return const Color(0xFF3182CE); // Blue pill
    }
    if (s.contains('RESOLVED') || s.contains('CLOSED')) {
      return const Color(0xFF38A169); // Green pill
    }
    if (s.contains('CS')) {
      return const Color(0xFF0284C7);
    }
    return const Color(0xFF718096);
  }

  String get itdsStatus {
    final s = status.toUpperCase().replaceAll('_', ' ');
    if (s.contains('DEV IN PROGRESS') || s == 'DEVELOPMENT IN PROGRESS') return 'DEVELOPMENT IN PROGRESS';
    if (s.contains('HOLD')) return 'HOLD';
    if (s.contains('PULL REQUEST') || s.contains('PR RAISED')) return 'PULL REQUEST RAISED';
    if (s.contains('TEST FAILED')) return 'TEST FAILED';
    if (s == 'ASSIGNED TO DEV' || s == 'DEVELOPMENT') return 'DEVELOPMENT';
    if (s.contains('READY FOR TESTING') || s == 'TESTING') return 'TESTING';
    if (s.contains('TESTING IN PROGRESS')) return 'TESTING IN PROGRESS';
    if (s.contains('CLOSED') || s.contains('RESOLVED')) return 'RESOLVED';
    if (s.contains('CS')) return 'CS TRIAGE';
    return s;
  }

  String get humanStatus => itdsStatus;
}

class TicketTimelineEvent {
  final int id;
  final String stepName;
  final String actorCode;
  final String actorName;
  final String actorRole;
  final String action;
  final String comment;
  final int timeTakenMinutes;
  final DateTime timestamp;

  TicketTimelineEvent({
    required this.id,
    required this.stepName,
    required this.actorCode,
    required this.actorName,
    required this.actorRole,
    required this.action,
    required this.comment,
    required this.timeTakenMinutes,
    required this.timestamp,
  });

  factory TicketTimelineEvent.fromJson(Map<String, dynamic> json) {
    return TicketTimelineEvent(
      id: (json['id'] as num?)?.toInt() ?? 0,
      stepName: json['stepName']?.toString() ?? '',
      actorCode: json['actorCode']?.toString() ?? '',
      actorName: json['actorName']?.toString() ?? '',
      actorRole: json['actorRole']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      timeTakenMinutes: (json['timeTakenMinutes'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null && json['timestamp'].toString().isNotEmpty
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class TicketComment {
  final int id;
  final String authorCode;
  final String authorName;
  final String authorRole;
  final String message;
  final String? attachmentName;
  final DateTime createdAt;

  TicketComment({
    required this.id,
    required this.authorCode,
    required this.authorName,
    required this.authorRole,
    required this.message,
    this.attachmentName,
    required this.createdAt,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    return TicketComment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      authorCode: json['authorCode']?.toString() ?? '',
      authorName: json['authorName']?.toString() ?? '',
      authorRole: json['authorRole']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      attachmentName: json['attachmentName']?.toString(),
      createdAt: json['createdAt'] != null && json['createdAt'].toString().isNotEmpty
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
