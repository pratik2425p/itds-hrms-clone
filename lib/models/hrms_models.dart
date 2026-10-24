import 'package:flutter/material.dart';

class FeedItem {
  final String id;
  final String author;
  final String authorInitials;
  final Color avatarBg;
  final String postedTime;
  final String content;
  int likes;
  final int comments;
  bool isLiked;

  FeedItem({
    required this.id,
    required this.author,
    required this.authorInitials,
    required this.avatarBg,
    required this.postedTime,
    required this.content,
    required this.likes,
    required this.comments,
    this.isLiked = false,
  });
}

class AttendanceRow {
  final String status;
  final String date;
  final String inTime;
  final String outTime;
  final String workingHrs;
  final String deviationHrs;
  final String breakHrs;
  final String lateMark;
  final String shiftTime;
  final String regStatus;
  final Color statusColor;

  AttendanceRow({
    required this.status,
    required this.date,
    this.inTime = '',
    this.outTime = '',
    this.workingHrs = '00:00',
    this.deviationHrs = '00:00 Hrs.',
    this.breakHrs = '00:00 Hrs.',
    this.lateMark = '--',
    this.shiftTime = '11:00 AM - 08:00 PM',
    this.regStatus = '--',
    required this.statusColor,
  });
}

class Employee {
  final String id;
  final String code;
  final String name;
  final String initials;
  final Color avatarColor;
  final String role;
  final String department;
  final String joinedOn;
  final String mobile;
  final String branchLocation;
  final String email;
  final String position;

  Employee({
    required this.id,
    required this.code,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.role,
    this.department = 'Engineering',
    this.joinedOn = '04-11-2024',
    this.mobile = '+91-9876543210',
    this.branchLocation = 'Mumbai; Mumbai; Maharashtra',
    this.email = 'pratik@codeqube.ai',
    this.position = 'Flutter Developer',
  });
}

class HolidayItem {
  final String date;
  final String day;
  final String name;
  final String type;
  final IconData icon;
  final Color iconColor;

  HolidayItem({
    required this.date,
    required this.day,
    required this.name,
    this.type = 'Mandatory',
    required this.icon,
    required this.iconColor,
  });
}

class RosterDay {
  final int dayNumber;
  final String weekday;
  final String shiftTime;
  final bool isWeeklyOff;

  RosterDay({
    required this.dayNumber,
    required this.weekday,
    this.shiftTime = '11:00 AM-08:00 PM',
    this.isWeeklyOff = false,
  });
}

class LeaveApplication {
  final String id;
  final String category;
  final String startDate;
  final String endDate;
  final double totalDays;
  final String status;
  final Color statusColor;

  LeaveApplication({
    required this.id,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.statusColor,
  });
}
