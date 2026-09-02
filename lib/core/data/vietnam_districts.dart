import 'dart:convert';

import 'package:flutter/services.dart';

class VietnamDistrict {
  const VietnamDistrict({
    required this.id,
    required this.name,
    required this.legacyProvinceName,
  });

  final String id;
  final String name;
  final String legacyProvinceName;
}

class VietnamDistrictCatalog {
  const VietnamDistrictCatalog._();

  static const _assetPath = 'assets/data/vietnam_legacy_districts.json';

  // Legacy district areas are grouped into the 34 provincial units that have
  // operated since July 1, 2025. This preserves familiar address entry while
  // the current two-tier administration no longer has a district tier.
  static const _legacyProvinceCodes = <String, List<String>>{
    'an_giang': ['tinh_an_giang', 'tinh_kien_giang'],
    'bac_ninh': ['tinh_bac_ninh', 'tinh_bac_giang'],
    'ca_mau': ['tinh_ca_mau', 'tinh_bac_lieu'],
    'cao_bang': ['tinh_cao_bang'],
    'can_tho': [
      'thanh_pho_can_tho',
      'tinh_hau_giang',
      'tinh_soc_trang',
    ],
    'da_nang': ['thanh_pho_da_nang', 'tinh_quang_nam'],
    'dak_lak': ['tinh_dak_lak', 'tinh_phu_yen'],
    'dien_bien': ['tinh_dien_bien'],
    'dong_nai': ['tinh_dong_nai', 'tinh_binh_phuoc'],
    'dong_thap': ['tinh_dong_thap', 'tinh_tien_giang'],
    'gia_lai': ['tinh_gia_lai', 'tinh_binh_dinh'],
    'ha_noi': ['thanh_pho_ha_noi'],
    'ha_tinh': ['tinh_ha_tinh'],
    'hai_phong': ['thanh_pho_hai_phong', 'tinh_hai_duong'],
    'hue': ['thanh_pho_hue'],
    'hung_yen': ['tinh_hung_yen', 'tinh_thai_binh'],
    'khanh_hoa': ['tinh_khanh_hoa', 'tinh_ninh_thuan'],
    'lai_chau': ['tinh_lai_chau'],
    'lam_dong': ['tinh_lam_dong', 'tinh_binh_thuan', 'tinh_dak_nong'],
    'lang_son': ['tinh_lang_son'],
    'lao_cai': ['tinh_lao_cai', 'tinh_yen_bai'],
    'nghe_an': ['tinh_nghe_an'],
    'ninh_binh': ['tinh_ninh_binh', 'tinh_ha_nam', 'tinh_nam_dinh'],
    'phu_tho': ['tinh_phu_tho', 'tinh_vinh_phuc', 'tinh_hoa_binh'],
    'quang_ngai': ['tinh_quang_ngai', 'tinh_kon_tum'],
    'quang_ninh': ['tinh_quang_ninh'],
    'quang_tri': ['tinh_quang_tri', 'tinh_quang_binh'],
    'son_la': ['tinh_son_la'],
    'tay_ninh': ['tinh_tay_ninh', 'tinh_long_an'],
    'thai_nguyen': ['tinh_thai_nguyen', 'tinh_bac_kan'],
    'thanh_hoa': ['tinh_thanh_hoa'],
    'ho_chi_minh_city': [
      'thanh_pho_ho_chi_minh',
      'tinh_binh_duong',
      'tinh_ba_ria_vung_tau',
    ],
    'tuyen_quang': ['tinh_tuyen_quang', 'tinh_ha_giang'],
    'vinh_long': ['tinh_vinh_long', 'tinh_ben_tre', 'tinh_tra_vinh'],
  };

  static Future<List<VietnamDistrict>> forProvince(String provinceId) async {
    final legacyCodes = _legacyProvinceCodes[provinceId];
    if (legacyCodes == null) return const [];

    final provinces = await _loadLegacyProvinces();
    return [
      for (final province in provinces)
        if (legacyCodes.contains(province.codename))
          for (final district in province.districts)
            VietnamDistrict(
              id: district.code.toString(),
              name: district.name,
              legacyProvinceName: province.name,
            ),
    ];
  }

  static Future<List<_LegacyProvince>> _loadLegacyProvinces() {
    return _cachedProvinces ??= _readAsset();
  }

  static Future<List<_LegacyProvince>>? _cachedProvinces;

  static Future<List<_LegacyProvince>> _readAsset() async {
    final source = await rootBundle.loadString(_assetPath);
    final values = jsonDecode(source) as List<dynamic>;
    return values
        .cast<Map<String, dynamic>>()
        .map(_LegacyProvince.fromJson)
        .toList(growable: false);
  }
}

class _LegacyProvince {
  const _LegacyProvince({
    required this.name,
    required this.codename,
    required this.districts,
  });

  factory _LegacyProvince.fromJson(Map<String, dynamic> json) {
    return _LegacyProvince(
      name: json['name']! as String,
      codename: json['codename']! as String,
      districts: (json['districts']! as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(_LegacyDistrict.fromJson)
          .toList(growable: false),
    );
  }

  final String name;
  final String codename;
  final List<_LegacyDistrict> districts;
}

class _LegacyDistrict {
  const _LegacyDistrict({required this.code, required this.name});

  factory _LegacyDistrict.fromJson(Map<String, dynamic> json) {
    return _LegacyDistrict(
      code: json['code']! as int,
      name: json['name']! as String,
    );
  }

  final int code;
  final String name;
}
