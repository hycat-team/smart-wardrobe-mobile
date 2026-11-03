/// Curated vocabulary for "Gu của tôi".
///
/// Vietnamese labels mirror production `fashion.fashion_items.style` values, and the backend taxonomy
/// maps the unaccented forms of the five canonical families (toi gian, thanh lich, sang trong, duong pho,
/// ca tinh, co dien, hoc duong), so a Vietnamese chip matches wardrobe metadata and cold-start
/// suggestions better than English.
const List<String> likedStyleOptions = [
  'Tối giản',
  'Thanh lịch',
  'Sang trọng',
  'Công sở',
  'Lịch lãm',
  'Cổ điển',
  'Vintage',
  'Retro',
  'Học đường',
  'Preppy',
  'Thường ngày',
  'Năng động',
  'Thể thao',
  'Athleisure',
  'Đường phố',
  'Cá tính',
  'Workwear',
  'Gorpcore',
  'Nữ tính',
  'Lãng mạn',
  'Boho',
  'Y2K',
  'Hàn Quốc',
  'Nhật Bản',
];

const List<String> avoidedStyleOptions = [
  'Đường phố',
  'Thể thao',
  'Cá tính',
  'Y2K',
  'Sặc sỡ',
  'Cầu kỳ',
  'Nữ tính',
  'Lãng mạn',
  'Boho',
  'Cổ điển',
  'Sang trọng',
  'Học đường',
  'Workwear',
  'Vintage',
];

const int maxStyleLength = 50;
