import 'dart:math';
import '../../data/model/find_hospital_place_info.dart';

class MapsDummyDataService {
  static const List<Map<String, dynamic>> _dummyHospitals = [
    {
      'name': 'TouchHealth General Hospital',
      'lat': -26.2041,
      'lng': 28.0473,
      'business_status': 'OPERATIONAL',
      'rating': 4.5,
      'user_ratings_total': 1250,
      'formatted_phone_number': '(011) 123-4567',
      'international_phone_number': '+27 11 123 4567',
      'formatted_address': '123 Medical Drive, Johannesburg, 2000, South Africa',
      'vicinity': 'Johannesburg CBD',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJtouchhealth001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://touchhealth-general.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'touchhealth_hospital_001',
          'html_attributions': ['TouchHealth General Hospital']
        }
      ]
    },
    {
      'name': 'Sandton Medical Centre',
      'lat': -26.1076,
      'lng': 28.0567,
      'business_status': 'OPERATIONAL',
      'rating': 4.2,
      'user_ratings_total': 890,
      'formatted_phone_number': '(011) 234-5678',
      'international_phone_number': '+27 11 234 5678',
      'formatted_address': '456 Rivonia Road, Sandton, 2196, South Africa',
      'vicinity': 'Sandton',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJsandton_medical_001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://sandton-medical.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'sandton_medical_001',
          'html_attributions': ['Sandton Medical Centre']
        }
      ]
    },
    {
      'name': 'Rosebank Emergency Clinic',
      'lat': -26.1448,
      'lng': 28.0436,
      'business_status': 'OPERATIONAL',
      'rating': 3.8,
      'user_ratings_total': 456,
      'formatted_phone_number': '(011) 345-6789',
      'international_phone_number': '+27 11 345 6789',
      'formatted_address': '789 Oxford Road, Rosebank, 2196, South Africa',
      'vicinity': 'Rosebank',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJrosebank_emergency_001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://rosebank-emergency.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'rosebank_emergency_001',
          'html_attributions': ['Rosebank Emergency Clinic']
        }
      ]
    },
    {
      'name': 'Melville Family Practice',
      'lat': -26.1885,
      'lng': 28.0065,
      'business_status': 'OPERATIONAL',
      'rating': 4.7,
      'user_ratings_total': 234,
      'formatted_phone_number': '(011) 456-7890',
      'international_phone_number': '+27 11 456 7890',
      'formatted_address': '321 Main Road, Melville, 2109, South Africa',
      'vicinity': 'Melville',
      'opening_hours': {'open_now': false},
      'place_id': 'ChIJmelville_family_001',
      'types': ['doctor', 'health', 'establishment'],
      'website': 'https://melville-family.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/doctor-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'melville_family_001',
          'html_attributions': ['Melville Family Practice']
        }
      ]
    },
    {
      'name': 'Parktown North Specialist Hospital',
      'lat': -26.1523,
      'lng': 28.0342,
      'business_status': 'OPERATIONAL',
      'rating': 4.3,
      'user_ratings_total': 678,
      'formatted_phone_number': '(011) 567-8901',
      'international_phone_number': '+27 11 567 8901',
      'formatted_address': '654 Jan Smuts Avenue, Parktown North, 2193, South Africa',
      'vicinity': 'Parktown North',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJparktown_specialist_001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://parktown-specialist.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'parktown_specialist_001',
          'html_attributions': ['Parktown North Specialist Hospital']
        }
      ]
    },
    {
      'name': 'Fourways Life Hospital',
      'lat': -25.9890,
      'lng': 28.0123,
      'business_status': 'OPERATIONAL',
      'rating': 4.1,
      'user_ratings_total': 1100,
      'formatted_phone_number': '(011) 678-9012',
      'international_phone_number': '+27 11 678 9012',
      'formatted_address': '987 Witkoppen Road, Fourways, 2055, South Africa',
      'vicinity': 'Fourways',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJfourways_life_001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://fourways-life.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'fourways_life_001',
          'html_attributions': ['Fourways Life Hospital']
        }
      ]
    },
    {
      'name': 'Randburg Medical Centre',
      'lat': -26.0942,
      'lng': 27.9823,
      'business_status': 'OPERATIONAL',
      'rating': 3.9,
      'user_ratings_total': 345,
      'formatted_phone_number': '(011) 789-0123',
      'international_phone_number': '+27 11 789 0123',
      'formatted_address': '147 Republic Road, Randburg, 2194, South Africa',
      'vicinity': 'Randburg',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJrandburg_medical_001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://randburg-medical.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'randburg_medical_001',
          'html_attributions': ['Randburg Medical Centre']
        }
      ]
    },
    {
      'name': 'Bryanston Emergency Unit',
      'lat': -26.0456,
      'lng': 28.0189,
      'business_status': 'OPERATIONAL',
      'rating': 4.0,
      'user_ratings_total': 567,
      'formatted_phone_number': '(011) 890-1234',
      'international_phone_number': '+27 11 890 1234',
      'formatted_address': '258 William Nicol Drive, Bryanston, 2021, South Africa',
      'vicinity': 'Bryanston',
      'opening_hours': {'open_now': true},
      'place_id': 'ChIJbryanston_emergency_001',
      'types': ['hospital', 'health', 'establishment'],
      'website': 'https://bryanston-emergency.co.za',
      'icon': 'https://maps.gstatic.com/mapfiles/place_api/icons/v1/png_71/hospital-71.png',
      'photos': [
        {
          'height': 1080,
          'width': 1920,
          'photo_reference': 'bryanston_emergency_001',
          'html_attributions': ['Bryanston Emergency Unit']
        }
      ]
    }
  ];

  /// Generate dummy hospital data based on user's location
  static List<FindHospitalsPlaceInfo> generateDummyHospitals({
    required double userLat,
    required double userLng,
    double radiusKm = 10.0,
  }) {
    final Random random = Random();
    final List<FindHospitalsPlaceInfo> hospitals = [];

    for (int i = 0; i < _dummyHospitals.length; i++) {
      final hospitalData = Map<String, dynamic>.from(_dummyHospitals[i]);
      
      // Calculate distance and duration from user location
      final distance = _calculateDistance(
        userLat, 
        userLng, 
        hospitalData['lat'], 
        hospitalData['lng']
      );
      
      // Only include hospitals within radius
      if (distance <= radiusKm) {
        // Add calculated distance and estimated duration
        hospitalData['distance'] = '${distance.toStringAsFixed(1)} km';
        hospitalData['duration'] = '${(distance * 3 + random.nextInt(10)).toInt()} min';
        
        // Add geometry data for proper parsing
        hospitalData['geometry'] = {
          'location': {
            'lat': hospitalData['lat'],
            'lng': hospitalData['lng']
          },
          'viewport': {
            'northeast': {
              'lat': hospitalData['lat'] + 0.01,
              'lng': hospitalData['lng'] + 0.01
            },
            'southwest': {
              'lat': hospitalData['lat'] - 0.01,
              'lng': hospitalData['lng'] - 0.01
            }
          }
        };

        // Add plus_code for address components
        hospitalData['plus_code'] = {
          'compound_code': '${_generatePlusCode(hospitalData['lat'], hospitalData['lng'])} Johannesburg, South Africa',
          'global_code': _generateGlobalPlusCode(hospitalData['lat'], hospitalData['lng'])
        };

        hospitals.add(FindHospitalsPlaceInfo.fromJson(hospitalData));
      }
    }

    // Sort by distance (closest first)
    hospitals.sort((a, b) {
      final distanceA = double.tryParse(a.distance?.split(' ')[0] ?? '0') ?? 0;
      final distanceB = double.tryParse(b.distance?.split(' ')[0] ?? '0') ?? 0;
      return distanceA.compareTo(distanceB);
    });

    return hospitals;
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Generate a mock Plus Code for the location
  static String _generatePlusCode(double lat, double lng) {
    final Random random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 4; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    return '${code}+${code.substring(0, 2)}';
  }

  /// Generate a mock global Plus Code
  static String _generateGlobalPlusCode(double lat, double lng) {
    final Random random = Random();
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[random.nextInt(chars.length)];
    }
    return '${code.substring(0, 4)}+${code.substring(4, 8)}';
  }

  /// Get a specific hospital by name (for testing)
  static FindHospitalsPlaceInfo? getHospitalByName(String name) {
    final hospitalData = _dummyHospitals.firstWhere(
      (hospital) => hospital['name'].toLowerCase().contains(name.toLowerCase()),
      orElse: () => _dummyHospitals.first,
    );

    final data = Map<String, dynamic>.from(hospitalData);
    
    // Add required geometry data
    data['geometry'] = {
      'location': {
        'lat': data['lat'],
        'lng': data['lng']
      }
    };

    return FindHospitalsPlaceInfo.fromJson(data);
  }

  /// Generate popular search locations for the search bar
  static List<Map<String, dynamic>> getPopularHealthcareLocations() {
    return [
      {
        'name': 'Nearest Hospital',
        'description': 'Find the closest hospital to your location',
        'type': 'hospital'
      },
      {
        'name': 'Emergency Room',
        'description': 'Locate emergency medical services',
        'type': 'emergency'
      },
      {
        'name': 'Pharmacy',
        'description': 'Find nearby pharmacies and drugstores',
        'type': 'pharmacy'
      },
      {
        'name': 'General Practitioner',
        'description': 'Locate family doctors and GPs',
        'type': 'doctor'
      },
      {
        'name': 'Specialist Clinic',
        'description': 'Find specialist medical clinics',
        'type': 'clinic'
      },
      {
        'name': 'Dental Clinic',
        'description': 'Locate dental practices and orthodontists',
        'type': 'dentist'
      }
    ];
  }
}
