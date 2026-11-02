import 'str_key.dart';
import 'str_keys_help.dart';

/// Türkçe: Nasıl Oynanır.
final Map<StrKey, String> trHelp = {
  HelpStr.title: 'Nasıl Oynanır',
  HelpStr.goalHead: 'Amaç',
  HelpStr.goalBody:
      'Her Ante üç blind içerir: Küçük, Büyük ve bir Boss. Bir blind\'ı '
      'geçmek için hedef skora ulaş. Ante 8 Boss\'unu yenersen kazanırsın; '
      'sonra Sonsuz Mod\'da Ante 39\'a kadar devam edebilirsin.',
  HelpStr.placingHead: 'Parça yerleştirme',
  HelpStr.placingBody:
      'Tepsideki bir parçayı 8x8 tahtaya sürükle. Parça, görebilesin diye '
      'parmağının üstünde çizilir. Bir satırı ya da sütunu tamamen doldurarak '
      'temizle. 3 parçanın hepsini yerleştirince yeni tepsi gelir.',
  HelpStr.scoringHead: 'Skor: Çip x Çarpan',
  HelpStr.scoringBody:
      '1. Temizleme türü temel Çip ve Çarpan\'ı belirler, kombon da eklenir.\n'
      '2. Temizlenen her hücre Çip ekler (satır ile sütunun kesiştiği hücre '
      'iki kez puan verir).\n'
      '3. Tahtada kalan hücreler de puan verebilir (Çelik x1.5).\n'
      '4. Jokerler soldan sağa işler, yani sıraları önemlidir.',
  HelpStr.comboHead: 'Kombo',
  HelpStr.comboBody:
      'Her temizleyen hamle kombonu büyütür ve Çarpan ekler. Temizlemeden '
      'üst üste 2 hamle yapabilirsin; 3.sü kombonu sıfırlar.',
  HelpStr.traysHead: 'Hamle ve atma',
  HelpStr.traysBody:
      'Her blind sana sınırlı sayıda hamle verir. Atma, henüz yerleştirmediğin '
      'parçaları yeniler. Bir blind\'ı geçince artan parçalar atılır ve '
      'tepsin baştan dolar. Boss yenilene kadar tahtan olduğu gibi kalır.',
  HelpStr.blindsHead: 'Blind\'lar, atlama ve boss\'lar',
  HelpStr.blindsBody:
      'Blind\'lar arasında neyi oynayacağını seçersin. Küçük ve Büyük blind '
      'atlanabilir ama ödülünü ve mağazayı kaybedersin. Boss atlanamaz ve bir '
      'zayıflatması vardır: kuralı önceden kartında, tur boyunca kırmızı '
      'bir şeritte gösterilir; etkisiz kalan bloklar ve jokerler kırmızı '
      'çarpı alır.',
  HelpStr.shopHead: 'Mağaza',
  HelpStr.shopBody:
      'Her blind sonrası parayı alır, en fazla 5 joker ve 2 kart satın '
      'alabilir, mağazayı yenileyebilir ya da joker satabilirsin. Faiz, '
      'elindeki her \$5 için \$1 öder.',
  HelpStr.losingHead: 'Kaybetmek',
  HelpStr.losingBody:
      'Hamlelerin hedefin altında biterse ya da hiçbir parça tahtaya sığmaz '
      've atman kalmazsa koşu biter.',
};
