import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/service/patient_lookup_service.dart';

// States
abstract class PatientSearchState extends Equatable {
  const PatientSearchState();

  @override
  List<Object> get props => [];
}

class PatientSearchInitial extends PatientSearchState {}

class PatientSearchLoading extends PatientSearchState {}

class PatientSearchSuccess extends PatientSearchState {
  final List<Map<String, dynamic>> patients;

  const PatientSearchSuccess(this.patients);

  @override
  List<Object> get props => [patients];
}

class PatientSearchError extends PatientSearchState {
  final String message;

  const PatientSearchError(this.message);

  @override
  List<Object> get props => [message];
}

class PatientDetailsLoading extends PatientSearchState {}

class PatientDetailsSuccess extends PatientSearchState {
  final Map<String, dynamic> patientRecord;

  const PatientDetailsSuccess(this.patientRecord);

  @override
  List<Object> get props => [patientRecord];
}

// Cubit
class PatientSearchCubit extends Cubit<PatientSearchState> {
  PatientSearchCubit() : super(PatientSearchInitial());

  Future<void> searchPatientsByName(String searchQuery) async {
    if (searchQuery.isEmpty) {
      // Show all demo patients when search is empty
      emit(PatientSearchLoading());
      try {
        final patients = await PatientLookupService.searchPatientsByName('');
        emit(PatientSearchSuccess(patients));
      } catch (e) {
        emit(PatientSearchError('Failed to load patients: ${e.toString()}'));
      }
      return;
    }

    emit(PatientSearchLoading());

    try {
      final patients = await PatientLookupService.searchPatientsByName(searchQuery);
      emit(PatientSearchSuccess(patients));
    } catch (e) {
      emit(PatientSearchError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> findPatientByMedicalNumber(String medicalNumber) async {
    emit(PatientSearchLoading());

    try {
      final patient = await PatientLookupService.findPatientByMedicalNumber(medicalNumber);
      
      if (patient != null) {
        emit(PatientSearchSuccess([patient]));
      } else {
        emit(PatientSearchError('Patient not found with medical number: $medicalNumber'));
      }
    } catch (e) {
      emit(PatientSearchError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> getPatientMedicalRecord(String medicalNumber) async {
    emit(PatientDetailsLoading());

    try {
      final record = await PatientLookupService.getPatientMedicalRecord(medicalNumber);
      
      if (record != null) {
        emit(PatientDetailsSuccess(record));
      } else {
        emit(PatientSearchError('Medical record not found for: $medicalNumber'));
      }
    } catch (e) {
      emit(PatientSearchError('Failed to load medical record: ${e.toString()}'));
    }
  }

  void clearSearch() {
    emit(PatientSearchInitial());
  }

  Future<void> addMedicalEntry(
    String patientId,
    String entryType,
    Map<String, String> entryData,
  ) async {
    emit(PatientSearchLoading());

    try {
      await PatientLookupService.addMedicalEntry(patientId, entryType, entryData);
      
      // Refresh the patient record after adding entry
      final record = await PatientLookupService.getPatientMedicalRecord(patientId);
      
      if (record != null) {
        emit(PatientDetailsSuccess(record));
      } else {
        emit(PatientSearchError('Failed to refresh patient record after adding entry'));
      }
    } catch (e) {
      emit(PatientSearchError('Failed to add medical entry: ${e.toString()}'));
    }
  }
}
