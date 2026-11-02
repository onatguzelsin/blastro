import 'content_text.dart';
import 'consumable_strings_tr.dart';

/// Türkçe: jokerler (ad, açıklama, kart üstü kısa yazı), sonra kartlar.
final Map<String, ContentText> trCards = {
  ...trConsumables,
  'joker_cornerstone': const ContentText(
    'Köşe Taşı',
    'Tahtada kalan her dolu köşe hücresi için +20 Çip.',
    '+20 / köşe',
  ),
  'joker_3x3_sanctuary': const ContentText(
    '3x3 Sığınak',
    'Tahtada tamamen dolu bir 3x3 blok kalırsa x2 Çarpan.',
    '3x3\'te x2',
  ),
  'joker_seven_fingers': const ContentText(
    'Yedi Parmak',
    '7. satır veya sütunda temizlenen her hücre için +7 Çip.',
    '7. hatta +7',
  ),
  'joker_heavyweight': const ContentText(
    'Ağır Sıklet',
    'Yerleştirilen parçanın tehlike seviyesi 4 ise +8 Çarpan.',
    'Ağırsa +8',
  ),
  'joker_plain': const ContentText(
    'Sade Joker',
    'Puan veren her hamlede +4 Çarpan.',
    '+4 Çarpan',
  ),
  'joker_chip_collector': const ContentText(
    'Çip Koleksiyoncusu',
    'Puan veren her hamlede +30 Çip.',
    '+30 Çip',
  ),
  'joker_amplifier': const ContentText(
    'Yükseltici',
    'Puan veren her hamlede x1.5 Çarpan.',
    'x1.5',
  ),
  'joker_combo_banker': const ContentText(
    'Kombo Bankacısı',
    'Aktif kombo serisinin her seviyesi için +2 Çarpan.',
    '+2 / seri',
  ),
  'joker_crossroads': const ContentText(
    'Kavşak',
    'Kesişen Artı\'nın kesişim hücresi her puan verdiğinde +10 Çip.',
    '+10 kesişim',
  ),
  'joker_tidy_up': const ContentText(
    'Derli Toplu',
    'Temizlikten sonra tahtada 8 veya daha az hücre kalırsa x2 Çarpan.',
    'Derliyse x2',
  ),
  'joker_gyroscope': const ContentText(
    'Cayroskop',
    'Bir tepsi parçasına dokunarak onu döndür.',
    'Döndür',
  ),
  'joker_streak_saver': const ContentText(
    'Seri Koruyucu',
    'Kombon, temizlemeyen 1 fazladan yerleştirmeden sağ çıkar.',
    '+1 hazırlık',
  ),
  'joker_blueprint': const ContentText(
    'Taslak',
    'Sağındaki jokeri kopyalar.',
    'Sağı kopyala',
  ),
  'joker_brainstorm': const ContentText(
    'Beyin Fırtınası',
    'En soldaki jokeri kopyalar.',
    'İlki kopyala',
  ),
  'joker_mime': const ContentText(
    'Pandomim',
    'Tahta kalıntısı etkilerini bir kez daha tetikler.',
    'Tekrar tetikle',
  ),
  'joker_baron_of_steel': const ContentText(
    'Çelik Baron',
    'Kalıntıdaki Çelik hücreler x1.5 yerine x2 Çarpan verir.',
    'Çelik x2',
  ),
  'joker_lucky_charm': const ContentText(
    'Şans Tılsımı',
    'Şans hücreleri her zaman tetiklenir.',
    'Hep şanslı',
  ),
  'joker_pocket_change': const ContentText(
    'Bozuk Para',
    'Bir blind\'ın parasını her aldığında fazladan \$2 kazan.',
    '+\$2 kasa',
  ),
  'joker_extra_tray': const ContentText(
    'Ekstra Hamle',
    'Her blind +1 hamle.',
    '+1 hamle',
  ),
  'joker_discard_hoarder': const ContentText(
    'Atma Stokçusu',
    'Her blind +1 atma.',
    '+1 atma',
  ),
  'joker_singularity': const ContentText(
    'Tekillik',
    'Puan veren her hamlede x3 Çarpan.',
    'x3 Çarpan',
  ),
  'joker_phoenix_feather': const ContentText(
    'Anka Tüyü',
    'Temizlemeden kaç hamle geçerse geçsin kombon asla sıfırlanmaz.',
    'Kombo yaşar',
  ),
  'joker_grand_architect': const ContentText(
    'Başmimar',
    'Hamlenin temizlediği her çizgi için x1.5 Çarpan (birbiriyle çarpılır).',
    'x1.5 / çizgi',
  ),
  'joker_red_rush': const ContentText(
    'Kırmızı Hücum',
    'Temizlemede puan veren her kırmızı hücre için +1 Çarpan.',
    '+1 / kırmızı',
  ),
  'joker_blue_tide': const ContentText(
    'Mavi Dalga',
    'Temizlemede puan veren her mavi hücre için +8 Çip.',
    '+8 / mavi',
  ),
};
