import 'package:flutter/material.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';

class PatientDetailPage extends StatelessWidget {
  final String patientId;
  final String patientName;

  const PatientDetailPage({
    required this.patientId,
    required this.patientName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = patientName.trim().isEmpty || patientName == 'Patient'
        ? 'Maria'
        : patientName;

    return Scaffold(
      backgroundColor: doctorBg,
      appBar: DoctorTopBar(
        title: 'Patient Detail',
        showBack: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: doctorText),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 96),
            child: Column(
              children: [
                DoctorCard(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const DoctorAvatar(
                            icon: Icons.person,
                            radius: 44,
                            color: Color(0xFF16A39A),
                          ),
                          Positioned(
                            right: -4,
                            bottom: 4,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: doctorTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.verified_rounded,
                                  color: doctorMint, size: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: doctorText,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ID: PT-2023-8472',
                        style: TextStyle(color: doctorMuted, fontSize: 14),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          DoctorChip(
                            label: 'Active Treatment',
                            icon: Icons.check_circle_outline_rounded,
                            color: doctorMintSoft,
                            textColor: doctorTeal,
                          ),
                          DoctorChip(
                            label: 'Female, 34 y/o',
                            color: doctorNeutral,
                            textColor: Color(0xFF5C6567),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                const _IdentitySummary(),
                const SizedBox(height: 26),
                const _DiagnosisCard(),
                const SizedBox(height: 26),
                const _TherapyPhaseCard(),
                const SizedBox(height: 26),
                const _MedicationScheduleCard(),
                const SizedBox(height: 26),
                const _TherapyHistoryCard(),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusSheet(context),
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('Update Status'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: doctorTeal2,
                    foregroundColor: const Color(0xFFA9DAD8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateStatusSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _UpdateStatusSheet(),
    );
  }
}

class _IdentitySummary extends StatelessWidget {
  const _IdentitySummary();

  @override
  Widget build(BuildContext context) {
    return const DoctorCard(
      padding: EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
              icon: Icons.person_outline_rounded, title: 'Identity Summary'),
          SizedBox(height: 22),
          _DetailRow(label: 'DOB', value: '12 May 1989'),
          _Line(),
          _DetailRow(label: 'Contact', value: '+1 (555) 123-4567'),
          _Line(),
          _DetailRow(
              label: 'Address', value: '1428 Elm St, Springfield, IL\n62701'),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard();

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(
              icon: Icons.medical_information_outlined, title: 'Diagnosis'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6F6),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: doctorBorder),
            ),
            child: const Column(
              children: [
                _DetailRow(
                    label: 'CATEGORY',
                    value: 'Pulmonary TB',
                    valueColor: doctorTeal),
                SizedBox(height: 12),
                _DetailRow(label: 'DATE DIAGNOSED', value: '14 Aug 2023'),
                SizedBox(height: 12),
                _DetailRow(label: 'TYPE', value: 'Drug-Susceptible'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TherapyPhaseCard extends StatelessWidget {
  const _TherapyPhaseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: doctorTeal2,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: doctorTeal.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Current Therapy Phase',
                  style: TextStyle(
                    color: Color(0xFFA9DAD8),
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE12835),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Continuation Phase (Month 4 of 6)',
            style: TextStyle(color: Color(0xFFA9DAD8), fontSize: 15),
          ),
          const SizedBox(height: 30),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Overall Progress',
                  style: TextStyle(color: Color(0xFFA9DAD8), fontSize: 14),
                ),
              ),
              Text(
                '65%',
                style: TextStyle(
                  color: Color(0xFFA9DAD8),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const DoctorChip(
            label: 'On Track',
            color: Color(0xFF5C9D9F),
            textColor: Color(0xFFCBE9E7),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              minHeight: 8,
              value: 0.65,
              backgroundColor: Color(0xFF005256),
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicationScheduleCard extends StatelessWidget {
  const _MedicationScheduleCard();

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: doctorTeal),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Medication\nSchedule',
                  style: TextStyle(
                      color: doctorText,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.05),
                ),
              ),
              Text(
                'Last 7 Days\nAdherence: 100%',
                textAlign: TextAlign.left,
                style: TextStyle(color: doctorMuted, fontSize: 13, height: 1.3),
              ),
            ],
          ),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.52,
            children: const [
              _MedBox(
                  label: 'Isoniazid (INH)',
                  value: '300mg',
                  icon: Icons.medication_rounded),
              _MedBox(
                  label: 'Rifampin (RIF)',
                  value: '600mg',
                  icon: Icons.medication_rounded),
              _MedBox(
                  label: 'Frequency',
                  value: 'Daily',
                  icon: Icons.update_rounded),
              _MedBox(
                  label: 'Next Dose',
                  value: '08:00 AM',
                  icon: Icons.alarm_rounded,
                  filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TherapyHistoryCard extends StatelessWidget {
  const _TherapyHistoryCard();

  @override
  Widget build(BuildContext context) {
    return const DoctorCard(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(icon: Icons.history_rounded, title: 'Therapy History'),
          SizedBox(height: 24),
          _TimelineItem(
            icon: Icons.receipt_long_rounded,
            title: 'Dose Administered (VOT)',
            time: 'Today, 08:30 AM',
            body:
                'Video observed therapy completed successfully. No adverse side effects reported.',
            active: true,
          ),
          _TimelineItem(
            icon: Icons.science_outlined,
            title: 'Sputum Smear Result: Negative',
            time: '12 Oct 2023, 10:00 AM',
            body: 'Month 2 follow-up test indicates negative culture.',
          ),
          _TimelineItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Phase Transition',
            time: '14 Oct 2023',
            body: 'Patient entered continuation phase after clinical review.',
          ),
        ],
      ),
    );
  }
}

class _UpdateStatusSheet extends StatelessWidget {
  const _UpdateStatusSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          32,
          12,
          32,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: doctorBorder,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Therapy Status',
                        style: TextStyle(
                            color: doctorText,
                            fontSize: 24,
                            fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Record a change in the patient clinical pathway.',
                        style: TextStyle(color: doctorMuted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFB7C3C3)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Row(
                children: [
                  Expanded(
                      child: Text('Current Status',
                          style: TextStyle(
                              color: Color(0xFF50585C), fontSize: 15))),
                  DoctorChip(
                    label: 'ON TREATMENT',
                    icon: Icons.medication_liquid_rounded,
                    color: doctorTeal2,
                    textColor: Color(0xFFA9DAD8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Select New Status',
              style: TextStyle(
                  color: doctorText, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 2.4,
              children: const [
                _StatusChoice(
                    icon: Icons.health_and_safety_outlined, label: 'Recovered'),
                _StatusChoice(
                    icon: Icons.person_off_outlined, label: 'Defaulted'),
                _StatusChoice(
                    icon: Icons.warning_amber_rounded, label: 'At Risk'),
                _StatusChoice(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Completed',
                    selected: true),
              ],
            ),
            const SizedBox(height: 86),
            const Row(
              children: [
                Expanded(
                  child: Text('Status Change Notes',
                      style: TextStyle(
                          color: doctorText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                Text('*Required',
                    style: TextStyle(color: doctorMuted, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter clinical rationale for this status update...',
                hintStyle: const TextStyle(color: Color(0xFF8A9496)),
                filled: true,
                fillColor: const Color(0xFFF7FAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFB7C3C3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(color: Color(0xFFB7C3C3)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: doctorTeal, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Confirm Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: doctorTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _StatusChoice({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF5F5) : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: selected ? doctorTeal : const Color(0xFFB7C3C3),
          width: selected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: selected ? doctorTeal : const Color(0xFF6B7275)),
          Text(
            label,
            style: TextStyle(
              color: selected ? doctorTeal : const Color(0xFF50585C),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _CardTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: doctorTeal, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
              color: doctorText, fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = doctorText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(color: doctorMuted, fontSize: 14))),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(height: 1, color: doctorBorder),
    );
  }
}

class _MedBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool filled;

  const _MedBox({
    required this.label,
    required this.value,
    required this.icon,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: filled ? doctorNeutral : Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: doctorBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(color: doctorMuted, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: doctorText,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Icon(icon,
              color: filled ? const Color(0xFF4F585B) : doctorTeal, size: 18),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String body;
  final bool active;

  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.body,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: active ? doctorTeal2 : doctorNeutral,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: active ? Colors.white : const Color(0xFF6B7275),
                    size: 15),
              ),
              Expanded(child: Container(width: 1, color: doctorBorder)),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(time,
                      style: const TextStyle(color: doctorMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(title,
                      style: const TextStyle(
                          color: doctorText,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(body,
                      style: const TextStyle(
                          color: doctorMuted, fontSize: 14, height: 1.38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
