import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/madrasa_provider.dart';
import '../models/student.dart';
import '../models/parent.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({Key? key}) : super(key: key);

  Future<void> _selectDate(BuildContext context, MadrasaProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      selectableDayPredicate: (DateTime day) {
        // Block/grey out Thursdays and Fridays
        return day.weekday != DateTime.thursday && day.weekday != DateTime.friday;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF064E3B), // Header color
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F2937), // Body text
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != provider.selectedDate) {
      await provider.setDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MadrasaProvider>(
      builder: (context, provider, child) {
        final formattedDate = DateFormat('EEEE, dd MMM yyyy').format(provider.selectedDate);
        final isWeekend = provider.isWeekend;

        // Statistics calculation for the header dashboard
        int presentCount = 0;
        int absentCount = 0;
        int lateCount = 0;

        if (!isWeekend) {
          provider.attendanceMap.forEach((_, att) {
            if (att.status == 'present') presentCount++;
            if (att.status == 'absent') absentCount++;
            if (att.status == 'late') lateCount++;
          });
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 130.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF064E3B),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF064E3B), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daily Attendance',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              _buildSyncStatusIndicator(context, provider),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _buildSyncButton(context, provider),
                                  const SizedBox(width: 8.0),
                                  ElevatedButton.icon(
                                    onPressed: () => _selectDate(context, provider),
                                    icon: const Icon(Icons.calendar_month, size: 16, color: Color(0xFF064E3B)),
                                    label: const Text('Date', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.0),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Loading indicator
              if (provider.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF064E3B)),
                    ),
                  ),
                )
              
              // No students registered yet
              else if (provider.students.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.child_care_outlined, size: 80, color: Colors.teal[200]),
                          const SizedBox(height: 16.0),
                          const Text(
                            'No Pupils Registered Yet',
                            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                          ),
                          const SizedBox(height: 8.0),
                          const Text(
                            'Please navigate to the Registration tab first to register parents and their pupils.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              // Weekend Policy friendly placeholder
              else if (isWeekend)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.hotel, size: 64, color: Colors.amber[800]),
                              ),
                              const SizedBox(height: 24.0),
                              const Text(
                                'No classes scheduled for today!',
                                style: TextStyle(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF064E3B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                'Madrasa weekends are scheduled on Thursdays and Fridays. Use the Date button in the header to select a standard weekday roster.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 15.0,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )

              // Standard Attendance List View with stats dashboard
              else ...[
                // Stat Dashboard
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Present',
                            count: presentCount,
                            color: const Color(0xFF10B981), // Emerald
                            textColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Absent',
                            count: absentCount,
                            color: const Color(0xFFEF4444), // Crimson
                            textColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Late',
                            count: lateCount,
                            color: const Color(0xFFF59E0B), // Amber
                            textColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Attendance list
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final student = provider.students[index];
                        final attendance = provider.attendanceMap[student.id];
                        
                        // Find parent
                        final parent = provider.parents.firstWhere(
                          (p) => p.id == student.parentId,
                          orElse: () => Parent(id: '', guardianName: 'Unknown Parent'),
                        );

                        return _buildRosterRow(
                          context: context,
                          student: student,
                          parent: parent,
                          status: attendance?.status ?? 'present',
                          onTapBadge: () {
                            // Instantly toggle and auto-save
                            provider.toggleAttendanceStatus(student.id);
                          },
                        );
                      },
                      childCount: provider.students.length,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32.0),
                )
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({required String title, required int count, required Color color, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.85),
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterRow({
    required BuildContext context,
    required Student student,
    required Parent parent,
    required String status,
    required VoidCallback onTapBadge,
  }) {
    Color badgeColor;
    String badgeText;
    
    switch (status) {
      case 'absent':
        badgeColor = const Color(0xFFEF4444);
        badgeText = 'ABSENT';
        break;
      case 'late':
        badgeColor = const Color(0xFFF59E0B);
        badgeText = 'LATE';
        break;
      case 'present':
      default:
        badgeColor = const Color(0xFF10B981);
        badgeText = 'PRESENT';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Student avatar with initials
            CircleAvatar(
              backgroundColor: badgeColor.withOpacity(0.1),
              child: Text(
                student.fullName.isNotEmpty ? student.fullName.substring(0, 1).toUpperCase() : 'P',
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            
            // Student & Parent details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          student.classId,
                          style: const TextStyle(fontSize: 10.0, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    parent.phoneNumber != null && parent.phoneNumber!.isNotEmpty
                        ? 'Parent: ${parent.guardianName} • ${parent.phoneNumber}'
                        : 'Parent: ${parent.guardianName}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            
            // High visibility badge (minimum 48x48 hit target)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTapBadge,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 90,
                  height: 48, // Fulfills the minimum 48px hit target
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusIndicator(BuildContext context, MadrasaProvider provider) {
    if (provider.isSyncing) {
      return const Text(
        'Syncing...',
        style: TextStyle(color: Colors.white70, fontSize: 12.0, fontWeight: FontWeight.w500),
      );
    }
    
    if (provider.syncErrorMessage != null) {
      return GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync Error: ${provider.syncErrorMessage}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        },
        child: const Row(
          children: [
            Icon(Icons.warning_amber, size: 14, color: Colors.orangeAccent),
            SizedBox(width: 4),
            Text(
              'Sync Error',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 12.0, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
          ],
        ),
      );
    }

    if (provider.lastSyncTime == null) {
      return const Text(
        'Offline Mode (Not Synced)',
        style: TextStyle(color: Colors.white70, fontSize: 12.0, fontStyle: FontStyle.italic),
      );
    }

    final timeStr = DateFormat('HH:mm').format(provider.lastSyncTime!);
    return Text(
      'Synced at $timeStr',
      style: TextStyle(color: Color(0xFFE6F4EA), fontSize: 12.0, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSyncButton(BuildContext context, MadrasaProvider provider) {
    if (provider.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 6),
            Text('Syncing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.0)),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () async {
        await provider.synchronizeWithBackend();
        if (context.mounted) {
          if (provider.syncErrorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync failed: ${provider.syncErrorMessage}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Madrasa successfully synchronized with backend!'),
                backgroundColor: Colors.teal,
              ),
            );
          }
        }
      },
      icon: const Icon(Icons.sync, size: 16, color: Color(0xFF064E3B)),
      label: const Text('Sync', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
