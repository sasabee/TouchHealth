import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:touchhealth/core/utils/theme/color.dart';
import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/controller/auth/practitioner_auth/practitioner_auth_cubit.dart';
import 'package:touchhealth/controller/practitioner/patient_search_cubit.dart';
import 'package:touchhealth/core/router/routes.dart';

class PractitionerDashboard extends StatefulWidget {
  const PractitionerDashboard({super.key});

  @override
  State<PractitionerDashboard> createState() => _PractitionerDashboardState();
}

class _PractitionerDashboardState extends State<PractitionerDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _medicalNumberController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _medicalNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: ColorManager.green,
        elevation: 0,
        title: Text(
          'Practitioner Dashboard',
          style: context.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: ColorManager.error),
                    Gap(8.w),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            Gap(20.h),
            _buildQuickActions(),
            Gap(20.h),
            _buildPatientSearch(),
            Gap(20.h),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return BlocBuilder<PractitionerAuthCubit, PractitionerAuthState>(
      builder: (context, state) {
        if (state is PractitionerAuthSuccess) {
          final practitioner = state.practitioner;
          return Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ColorManager.green, ColorManager.green.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25.r,
                      backgroundColor: Colors.white,
                      child: Icon(
                        practitioner.practitionerType == 'nurse' 
                            ? Icons.local_hospital 
                            : Icons.medical_services,
                        color: ColorManager.green,
                        size: 30.w,
                      ),
                    ),
                    Gap(12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            practitioner.name,
                            style: context.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${practitioner.specialization} • ${practitioner.department}',
                            style: context.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Gap(12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'License: ${practitioner.licenseNumber}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap(12.h),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search,
                title: 'Find Patient',
                subtitle: 'Search by medical number',
                color: ColorManager.green,
                onTap: () => _showMedicalNumberDialog(),
              ),
            ),
            Gap(12.w),
            Expanded(
              child: _buildActionCard(
                icon: Icons.people,
                title: 'Browse Patients',
                subtitle: 'View all patients',
                color: Colors.blue,
                onTap: () => _searchAllPatients(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.w),
            Gap(8.h),
            Text(
              title,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Gap(4.h),
            Text(
              subtitle,
              style: context.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Patient Search',
          style: context.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Gap(12.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by patient name...',
              prefixIcon: Icon(Icons.search, color: ColorManager.green),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<PatientSearchCubit>().clearSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              if (value.isNotEmpty && value.length >= 2) {
                context.read<PatientSearchCubit>().searchPatientsByName(value);
              } else {
                context.read<PatientSearchCubit>().clearSearch();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return BlocBuilder<PatientSearchCubit, PatientSearchState>(
      builder: (context, state) {
        if (state is PatientSearchLoading) {
          return Center(
            child: CircularProgressIndicator(color: ColorManager.green),
          );
        }
        
        if (state is PatientSearchSuccess) {
          if (state.patients.isEmpty) {
            return _buildEmptyState();
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search Results (${state.patients.length})',
                style: context.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Gap(12.h),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: state.patients.length,
                itemBuilder: (context, index) {
                  final patient = state.patients[index];
                  return _buildPatientCard(patient);
                },
              ),
            ],
          );
        }
        
        if (state is PatientSearchError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48.w, color: ColorManager.error),
                Gap(8.h),
                Text(
                  'Error: ${state.message}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: ColorManager.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }
        
        return _buildEmptyState();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.search_off, size: 48.w, color: Colors.grey),
          Gap(8.h),
          Text(
            'No patients found',
            style: context.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          Gap(4.h),
          Text(
            'Try searching by name or medical number',
            style: context.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewPatientDetails(patient),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25.r,
              backgroundColor: ColorManager.green.withOpacity(0.1),
              child: Icon(
                patient['gender'] == 'Male' ? Icons.man : Icons.woman,
                color: ColorManager.green,
                size: 30.w,
              ),
            ),
            Gap(12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient['name'] ?? 'Unknown Patient',
                    style: context.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Gap(4.h),
                  Text(
                    'Medical #: ${patient['medicalNumber']}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: ColorManager.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Gap(2.h),
                  Text(
                    '${patient['age']} years • ${patient['gender']} • ${patient['bloodType']}',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16.w,
            ),
          ],
        ),
      ),
    );
  }

  void _showMedicalNumberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Find Patient'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the patient\'s medical number:'),
              Gap(12.h),
              TextField(
                controller: _medicalNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g., MED000001',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_medicalNumberController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  context.read<PatientSearchCubit>()
                      .findPatientByMedicalNumber(_medicalNumberController.text);
                  _medicalNumberController.clear();
                }
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _searchAllPatients() {
    context.read<PatientSearchCubit>().searchPatientsByName('');
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    Navigator.pushNamed(
      context,
      RouteManager.patientDetails,
      arguments: patient,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<PractitionerAuthCubit>().signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteManager.practitionerLogin,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.error,
              ),
              child: Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
