import 'content_text.dart';

/// Türkçe: boss blind'lar (ad + zayıflatma kuralı) ve başlangıç desteleri.
final Map<String, ContentText> trWorld = {
  'boss_wall': const ContentText('Duvar', 'Hedef, Ante tabanının 4 katı'),
  'boss_needle': const ContentText('İğne', 'Yalnızca 2 hamle'),
  'boss_water': const ContentText('Su', '0 atma ile başlarsın'),
  'boss_flint': const ContentText(
    'Çakmaktaşı',
    'Temel Çip ve Çarpan yarıya iner',
  ),
  'boss_eye': const ContentText(
    'Göz',
    'Her temizleme türü yalnızca bir kez puan verir',
  ),
  'boss_pillar': const ContentText('Sütun', 'Tahta kalıntısı puanlanmaz'),
  'boss_violet_vessel': const ContentText(
    'Mor Kap',
    'Final: joker XÇarpanı yarıya iner',
  ),
  'boss_window': const ContentText(
    'Pencere',
    'Geliştirmeler ve edisyonlar işe yaramaz',
  ),
  'boss_mouth': const ContentText(
    'Ağız',
    'Yalnızca ilk temizleme türü puan verir',
  ),
  'boss_tooth': const ContentText(
    'Diş',
    'Her temizleyen yerleştirmede \$1 kaybedersin',
  ),
  'deck_standard': const ContentText(
    'Standart Deste',
    'Dengeli klasik: dört renkte 24 şeklin hepsi, her blind 5 hamle ve '
        '3 atma.',
  ),
  'deck_monolith_cube': const ContentText(
    'Küp Envanteri',
    'Torbada YALNIZCA 2x2 ve 3x3 kareler var. Yoğun ve ağır; kare ve ağır '
        'parça jokerleri için ideal ama yerleştirmesi acımasız.',
  ),
  'deck_crimson_recycler': const ContentText(
    'Geri Dönüşüm Destesi',
    'Her blind +1 atma: hepsine 4 atma ile başlarsın.',
  ),
  'deck_azure_architect': const ContentText(
    'Mimar Destesi',
    'Her blind +1 hamle: hepsine 6 hamle ile başlarsın.',
  ),
  'deck_chromatic_flush': const ContentText(
    'İkili Renk Destesi',
    'Bloklar dört renk yerine yalnızca Kırmızı ve Mavi gelir; Kırmızı '
        'Hücum ve Mavi Dalga gibi renk jokerleri çok daha sık tetiklenir.',
  ),
};
