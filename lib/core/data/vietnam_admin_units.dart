class VietnamProvince {
  const VietnamProvince({required this.code, required this.name});

  final String code;
  final String name;
}

const vietnamProvinces = <VietnamProvince>[
  VietnamProvince(code: 'ha_noi', name: 'Ha Noi'),
  VietnamProvince(code: 'hue', name: 'Hue'),
  VietnamProvince(code: 'lai_chau', name: 'Lai Chau'),
  VietnamProvince(code: 'dien_bien', name: 'Dien Bien'),
  VietnamProvince(code: 'son_la', name: 'Son La'),
  VietnamProvince(code: 'lang_son', name: 'Lang Son'),
  VietnamProvince(code: 'quang_ninh', name: 'Quang Ninh'),
  VietnamProvince(code: 'thanh_hoa', name: 'Thanh Hoa'),
  VietnamProvince(code: 'nghe_an', name: 'Nghe An'),
  VietnamProvince(code: 'ha_tinh', name: 'Ha Tinh'),
  VietnamProvince(code: 'cao_bang', name: 'Cao Bang'),
  VietnamProvince(code: 'tuyen_quang', name: 'Tuyen Quang'),
  VietnamProvince(code: 'lao_cai', name: 'Lao Cai'),
  VietnamProvince(code: 'thai_nguyen', name: 'Thai Nguyen'),
  VietnamProvince(code: 'phu_tho', name: 'Phu Tho'),
  VietnamProvince(code: 'bac_ninh', name: 'Bac Ninh'),
  VietnamProvince(code: 'hung_yen', name: 'Hung Yen'),
  VietnamProvince(code: 'hai_phong', name: 'Hai Phong'),
  VietnamProvince(code: 'ninh_binh', name: 'Ninh Binh'),
  VietnamProvince(code: 'quang_tri', name: 'Quang Tri'),
  VietnamProvince(code: 'da_nang', name: 'Da Nang'),
  VietnamProvince(code: 'quang_ngai', name: 'Quang Ngai'),
  VietnamProvince(code: 'gia_lai', name: 'Gia Lai'),
  VietnamProvince(code: 'khanh_hoa', name: 'Khanh Hoa'),
  VietnamProvince(code: 'lam_dong', name: 'Lam Dong'),
  VietnamProvince(code: 'dak_lak', name: 'Dak Lak'),
  VietnamProvince(code: 'tp_ho_chi_minh', name: 'TP Ho Chi Minh'),
  VietnamProvince(code: 'dong_nai', name: 'Dong Nai'),
  VietnamProvince(code: 'tay_ninh', name: 'Tay Ninh'),
  VietnamProvince(code: 'can_tho', name: 'Can Tho'),
  VietnamProvince(code: 'vinh_long', name: 'Vinh Long'),
  VietnamProvince(code: 'dong_thap', name: 'Dong Thap'),
  VietnamProvince(code: 'ca_mau', name: 'Ca Mau'),
  VietnamProvince(code: 'an_giang', name: 'An Giang'),
];

List<String> get vietnamProvinceNames =>
    vietnamProvinces.map((province) => province.name).toList(growable: false);

String normalizeVietnamAdminText(Object? value) {
  return (value?.toString() ?? '').trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
}
