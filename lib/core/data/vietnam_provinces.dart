class VietnamProvince {
  const VietnamProvince({
    required this.id,
    required this.name,
    this.isMunicipality = false,
  });

  final String id;
  final String name;
  final bool isMunicipality;
}

/// Provincial-level administrative units operating from July 1, 2025.
const vietnamProvinces = <VietnamProvince>[
  VietnamProvince(id: 'an_giang', name: 'An Giang'),
  VietnamProvince(id: 'bac_ninh', name: 'Bắc Ninh'),
  VietnamProvince(id: 'ca_mau', name: 'Cà Mau'),
  VietnamProvince(id: 'cao_bang', name: 'Cao Bằng'),
  VietnamProvince(id: 'can_tho', name: 'Cần Thơ', isMunicipality: true),
  VietnamProvince(id: 'da_nang', name: 'Đà Nẵng', isMunicipality: true),
  VietnamProvince(id: 'dak_lak', name: 'Đắk Lắk'),
  VietnamProvince(id: 'dien_bien', name: 'Điện Biên'),
  VietnamProvince(id: 'dong_nai', name: 'Đồng Nai'),
  VietnamProvince(id: 'dong_thap', name: 'Đồng Tháp'),
  VietnamProvince(id: 'gia_lai', name: 'Gia Lai'),
  VietnamProvince(id: 'ha_noi', name: 'Hà Nội', isMunicipality: true),
  VietnamProvince(id: 'ha_tinh', name: 'Hà Tĩnh'),
  VietnamProvince(id: 'hai_phong', name: 'Hải Phòng', isMunicipality: true),
  VietnamProvince(id: 'hue', name: 'Huế', isMunicipality: true),
  VietnamProvince(id: 'hung_yen', name: 'Hưng Yên'),
  VietnamProvince(id: 'khanh_hoa', name: 'Khánh Hòa'),
  VietnamProvince(id: 'lai_chau', name: 'Lai Châu'),
  VietnamProvince(id: 'lam_dong', name: 'Lâm Đồng'),
  VietnamProvince(id: 'lang_son', name: 'Lạng Sơn'),
  VietnamProvince(id: 'lao_cai', name: 'Lào Cai'),
  VietnamProvince(id: 'nghe_an', name: 'Nghệ An'),
  VietnamProvince(id: 'ninh_binh', name: 'Ninh Bình'),
  VietnamProvince(id: 'phu_tho', name: 'Phú Thọ'),
  VietnamProvince(id: 'quang_ngai', name: 'Quảng Ngãi'),
  VietnamProvince(id: 'quang_ninh', name: 'Quảng Ninh'),
  VietnamProvince(id: 'quang_tri', name: 'Quảng Trị'),
  VietnamProvince(id: 'son_la', name: 'Sơn La'),
  VietnamProvince(id: 'tay_ninh', name: 'Tây Ninh'),
  VietnamProvince(id: 'thai_nguyen', name: 'Thái Nguyên'),
  VietnamProvince(id: 'thanh_hoa', name: 'Thanh Hóa'),
  VietnamProvince(
    id: 'ho_chi_minh_city',
    name: 'Thành phố Hồ Chí Minh',
    isMunicipality: true,
  ),
  VietnamProvince(id: 'tuyen_quang', name: 'Tuyên Quang'),
  VietnamProvince(id: 'vinh_long', name: 'Vĩnh Long'),
];
