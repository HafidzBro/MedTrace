import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PatientMockScaffold(
      currentIndex: 2,
      backgroundColor: const Color(0xFFF0FBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 76,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 8),
            child: IconButton.filled(
              onPressed: () => context.go(AppRoutes.patientDashboard),
              icon: const Icon(Icons.close_rounded),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE9EEEE),
                foregroundColor: const Color(0xFF2B3335),
              ),
            ),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 74, 36, 104),
          child: Column(
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: patientTeal2,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: patientTeal.withValues(alpha: 0.24),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.wb_sunny_outlined,
                  color: Color(0xFFA9DAD8),
                  size: 42,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Time for your morning\ndose',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: patientTeal,
                  fontSize: 30,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stay on track with your treatment plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF50585C),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 34),
              PatientCard(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                color: Colors.white,
                borderColor: const Color(0xFFD1F5EF),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: patientMint,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.medication_rounded,
                            color: patientTeal,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Isoniazid & Rifampicin',
                                style: TextStyle(
                                  color: patientTeal,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '300mg + 600mg',
                                style: TextStyle(
                                  color: Color(0xFF50585C),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(height: 1, color: patientBorder),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: patientTeal),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Take with food, ideally with a glass of water.',
                              style: TextStyle(
                                color: patientText,
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _showDoseLogged(context),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Confirm Intake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: patientTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  void _showDoseLogged(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: patientBorder, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: patientMint.withValues(alpha: 0.35),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.check_rounded,
                        color: Colors.white, size: 42),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Dose Logged!',
                  style: TextStyle(fontSize: 16, color: patientText),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Great job staying on track. Your next dose is scheduled for tomorrow at 08:00 AM.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: patientText,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: patientBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'INTAKE TIMESTAMP',
                        style: TextStyle(
                          color: patientText,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 18),
                          SizedBox(width: 8),
                          Text('Today, 08:15 AM',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go(AppRoutes.patientDashboard);
                    },
                    child: const Text(
                      'Return to Home',
                      style: TextStyle(color: patientText, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
