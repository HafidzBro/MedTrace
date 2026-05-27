import 'package:medtrace/core/error/exceptions.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/data/models/doctor_code_usage_model.dart';
import 'package:medtrace/services/supabase/doctor_service.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class DoctorCodeService {
  final SupabaseServiceContext context;
  final DoctorService doctors;

  const DoctorCodeService(this.context, this.doctors);

  Future<String> generate({
    required String doctorId,
    int maxUses = 1,
    int expiryDays = 30,
  }) async {
    final resolvedDoctorId = await doctors.resolveDoctorId(doctorId);
    final code = context.generateCode();
    final expiresAt = DateTime.now().add(Duration(days: expiryDays));

    await context.client.from('doctor_codes').insert({
      'doctor_id': resolvedDoctorId,
      'code': code,
      'max_uses': maxUses,
      'expires_at': expiresAt.toIso8601String(),
    });

    return code;
  }

  Future<DoctorCodeModel> validate(String code) async {
    final response = await context.client
        .from('doctor_codes')
        .select()
        .eq('code', code.trim().toUpperCase())
        .maybeSingle();

    if (response == null) {
      throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code');
    }

    final doctorCode = DoctorCodeModel.fromJson(response);
    if (!doctorCode.canBeUsed) {
      throw InvalidDoctorCodeException(
          message: 'Invalid or expired doctor code');
    }

    return doctorCode;
  }

  Future<List<DoctorCodeModel>> listForDoctor(String doctorId) async {
    final resolvedDoctorId = await doctors.resolveDoctorId(doctorId);
    final response = await context.client
        .from('doctor_codes')
        .select()
        .eq('doctor_id', resolvedDoctorId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => DoctorCodeModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorCodeUsageModel>> listUsages(String codeId) async {
    final response = await context.client
        .from('doctor_code_usages')
        .select()
        .eq('code_id', codeId)
        .order('used_at', ascending: false);

    return (response as List)
        .map(
            (row) => DoctorCodeUsageModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}
