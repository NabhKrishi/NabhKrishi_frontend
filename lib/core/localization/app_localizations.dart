import 'package:flutter/material.dart';

class AppLocalizations {
  final String language;

  AppLocalizations(this.language);

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'use_my_location': 'Use My Location',
      'select_farm_area': 'Select Farm Area',
      'draw_instruction': 'Tap on the map to draw your farm boundary.',
      'clear_boundary': 'Clear Area',
      'confirm_location': 'Confirm Farm Area',
      'confirm_farm_location': 'Confirm Farm Location',
      'weather_section': 'Weather Condition',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'rainfall_7d': 'Rainfall (7 Days)',
      'rainfall_14d': 'Rainfall (14 Days)',
      'et0_7d': 'ET0 (Water Demand)',
      'deficit_7d': 'Water Deficit',
      'field_condition': 'Soil / Field Condition',
      'estimated_water_condition': 'Estimated Field Water Condition',
      'low_stress': 'Low estimated water stress',
      'moderate_requirement': 'Moderate water requirement',
      'high_deficit': 'High estimated water deficit',
      'satellite_section': 'Sentinel-1 Satellite Information',
      'vv_mean': 'VV Mean',
      'vv_change': 'VV Change',
      'observation_age': 'Latest Observation Age',
      'satellite_freshness': 'Satellite data was updated {days} days ago.',
      'more_details': 'More Details',
      'irrigation_recommendation': 'Irrigation Recommendation',
      'apply_irrigation': 'Apply {amount} mm irrigation',
      'no_irrigation': 'No irrigation required',
      'explanation_title': 'Why this recommendation?',
      'loading_gps': 'Getting location...',
      'loading_weather': 'Fetching weather...',
      'loading_satellite': 'Fetching satellite data...',
      'loading_analysis': 'Analyzing field conditions...',
      'loading_recommendation': 'Generating irrigation recommendation...',
      'loading_cold_start': 'Starting NabhKrishi services...',
      'error_title': 'Something went wrong',
      'error_gps_denied': 'Location permission denied. Please allow GPS access.',
      'error_gps_unavailable': 'Location services are disabled on your device.',
      'error_502': 'Satellite data is temporarily unavailable. Please try again in a moment.',
      'error_generic': 'Connection error. Please try again.',
      'retry_button': 'Retry',
      'prediction_coordinate': 'Prediction Coordinate',
      'farm_boundary': 'Farm Boundary',
      'centroid_hint': 'Predictions are calculated at the center (centroid) of your selected area.',
      'insufficient_points': 'Please tap at least 3 points on the map to define your farm area.',
    },
    'hi': {
      'use_my_location': 'मेरी लोकेशन इस्तेमाल करें',
      'select_farm_area': 'खेत का चयन करें',
      'draw_instruction': 'अपने खेत की सीमा बनाने के लिए मानचित्र पर टैप करें।',
      'clear_boundary': 'क्षेत्र साफ़ करें',
      'confirm_location': 'खेत क्षेत्र की पुष्टि करें',
      'confirm_farm_location': 'खेत का स्थान पुष्टि करें',
      'weather_section': 'मौसम की स्थिति',
      'temperature': 'तापमान',
      'humidity': 'आर्द्रता',
      'rainfall_7d': 'वर्षा (पिछले 7 दिन)',
      'rainfall_14d': 'वर्षा (पिछले 14 दिन)',
      'et0_7d': 'ET0 (पानी की आवश्यकता)',
      'deficit_7d': 'पानी की कमी',
      'field_condition': 'मिट्टी / खेत की स्थिति',
      'estimated_water_condition': 'अनुमानित खेत की जल स्थिति',
      'low_stress': 'कम अनुमानित जल तनाव',
      'moderate_requirement': 'सामान्य पानी की आवश्यकता',
      'high_deficit': 'उच्च अनुमानित जल कमी',
      'satellite_section': 'सेंटिनल-1 सैटेलाइट जानकारी',
      'vv_mean': 'VV मीन (बैकस्कैटर)',
      'vv_change': 'VV बदलाव',
      'observation_age': 'नवीनतम अवलोकन काल',
      'satellite_freshness': 'सैटेलाइट डेटा {days} दिन पहले अपडेट हुआ था।',
      'more_details': 'अधिक जानकारी',
      'irrigation_recommendation': 'सिंचाई की सिफारिश',
      'apply_irrigation': '{amount} मिमी सिंचाई करें',
      'no_irrigation': 'सिंचाई की आवश्यकता नहीं है',
      'explanation_title': 'यह सिफारिश क्यों?',
      'loading_gps': 'लोकेशन प्राप्त की जा रही है...',
      'loading_weather': 'मौसम की जानकारी ली जा रही है...',
      'loading_satellite': 'सैटेलाइट डेटा प्राप्त किया जा रहा है...',
      'loading_analysis': 'खेत की स्थिति का विश्लेषण किया जा रहा है...',
      'loading_recommendation': 'सिंचाई की सिफारिश तैयार की जा रही है...',
      'loading_cold_start': 'नभकृषि सेवाएं शुरू हो रही हैं...',
      'error_title': 'कुछ गड़बड़ हो गई',
      'error_gps_denied': 'लोकेशन की अनुमति अस्वीकृत। कृपया जीपीएस एक्सेस प्रदान करें।',
      'error_gps_unavailable': 'आपके डिवाइस पर लोकेशन सेवाएं बंद हैं।',
      'error_502': 'सैटेलाइट डेटा अस्थायी रूप से अनुपलब्ध है। कृपया कुछ ही क्षणों में पुनः प्रयास करें।',
      'error_generic': 'कनेक्शन त्रुटि। कृपया पुनः प्रयास करें।',
      'retry_button': 'पुनः प्रयास करें',
      'prediction_coordinate': 'अनुमानित निर्देशांक',
      'farm_boundary': 'खेत की सीमा',
      'centroid_hint': 'अनुमान आपके चयनित क्षेत्र के केंद्र (सेंट्रॉइड) पर आधारित हैं।',
      'insufficient_points': 'कृपया अपने खेत के क्षेत्र को परिभाषित करने के लिए मानचित्र पर कम से कम 3 बिंदुओं को टैप करें।',
    }
  };

  String translate(String key, {Map<String, String>? arguments}) {
    final langCode = language.toLowerCase() == 'hindi' ? 'hi' : 'en';
    String value = _localizedValues[langCode]?[key] ?? key;
    if (arguments != null) {
      arguments.forEach((key, val) {
        value = value.replaceAll('{$key}', val);
      });
    }
    return value;
  }
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations(
    // We will retrieve the language from languageProvider.
    // In StatelessWidget/Widget build, we will pass it.
    'en', // Default, we will provide a better way via extensions if needed.
  );

  String translate(String key, String currentLanguage, {Map<String, String>? arguments}) {
    return AppLocalizations(currentLanguage).translate(key, arguments: arguments);
  }
}
