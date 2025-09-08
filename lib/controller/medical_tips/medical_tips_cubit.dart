import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../data/model/medical_tips_model.dart';
import '../../data/source/remote/medical_tips_service.dart';

part 'medical_tips_state.dart';

class MedicalTipsCubit extends Cubit<MedicalTipsState> {
  final MedicalTipsService _medicalTipsService = MedicalTipsService();

  MedicalTipsCubit() : super(MedicalTipsInitial());

  Future<void> fetchDailyTip() async {
    try {
      emit(MedicalTipsLoading());
      // Use fallback medical tip instead of API call
      final fallbackTip = MedicalTip(
        id: 1,
        title: "Medical Tips",
        content: "Practice good general hygiene, such as frequent handwashing to prevent illness",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );
      emit(MedicalTipsLoaded(fallbackTip));
    } catch (e) {
      emit(MedicalTipsError(e.toString()));
    }
  }
}
