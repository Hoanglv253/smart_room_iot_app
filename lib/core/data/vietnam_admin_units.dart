class VietnamProvince {
  const VietnamProvince({required this.code, required this.name});

  final String code;
  final String name;
}

const vietnamProvinces = <VietnamProvince>[
  VietnamProvince(code: 'ha_noi', name: 'Hà Nội'),
  VietnamProvince(code: 'hue', name: 'Huế'),
  VietnamProvince(code: 'lai_chau', name: 'Lai Châu'),
  VietnamProvince(code: 'dien_bien', name: 'Điện Biên'),
  VietnamProvince(code: 'son_la', name: 'Sơn La'),
  VietnamProvince(code: 'lang_son', name: 'Lạng Sơn'),
  VietnamProvince(code: 'quang_ninh', name: 'Quảng Ninh'),
  VietnamProvince(code: 'thanh_hoa', name: 'Thanh Hóa'),
  VietnamProvince(code: 'nghe_an', name: 'Nghệ An'),
  VietnamProvince(code: 'ha_tinh', name: 'Hà Tĩnh'),
  VietnamProvince(code: 'cao_bang', name: 'Cao Bằng'),
  VietnamProvince(code: 'tuyen_quang', name: 'Tuyên Quang'),
  VietnamProvince(code: 'lao_cai', name: 'Lào Cai'),
  VietnamProvince(code: 'thai_nguyen', name: 'Thái Nguyên'),
  VietnamProvince(code: 'phu_tho', name: 'Phú Thọ'),
  VietnamProvince(code: 'bac_ninh', name: 'Bắc Ninh'),
  VietnamProvince(code: 'hung_yen', name: 'Hưng Yên'),
  VietnamProvince(code: 'hai_phong', name: 'Hải Phòng'),
  VietnamProvince(code: 'ninh_binh', name: 'Ninh Bình'),
  VietnamProvince(code: 'quang_tri', name: 'Quảng Trị'),
  VietnamProvince(code: 'da_nang', name: 'Đà Nẵng'),
  VietnamProvince(code: 'quang_ngai', name: 'Quảng Ngãi'),
  VietnamProvince(code: 'gia_lai', name: 'Gia Lai'),
  VietnamProvince(code: 'khanh_hoa', name: 'Khánh Hòa'),
  VietnamProvince(code: 'lam_dong', name: 'Lâm Đồng'),
  VietnamProvince(code: 'dak_lak', name: 'Đắk Lắk'),
  VietnamProvince(code: 'tp_ho_chi_minh', name: 'TP Hồ Chí Minh'),
  VietnamProvince(code: 'dong_nai', name: 'Đồng Nai'),
  VietnamProvince(code: 'tay_ninh', name: 'Tây Ninh'),
  VietnamProvince(code: 'can_tho', name: 'Cần Thơ'),
  VietnamProvince(code: 'vinh_long', name: 'Vĩnh Long'),
  VietnamProvince(code: 'dong_thap', name: 'Đồng Tháp'),
  VietnamProvince(code: 'ca_mau', name: 'Cà Mau'),
  VietnamProvince(code: 'an_giang', name: 'An Giang'),
];

List<String> get vietnamProvinceNames =>
    vietnamProvinces.map((province) => province.name).toList(growable: false);

String normalizeVietnamAdminText(Object? value) {
  return value?.toString().trim().toLowerCase() ?? '';
}
