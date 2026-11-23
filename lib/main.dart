import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// UYGULAMA & MARKA ADI AYARLARI
// ============================================================================
const String kMarkaIlkKelime = 'Ustam';
const String kMarkaIkinciKelime = 'App';
const String kMarkaAdi = '$kMarkaIlkKelime $kMarkaIkinciKelime';
const String kMarkaAdiBaslik = 'Ustam App';

// ============================================================================
// BEYAZ AĞIRLIKLI KIRMIZI NİŞ RENK PALETİ
// ============================================================================
const Color kAnaBeyaz = Color(0xFFFFFFFF);
const Color kZeminKirikBeyaz = Color(0xFFF9FAFB);
const Color kMarkaKirmizi = Color(0xFFD91E2A);
const Color kKoyuKirmizi = Color(0xFFA8131D);
const Color kAcikKirmiziZemin = Color(0xFFFFF1F2);
const Color kKoyuAntrasit = Color(0xFF111827);
const Color kIkincilGri = Color(0xFF6B7280);
const Color kInceCizgiGri = Color(0xFFE5E7EB);

final List<String> kMotorMarkalari = [
  'Yamaha',
  'Honda',
  'Bajaj',
  'Mondial',
  'CFMoto',
  'Vespa',
  'KTM',
  'Sym',
  'Kuba',
];

String _trKucuk(String metin) {
  return metin
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .replaceAll('Ş', 'ş')
      .replaceAll('Ğ', 'ğ')
      .replaceAll('Ü', 'ü')
      .replaceAll('Ö', 'ö')
      .replaceAll('Ç', 'ç')
      .toLowerCase();
}

Future<void> _servisPuaniniYenidenHesapla(String servisId) async {
  if (servisId.isEmpty) return;
  final snap = await FirebaseFirestore.instance
      .collection('yorumlar')
      .where('servisId', isEqualTo: servisId)
      .get();
  final docs = snap.docs.where((d) => (d.data())['gizliMi'] != true).toList();
  if (docs.isEmpty) {
    await FirebaseFirestore.instance
        .collection('servisler')
        .doc(servisId)
        .update({
      'ortalamaPuan': 5.0,
      'yorumSayisi': 0,
    });
    return;
  }
  double toplam = 0;
  for (final d in docs) {
    toplam += ((d.data())['puan'] ?? 5.0).toDouble();
  }
  await FirebaseFirestore.instance
      .collection('servisler')
      .doc(servisId)
      .update({
    'ortalamaPuan': toplam / docs.length,
    'yorumSayisi': docs.length,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAd9sHkC9EB3QyOBvKAWgTObBTnKyHC1FE',
      appId: '1:771920257967:web:4feb8ce6c6f99bbd71055a',
      messagingSenderId: '771920257967',
      projectId: 'ustam-cepte-e749a',
      authDomain: 'ustam-cepte-e749a.firebaseapp.com',
      storageBucket: 'ustam-cepte-e749a.firebasestorage.app',
    ),
  );
  runApp(const UstamApp());
}

class UstamApp extends StatelessWidget {
  const UstamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kMarkaAdiBaslik,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kZeminKirikBeyaz,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kMarkaKirmizi,
          primary: kMarkaKirmizi,
          secondary: kKoyuAntrasit,
          surface: kAnaBeyaz,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kAnaBeyaz,
          foregroundColor: kKoyuAntrasit,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: Colors.transparent,
          shape: Border(
            bottom: BorderSide(color: kInceCizgiGri, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kAnaBeyaz,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kInceCizgiGri),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kInceCizgiGri),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kMarkaKirmizi, width: 1.6),
          ),
        ),
      ),
      home: const AnaSayfaIskeleti(),
    );
  }
}

// ============================================================================
// ÖZEL USTAM APP LOGOSU (Gerçek Logo Görseli)
// ============================================================================
class _UstamAppLogo extends StatelessWidget {
  final double size;

  const _UstamAppLogo({this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kAnaBeyaz,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: kMarkaKirmizi.withValues(alpha: 0.35),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: kMarkaKirmizi.withValues(alpha: 0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/ustamceptelogo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.build_circle,
              color: kMarkaKirmizi,
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// VERİ MODELLERİ
// ============================================================================
class _ServisModeli {
  final String id;
  final String dukkanAdi;
  final String ustaAdi;
  final List<String> ustalar;
  final String telefon;
  final List<String> baktigiMarkalar;
  final List<String> verilenHizmetler;
  final String adres;
  final String il;
  final String ilce;
  final double enlem;
  final double boylam;
  final String calismaSaatleri;
  final bool dukkanAcikMi;
  final bool yoneticiOnayliMi;
  final String onayDurumu;
  final String redNedeni;
  final bool banliMi;
  final double ortalamaPuan;
  final int yorumSayisi;
  final int begeniSayisi;
  final bool sistemIndirimAktifMi;
  final int sistemIndirimTutari;

  const _ServisModeli({
    required this.id,
    required this.dukkanAdi,
    required this.ustaAdi,
    required this.ustalar,
    required this.telefon,
    required this.baktigiMarkalar,
    required this.verilenHizmetler,
    required this.adres,
    required this.il,
    required this.ilce,
    required this.enlem,
    required this.boylam,
    required this.calismaSaatleri,
    required this.dukkanAcikMi,
    required this.yoneticiOnayliMi,
    required this.onayDurumu,
    required this.redNedeni,
    required this.banliMi,
    required this.ortalamaPuan,
    required this.yorumSayisi,
    required this.begeniSayisi,
    required this.sistemIndirimAktifMi,
    required this.sistemIndirimTutari,
  });

  factory _ServisModeli.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    final durum = d['onayDurumu'] != null
        ? d['onayDurumu'].toString()
        : (d['yoneticiOnayliMi'] == false ? 'onay_bekliyor' : 'onaylandi');

    return _ServisModeli(
      id: doc.id,
      dukkanAdi: (d['dukkanAdi'] ?? 'Moto Servis').toString(),
      ustaAdi: (d['ustaAdi'] ?? 'Usta').toString(),
      ustalar: List<String>.from(d['ustalar'] ?? []),
      telefon: (d['telefon'] ?? '').toString(),
      baktigiMarkalar: List<String>.from(d['baktigiMarkalar'] ?? []),
      verilenHizmetler: List<String>.from(d['verilenHizmetler'] ?? []),
      adres: (d['adres'] ?? '').toString(),
      il: (d['il'] ?? '').toString(),
      ilce: (d['ilce'] ?? '').toString(),
      enlem: (d['enlem'] ?? 41.0082).toDouble(),
      boylam: (d['boylam'] ?? 28.9784).toDouble(),
      calismaSaatleri:
      (d['calismaSaatleri'] ?? 'Hafta içi 09:00 - 19:00').toString(),
      dukkanAcikMi: d['dukkanAcikMi'] ?? true,
      yoneticiOnayliMi: d['yoneticiOnayliMi'] != false,
      onayDurumu: durum,
      redNedeni: (d['redNedeni'] ?? '').toString(),
      banliMi: d['banliMi'] == true,
      ortalamaPuan: (d['ortalamaPuan'] ?? 5.0).toDouble(),
      yorumSayisi: (d['yorumSayisi'] ?? 0).toInt(),
      begeniSayisi: (d['begeniSayisi'] ?? 0).toInt(),
      sistemIndirimAktifMi: d['sistemIndirimAktifMi'] == true,
      sistemIndirimTutari: (d['sistemIndirimTutari'] ?? 200).toInt(),
    );
  }
}

class _MotorcuKisi {
  final String uid;
  final String adSoyad;
  final String email;
  final String telefon;
  final String motorMarka;
  final String motorModel;
  final bool yoneticiMi;
  final bool banliMi;

  const _MotorcuKisi({
    required this.uid,
    required this.adSoyad,
    required this.email,
    required this.telefon,
    required this.motorMarka,
    required this.motorModel,
    required this.yoneticiMi,
    required this.banliMi,
  });

  String get motorBilgisi => '$motorMarka $motorModel'.trim();

  factory _MotorcuKisi.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return _MotorcuKisi(
      uid: doc.id,
      adSoyad: (d['adSoyad'] ?? 'Motorcu').toString(),
      email: (d['email'] ?? '').toString(),
      telefon: (d['telefon'] ?? '').toString(),
      motorMarka: (d['motorMarka'] ?? '').toString().trim(),
      motorModel: (d['motorModel'] ?? '').toString().trim(),
      yoneticiMi: d['yoneticiMi'] == true || d['rol'] == 'yonetici',
      banliMi: d['banliMi'] == true,
    );
  }
}

class _GrupIstekOgesi {
  final String grupId;
  final String grupAdi;
  final _MotorcuKisi aday;

  const _GrupIstekOgesi({
    required this.grupId,
    required this.grupAdi,
    required this.aday,
  });
}

// ============================================================================
// ANA İSKELET (ALT BAR: ARKADAŞLAR • SERVİS BUL • PROFİL)
// ============================================================================
class AnaSayfaIskeleti extends StatefulWidget {
  const AnaSayfaIskeleti({super.key});

  @override
  State<AnaSayfaIskeleti> createState() => _AnaSayfaIskeletiState();
}

class _AnaSayfaIskeletiState extends State<AnaSayfaIskeleti> {
  int _seciliSekme = 1; // Varsayılan açılış: Servis Bul
  final GlobalKey<_ServisBulSayfasiState> _servisBulKey =
  GlobalKey<_ServisBulSayfasiState>();

  void _sekmeyeGit(int index) {
    setState(() => _seciliSekme = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const _UstamAppLogo(size: 38),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
                children: [
                  TextSpan(
                    text: '$kMarkaIlkKelime ',
                    style: TextStyle(color: kKoyuAntrasit),
                  ),
                  TextSpan(
                    text: kMarkaIkinciKelime,
                    style: TextStyle(color: kMarkaKirmizi),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_seciliSekme == 1)
            IconButton(
              tooltip: 'Konumuma Odaklan',
              icon: const Icon(Icons.my_location, color: kMarkaKirmizi),
              onPressed: () {
                _servisBulKey.currentState?.konumuYenileVeOdaklan();
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _seciliSekme,
        children: [
          const ArkadaslarSayfasi(),
          ServisBulSayfasi(
            key: _servisBulKey,
            onProfilSekmesineGit: () => _sekmeyeGit(2),
          ),
          const ProfilVeYonetimSayfasi(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: kAnaBeyaz,
          border: Border(top: BorderSide(color: kInceCizgiGri, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // SOL: ARKADAŞLAR
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _sekmeyeGit(0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _seciliSekme == 0
                                ? Icons.people
                                : Icons.people_outline,
                            color: _seciliSekme == 0
                                ? kMarkaKirmizi
                                : kIkincilGri,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Arkadaşlar',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _seciliSekme == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _seciliSekme == 0
                                  ? kMarkaKirmizi
                                  : kIkincilGri,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ORTA: SERVİS BUL
                Expanded(
                  flex: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => _sekmeyeGit(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 11, horizontal: 14),
                      decoration: BoxDecoration(
                        color: kMarkaKirmizi,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: kMarkaKirmizi.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.build_circle,
                              color: kAnaBeyaz, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Servis Bul',
                            style: TextStyle(
                              color: kAnaBeyaz,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // SAĞ: PROFİL
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _sekmeyeGit(2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _seciliSekme == 2
                                ? Icons.person
                                : Icons.person_outline,
                            color: _seciliSekme == 2
                                ? kMarkaKirmizi
                                : kIkincilGri,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Profil',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: _seciliSekme == 2
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: _seciliSekme == 2
                                  ? kMarkaKirmizi
                                  : kIkincilGri,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADMOB BANNER REKLAM WIDGET'I
// ============================================================================
class AdMobBannerWidget extends StatefulWidget {
  const AdMobBannerWidget({super.key});

  @override
  State<AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // Google AdMob Test Reklam Birimi Kimlikleri (Ad Unit IDs)
  // Android Test ID: ca-app-pub-3940256099942544/6300978111
  // iOS Test ID:     ca-app-pub-3940256099942544/2934735716
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-4819592999178858/7245638929'
      : 'ca-app-pub-3940256099942544/2934735716';

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('AdMob Banner yüklenirken hata oluştu: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      height: 50,
      decoration: BoxDecoration(
        color: kAnaBeyaz,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kInceCizgiGri),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.ads_click, color: kIkincilGri, size: 20),
          SizedBox(width: 8),
          Text(
            'Sponsorlu Reklam Alanı',
            style: TextStyle(
              color: kIkincilGri,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEKME 1 (ORTA): SERVİS BUL (REKLAM BANNER, HARİTA / LİSTE, TALEP GÖNDER)
// ============================================================================
class ServisBulSayfasi extends StatefulWidget {
  final VoidCallback onProfilSekmesineGit;

  const ServisBulSayfasi({super.key, required this.onProfilSekmesineGit});

  @override
  State<ServisBulSayfasi> createState() => _ServisBulSayfasiState();
}

class _ServisBulSayfasiState extends State<ServisBulSayfasi> {
  final MapController _mapController = MapController();
  LatLng _kullaniciKonumu = const LatLng(41.0082, 28.9784);
  bool _konumAlindi = false;
  String? _konumUyariMesaji;

  double _seciliMesafeKm = 5.0;
  bool _haritaGorunumu = true;
  String? _seciliMarka;

  @override
  void initState() {
    super.initState();
    konumuYenileVeOdaklan();
  }

  Future<void> konumuYenileVeOdaklan() async {
    try {
      final servisAcik = await Geolocator.isLocationServiceEnabled();
      if (!servisAcik) {
        if (!mounted) return;
        setState(() {
          _konumUyariMesaji =
          'Cihazınızın konum (GPS) servisi kapalı. Yakındaki ustaları görmek için konumu açın.';
        });
        return;
      }

      LocationPermission izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.denied) {
        izin = await Geolocator.requestPermission();
      }
      if (izin == LocationPermission.denied ||
          izin == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _konumUyariMesaji =
          'Konum izni verilmedi. Varsayılan harita merkezi gösteriliyor.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      final yeni = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _kullaniciKonumu = yeni;
        _konumAlindi = true;
        _konumUyariMesaji = null;
      });
      try {
        _mapController.move(yeni, 14.2);
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _konumUyariMesaji =
        'Konum güncellenemedi. Sağ üstteki konum simgesine basarak tekrar deneyebilirsiniz.';
      });
    }
  }

  double _mesafeKmHesapla(_ServisModeli s) {
    final metre = Geolocator.distanceBetween(
      _kullaniciKonumu.latitude,
      _kullaniciKonumu.longitude,
      s.enlem,
      s.boylam,
    );
    return metre / 1000.0;
  }

  Future<void> _talepGonderFirestore({
    required _ServisModeli servis,
    required String talepTuru,
    required String aciklama,
    required String randevuTarihi,
    String misafirAdi = '',
    String misafirTel = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    Map<String, dynamic> motorcuVeri = {};
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(user.uid)
          .get();
      motorcuVeri = doc.data() ?? {};
    }

    final ad = user != null
        ? (motorcuVeri['adSoyad'] ?? 'Motorcu').toString()
        : (misafirAdi.isNotEmpty ? misafirAdi : 'Misafir Motorcu');
    final tel = user != null
        ? (motorcuVeri['telefon'] ?? '').toString()
        : misafirTel;

    await FirebaseFirestore.instance.collection('talepler').add({
      'servisId': servis.id,
      'servisAdi': servis.dukkanAdi,
      'motorcuUid': user?.uid ?? 'misafir',
      'motorcuAdi': ad,
      'motorcuTelefon': tel,
      'motorMarka': (motorcuVeri['motorMarka'] ?? '').toString(),
      'motorModel': (motorcuVeri['motorModel'] ?? '').toString(),
      'talepTuru': talepTuru,
      'randevuTarihi': randevuTarihi,
      'aciklama': aciklama.isEmpty ? 'Genel kontrol ve bakım' : aciklama,
      'konumEnlem': _kullaniciKonumu.latitude,
      'konumBoylam': _kullaniciKonumu.longitude,
      'indirimKullanildiMi': servis.sistemIndirimAktifMi,
      'sistemIndirimTutari': servis.sistemIndirimTutari,
      'durum': 'bekliyor',
      'tarih': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text(
          '${servis.dukkanAdi} servisine "$talepTuru" talebiniz iletildi!',
        ),
      ),
    );
  }

  void _servisDetayAc(_ServisModeli servis) {
    final km = _mesafeKmHesapla(servis);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kAnaBeyaz,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: kInceCizgiGri,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          servis.dukkanAdi,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: kKoyuAntrasit,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: servis.dukkanAcikMi
                              ? Colors.green.shade50
                              : kAcikKirmiziZemin,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: servis.dukkanAcikMi
                                ? Colors.green
                                : kMarkaKirmizi,
                          ),
                        ),
                        child: Text(
                          servis.dukkanAcikMi ? '● Açık' : '● Kapalı',
                          style: TextStyle(
                            color: servis.dukkanAcikMi
                                ? Colors.green.shade800
                                : kMarkaKirmizi,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Usta: ${servis.ustalar.isNotEmpty ? servis.ustalar.join(", ") : servis.ustaAdi} • ⭐ ${servis.ortalamaPuan.toStringAsFixed(1)} (${servis.yorumSayisi}) • ${km.toStringAsFixed(1)} km',
                    style: const TextStyle(color: kIkincilGri, fontSize: 13.5),
                  ),
                  if (servis.sistemIndirimAktifMi) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kAcikKirmiziZemin,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: kMarkaKirmizi.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer,
                              color: kMarkaKirmizi, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sistem Destekli ${servis.sistemIndirimTutari} TL İndirim Geçerli!',
                              style: const TextStyle(
                                color: kKoyuAntrasit,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 17, color: kMarkaKirmizi),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          servis.calismaSaatleri,
                          style: const TextStyle(
                              fontSize: 13, color: kKoyuAntrasit),
                        ),
                      ),
                    ],
                  ),
                  if (servis.adres.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 17, color: kMarkaKirmizi),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            servis.adres,
                            style: const TextStyle(
                                fontSize: 13, color: kIkincilGri),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (servis.baktigiMarkalar.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Uzman Olduğu Markalar',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: kKoyuAntrasit),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: servis.baktigiMarkalar.map((m) {
                        return Chip(
                          label: Text(m, style: const TextStyle(fontSize: 12)),
                          backgroundColor: kZeminKirikBeyaz,
                          side: const BorderSide(color: kInceCizgiGri),
                        );
                      }).toList(),
                    ),
                  ],
                  if (servis.verilenHizmetler.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Verilen Hizmetler',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: kKoyuAntrasit),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: servis.verilenHizmetler.map((h) {
                        return Chip(
                          label: Text(
                            h,
                            style: const TextStyle(
                              fontSize: 12,
                              color: kMarkaKirmizi,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: kAcikKirmiziZemin,
                          side: BorderSide(
                              color: kMarkaKirmizi.withValues(alpha: 0.25)),
                        );
                      }).toList(),
                    ),
                  ],
                  const Divider(height: 26, color: kInceCizgiGri),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kMarkaKirmizi,
                            foregroundColor: kAnaBeyaz,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _tamirRandevuFormuAc(servis);
                          },
                          icon: const Icon(Icons.build_circle, size: 19),
                          label: const Text(
                            'Tamir / Randevu',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kKoyuAntrasit,
                            foregroundColor: kAnaBeyaz,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await _talepGonderFirestore(
                              servis: servis,
                              talepTuru: 'Konuma Git (Yol Yardım)',
                              aciklama:
                              'Bulunduğum konuma yol yardım / usta desteği istiyorum.',
                              randevuTarihi: '',
                            );
                          },
                          icon: const Icon(Icons.sos, size: 19),
                          label: const Text(
                            'Konuma Çağır',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kKoyuAntrasit,
                            side: const BorderSide(color: kInceCizgiGri),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse(
                              'https://www.google.com/maps/dir/?api=1&destination=${servis.enlem},${servis.boylam}&travelmode=driving',
                            );
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.directions,
                              size: 18, color: kMarkaKirmizi),
                          label: const Text('Yol Tarifi'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (servis.telefon.isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kKoyuAntrasit,
                              side: const BorderSide(color: kInceCizgiGri),
                            ),
                            onPressed: () async {
                              final tel = servis.telefon
                                  .replaceAll(RegExp(r'[^0-9]'), '');
                              final msg = Uri.encodeComponent(
                                'Merhaba ${servis.dukkanAdi}, $kMarkaAdi üzerinden ulaşıyorum.',
                              );
                              await launchUrl(
                                Uri.parse('https://wa.me/$tel?text=$msg'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            icon: const Icon(Icons.chat,
                                size: 18, color: Colors.green),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('servisler')
                                .doc(servis.id)
                                .update({
                              'begeniSayisi': FieldValue.increment(1),
                            });
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Servis beğenildi! ❤️')),
                            );
                          },
                          icon: const Icon(Icons.favorite,
                              color: kMarkaKirmizi),
                          label: Text(
                            'Beğen (${servis.begeniSayisi})',
                            style: const TextStyle(color: kKoyuAntrasit),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _yorumPenceresiAc(servis);
                          },
                          icon: const Icon(Icons.star, color: kMarkaKirmizi),
                          label: const Text(
                            'Puan Ver / Yorum Yap',
                            style: TextStyle(color: kKoyuAntrasit),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _tamirRandevuFormuAc(_ServisModeli servis) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tamir veya randevu talebi oluşturmak için önce giriş yapın.'),
        ),
      );
      widget.onProfilSekmesineGit();
      return;
    }

    String talepTuru = 'Tamir Talebi';
    final randevuController = TextEditingController();
    final aciklamaController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: Text('${servis.dukkanAdi} - Talep Oluştur'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<String>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: kMarkaKirmizi,
                      selectedForegroundColor: kAnaBeyaz,
                    ),
                    segments: const [
                      ButtonSegment(
                          value: 'Tamir Talebi', label: Text('Tamir')),
                      ButtonSegment(
                          value: 'Randevu Talebi', label: Text('Randevu')),
                    ],
                    selected: {talepTuru},
                    onSelectionChanged: (s) =>
                        setDialogState(() => talepTuru = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (talepTuru == 'Randevu Talebi') ...[
                    TextField(
                      controller: randevuController,
                      decoration: const InputDecoration(
                        labelText: 'İstenen Gün ve Saat',
                        hintText: 'Örn: Yarın 14:30',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: aciklamaController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Arıza veya Bakım Açıklaması',
                      hintText: 'Örn: Periyodik yağ bakımı ve ön fren balatası',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: () async {
                  await _talepGonderFirestore(
                    servis: servis,
                    talepTuru: talepTuru,
                    aciklama: aciklamaController.text.trim(),
                    randevuTarihi: randevuController.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Talebi Gönder'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _yorumPenceresiAc(_ServisModeli servis) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorum yapmak için önce giriş yapın.')),
      );
      widget.onProfilSekmesineGit();
      return;
    }

    int secilenPuan = 5;
    final yorumController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: Text('${servis.dukkanAdi} Değerlendir'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final yildiz = i + 1;
                    return IconButton(
                      onPressed: () =>
                          setDialogState(() => secilenPuan = yildiz),
                      icon: Icon(
                        yildiz <= secilenPuan ? Icons.star : Icons.star_border,
                        color: kMarkaKirmizi,
                        size: 32,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: yorumController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deneyiminizi yazın',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: () async {
                  final uDoc = await FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(user.uid)
                      .get();
                  final ad =
                  (uDoc.data()?['adSoyad'] ?? 'Motorcu').toString();

                  await FirebaseFirestore.instance.collection('yorumlar').add({
                    'servisId': servis.id,
                    'servisAdi': servis.dukkanAdi,
                    'kullaniciUid': user.uid,
                    'kullaniciAdi': ad,
                    'puan': secilenPuan,
                    'yorumMetni': yorumController.text.trim(),
                    'gizliMi': false,
                    'tarih': FieldValue.serverTimestamp(),
                  });

                  final yeniSayi = servis.yorumSayisi + 1;
                  final yeniOrtalama =
                      ((servis.ortalamaPuan * servis.yorumSayisi) +
                          secilenPuan) /
                          yeniSayi;

                  await FirebaseFirestore.instance
                      .collection('servisler')
                      .doc(servis.id)
                      .update({
                    'yorumSayisi': yeniSayi,
                    'ortalamaPuan': yeniOrtalama,
                  });

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Gönder'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;

        return StreamBuilder<DocumentSnapshot?>(
          stream: user != null
              ? FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(user.uid)
              .snapshots()
              : Stream<DocumentSnapshot?>.value(null),
          builder: (context, uSnap) {
            final uData =
                (uSnap.data?.data() as Map<String, dynamic>?) ?? {};
            final ad = (uData['adSoyad'] ?? 'Motorcu').toString();
            final kayitliMotorMarka =
            (uData['motorMarka'] ?? '').toString().trim();
            final kayitliMotorModel =
            (uData['motorModel'] ?? '').toString().trim();
            final motorTamBilgi =
            '$kayitliMotorMarka $kayitliMotorModel'.trim();

            // Kullanıcı online durumunu güncelle
            if (user != null) {
              FirebaseFirestore.instance
                  .collection('kullanicilar')
                  .doc(user.uid)
                  .set({'sonGirisTarihi': FieldValue.serverTimestamp()}, SetOptions(merge: true));
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('servisler')
                  .snapshots(),
              builder: (context, snapshot) {
                final tumServisler = snapshot.hasData
                    ? snapshot.data!.docs
                    .map((d) => _ServisModeli.fromDoc(d))
                    .toList()
                    : <_ServisModeli>[];

                final onayliServisler = tumServisler.where((s) {
                  return s.yoneticiOnayliMi &&
                      s.onayDurumu == 'onaylandi' &&
                      !s.banliMi;
                }).toList();

                final String aktifFiltreMarkasi = _seciliMarka ??
                    (kayitliMotorMarka.isNotEmpty ? kayitliMotorMarka : 'Tümü');

                final filtrelenmisServisler = onayliServisler.where((s) {
                  final km = _mesafeKmHesapla(s);
                  if (km > _seciliMesafeKm) return false;
                  if (aktifFiltreMarkasi != 'Tümü') {
                    return s.baktigiMarkalar.any(
                            (m) => _trKucuk(m) == _trKucuk(aktifFiltreMarkasi));
                  }
                  return true;
                }).toList();

                filtrelenmisServisler.sort((a, b) =>
                    _mesafeKmHesapla(a).compareTo(_mesafeKmHesapla(b)));

                return Column(
                  children: [
                    // 1. ADMOB BANNER REKLAM ALANI
                    const AdMobBannerWidget(),

                    // 2. KULLANICI DURUM ŞERİDİ
                    if (user == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş geldin, Misafir 👋',
                                    style: TextStyle(
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w900,
                                      color: kKoyuAntrasit,
                                    ),
                                  ),
                                  Text(
                                    'İşlem yapmak için Profil\'den giriş yap',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: kIkincilGri,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kMarkaKirmizi,
                                foregroundColor: kAnaBeyaz,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: widget.onProfilSekmesineGit,
                              child: const Text(
                                'Giriş Yap',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş geldin, $ad 👋',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: kKoyuAntrasit,
                                    ),
                                  ),
                                  Text(
                                    motorTamBilgi.isNotEmpty
                                        ? '🏍️ $motorTamBilgi'
                                        : 'Motosikletini Profil sekmesinden ekleyebilirsin',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: kIkincilGri,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 3. MESAFE SLIDER & HARİTA / LİSTE GEÇİŞİ
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mesafe: 0 - ${_seciliMesafeKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: kKoyuAntrasit,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: kAnaBeyaz,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: kInceCizgiGri),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _gorunumButonu(
                                  secili: _haritaGorunumu,
                                  ikon: Icons.check,
                                  etiket: 'Harita',
                                  onTap: () =>
                                      setState(() => _haritaGorunumu = true),
                                ),
                                _gorunumButonu(
                                  secili: !_haritaGorunumu,
                                  ikon: Icons.list,
                                  etiket: 'Liste',
                                  onTap: () =>
                                      setState(() => _haritaGorunumu = false),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Slider(
                      value: _seciliMesafeKm,
                      min: 1.0,
                      max: 50.0,
                      activeColor: kMarkaKirmizi,
                      inactiveColor: kMarkaKirmizi.withValues(alpha: 0.2),
                      onChanged: (val) =>
                          setState(() => _seciliMesafeKm = val),
                    ),

                    // MARKA FİLTRE ŞERİDİ (Başlangıçta hiçbiri seçili değil)
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        children: ['Tümü', ...kMotorMarkalari].map((marka) {
                          final secili = _seciliMarka == marka;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(marka,
                                  style: const TextStyle(fontSize: 12)),
                              selected: secili,
                              backgroundColor: kAnaBeyaz,
                              selectedColor: kMarkaKirmizi,
                              side: BorderSide(
                                color: secili ? kMarkaKirmizi : kInceCizgiGri,
                              ),
                              labelStyle: TextStyle(
                                color: secili ? kAnaBeyaz : kKoyuAntrasit,
                                fontWeight: FontWeight.bold,
                              ),
                              onSelected: (secildi) => setState(
                                    () => _seciliMarka = secildi ? marka : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    if (_seciliMarka == null && kayitliMotorMarka.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                        child: Row(
                          children: [
                            const Icon(Icons.filter_alt_outlined,
                                size: 15, color: kMarkaKirmizi),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Kayıtlı motoruna ($kayitliMotorMarka) uygun servisler listeleniyor',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: kIkincilGri,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),

                    if (_konumUyariMesaji != null)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: kAcikKirmiziZemin,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: kMarkaKirmizi.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_off,
                                color: kMarkaKirmizi, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _konumUyariMesaji!,
                                style: const TextStyle(
                                    fontSize: 12, color: kKoyuAntrasit),
                              ),
                            ),
                            TextButton(
                              onPressed: konumuYenileVeOdaklan,
                              child: const Text(
                                'Tekrar Dene',
                                style: TextStyle(color: kMarkaKirmizi),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 4. HARİTA VEYA LİSTE ALANI
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: _haritaGorunumu
                            ? _haritaGorunumuWidget(
                                filtrelenmisServisler, aktifFiltreMarkasi)
                            : _listeGorunumuWidget(
                                filtrelenmisServisler, aktifFiltreMarkasi),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _gorunumButonu({
    required bool secili,
    required IconData ikon,
    required String etiket,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: secili ? kMarkaKirmizi : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              ikon,
              size: 16,
              color: secili ? kAnaBeyaz : kKoyuAntrasit,
            ),
            const SizedBox(width: 4),
            Text(
              etiket,
              style: TextStyle(
                color: secili ? kAnaBeyaz : kKoyuAntrasit,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _haritaGorunumuWidget(
      List<_ServisModeli> servisler, String aktifFiltreMarkasi) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kInceCizgiGri, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kullaniciKonumu,
              initialZoom: _konumAlindi ? 14.0 : 12.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sephartmedia.ustamapp',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _kullaniciKonumu,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kKoyuAntrasit,
                        shape: BoxShape.circle,
                        border: Border.all(color: kAnaBeyaz, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(
                        Icons.two_wheeler,
                        color: kAnaBeyaz,
                        size: 24,
                      ),
                    ),
                  ),
                  ...servisler.map((s) {
                    return Marker(
                      point: LatLng(s.enlem, s.boylam),
                      width: 110,
                      height: 62,
                      child: GestureDetector(
                        onTap: () => _servisDetayAc(s),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kKoyuAntrasit,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                s.dukkanAdi,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kAnaBeyaz,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: kMarkaKirmizi,
                              size: 36,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          if (servisler.isEmpty)
            Positioned(
              top: 12,
              left: 14,
              right: 14,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kAnaBeyaz.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kInceCizgiGri),
                ),
                child: Text(
                  aktifFiltreMarkasi != 'Tümü'
                      ? 'Seçilen alanda $aktifFiltreMarkasi markasına bakan servis bulunmuyor.'
                      : 'Seçilen alanda kayıtlı servis bulunmuyor.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kKoyuAntrasit,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _listeGorunumuWidget(
      List<_ServisModeli> servisler, String aktifFiltreMarkasi) {
    if (servisler.isEmpty) {
      return Center(
        child: Text(
          aktifFiltreMarkasi != 'Tümü'
              ? 'Seçilen mesafede $aktifFiltreMarkasi markasına bakan onaylı servis bulunmuyor.'
              : 'Seçilen mesafe filtresinde onaylı servis bulunmuyor.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: kIkincilGri, fontSize: 14.5),
        ),
      );
    }

    return ListView.builder(
      itemCount: servisler.length,
      itemBuilder: (context, index) {
        final s = servisler[index];
        final km = _mesafeKmHesapla(s);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: kAnaBeyaz,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kInceCizgiGri),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: const CircleAvatar(
              radius: 25,
              backgroundColor: kAcikKirmiziZemin,
              child: Icon(Icons.build_circle, color: kMarkaKirmizi),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    s.dukkanAdi,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kKoyuAntrasit,
                    ),
                  ),
                ),
                Text(
                  '${km.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kMarkaKirmizi,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Usta: ${s.ustaAdi} • ⭐ ${s.ortalamaPuan.toStringAsFixed(1)} (${s.yorumSayisi})',
                  style: const TextStyle(fontSize: 12.5, color: kIkincilGri),
                ),
                if (s.sistemIndirimAktifMi)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '🎁 Sistem Destekli ${s.sistemIndirimTutari} TL İndirim',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: kMarkaKirmizi,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => _servisDetayAc(s),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SEKME 0 (SOL): ARKADAŞLAR
// ============================================================================
class ArkadaslarSayfasi extends StatefulWidget {
  const ArkadaslarSayfasi({super.key});

  @override
  State<ArkadaslarSayfasi> createState() => _ArkadaslarSayfasiState();
}

class _ArkadaslarSayfasiState extends State<ArkadaslarSayfasi> {
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = '';

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _yoneticiDirektArkadasEkle(
      String benimUid, String hedefUid, String hedefAdi) async {
    final db = FirebaseFirestore.instance;
    await db.collection('kullanicilar').doc(benimUid).set({
      'arkadaslar': FieldValue.arrayUnion([hedefUid]),
      'gelenIstekler': FieldValue.arrayRemove([hedefUid]),
      'gonderilenIstekler': FieldValue.arrayRemove([hedefUid]),
    }, SetOptions(merge: true));

    await db.collection('kullanicilar').doc(hedefUid).set({
      'arkadaslar': FieldValue.arrayUnion([benimUid]),
      'gelenIstekler': FieldValue.arrayRemove([benimUid]),
      'gonderilenIstekler': FieldValue.arrayRemove([benimUid]),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text(
            '$hedefAdi istek gönderilmeksizin doğrudan arkadaş eklendi.'),
      ),
    );
  }

  Future<void> _istekGonder(
      String benimUid, String hedefUid, String hedefAdi) async {
    final db = FirebaseFirestore.instance;
    await db.collection('kullanicilar').doc(benimUid).set({
      'gonderilenIstekler': FieldValue.arrayUnion([hedefUid]),
    }, SetOptions(merge: true));

    await db.collection('kullanicilar').doc(hedefUid).set({
      'gelenIstekler': FieldValue.arrayUnion([benimUid]),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
          Text('$hedefAdi adlı motorcuya arkadaşlık isteği gönderildi.')),
    );
  }

  Future<void> _istekOnayla(
      String benimUid, String gonderenUid, String gonderenAdi) async {
    final db = FirebaseFirestore.instance;
    await db.collection('kullanicilar').doc(benimUid).set({
      'gelenIstekler': FieldValue.arrayRemove([gonderenUid]),
      'arkadaslar': FieldValue.arrayUnion([gonderenUid]),
    }, SetOptions(merge: true));

    await db.collection('kullanicilar').doc(gonderenUid).set({
      'gonderilenIstekler': FieldValue.arrayRemove([benimUid]),
      'arkadaslar': FieldValue.arrayUnion([benimUid]),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('$gonderenAdi artık Arkadaşlar bölümünde!'),
      ),
    );
  }

  Future<void> _istekReddetVeyaCikar(String benimUid, String digerUid) async {
    final db = FirebaseFirestore.instance;
    await db.collection('kullanicilar').doc(benimUid).set({
      'arkadaslar': FieldValue.arrayRemove([digerUid]),
      'gelenIstekler': FieldValue.arrayRemove([digerUid]),
      'gonderilenIstekler': FieldValue.arrayRemove([digerUid]),
    }, SetOptions(merge: true));

    await db.collection('kullanicilar').doc(digerUid).set({
      'arkadaslar': FieldValue.arrayRemove([benimUid]),
      'gelenIstekler': FieldValue.arrayRemove([benimUid]),
      'gonderilenIstekler': FieldValue.arrayRemove([benimUid]),
    }, SetOptions(merge: true));
  }

  Future<void> _grubaKatilmaIstegiGonder(
      String benimUid, String grupId, String grupAdi) async {
    await FirebaseFirestore.instance
        .collection('arkadas_gruplari')
        .doc(grupId)
        .update({
      'katilmaIstekleri': FieldValue.arrayUnion([benimUid]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('"$grupAdi" grubuna katılma isteği gönderildi.'),
      ),
    );
  }

  Future<void> _grupKatilmaIsteginiGeriCek(
      String benimUid, String grupId) async {
    await FirebaseFirestore.instance
        .collection('arkadas_gruplari')
        .doc(grupId)
        .update({
      'katilmaIstekleri': FieldValue.arrayRemove([benimUid]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grup katılma isteği geri çekildi.')),
    );
  }

  Future<void> _grupKatilmaIstegiOnayla(
      String grupId, String adayUid, String adayAdi, String grupAdi) async {
    await FirebaseFirestore.instance
        .collection('arkadas_gruplari')
        .doc(grupId)
        .update({
      'katilmaIstekleri': FieldValue.arrayRemove([adayUid]),
      'uyeler': FieldValue.arrayUnion([adayUid]),
      'banliUyeler': FieldValue.arrayRemove([adayUid]),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('$adayAdi "$grupAdi" grubuna kabul edildi!'),
      ),
    );
  }

  Future<void> _grupKatilmaIstegiReddet(String grupId, String adayUid) async {
    await FirebaseFirestore.instance
        .collection('arkadas_gruplari')
        .doc(grupId)
        .update({
      'katilmaIstekleri': FieldValue.arrayRemove([adayUid]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final benimUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: kAnaBeyaz,
            border: Border(bottom: BorderSide(color: kInceCizgiGri)),
          ),
          child: TextField(
            controller: _aramaController,
            onChanged: (val) => setState(() => _aramaMetni = val.trim()),
            style: const TextStyle(
                color: kKoyuAntrasit, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Arkadaş, motor veya grup adı ara...',
              hintStyle: const TextStyle(color: kIkincilGri, fontSize: 14),
              filled: true,
              fillColor: kZeminKirikBeyaz,
              prefixIcon: const Icon(Icons.search, color: kMarkaKirmizi),
              suffixIcon: _aramaMetni.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: kIkincilGri),
                onPressed: () {
                  _aramaController.clear();
                  setState(() => _aramaMetni = '');
                },
              )
                  : null,
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('kullanicilar')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: kMarkaKirmizi));
              }

              final tumKisiler = snapshot.data!.docs
                  .map((d) => _MotorcuKisi.fromDoc(d))
                  .toList();

              Map<String, dynamic> benimVerim = {};
              if (benimUid != null) {
                for (final doc in snapshot.data!.docs) {
                  if (doc.id == benimUid) {
                    benimVerim = (doc.data() as Map<String, dynamic>?) ?? {};
                    break;
                  }
                }
              }

              final bool benimYoneticiMi = benimVerim['yoneticiMi'] == true ||
                  benimVerim['rol'] == 'yonetici';

              final arkadasUidleri =
              List<String>.from(benimVerim['arkadaslar'] ?? []);
              final gelenIstekUidleri =
              List<String>.from(benimVerim['gelenIstekler'] ?? []);
              final gonderilenIstekUidleri =
              List<String>.from(benimVerim['gonderilenIstekler'] ?? []);

              final gorunurMotorcular = tumKisiler.where((k) {
                if (k.uid == benimUid) return false;
                if (!benimYoneticiMi && k.yoneticiMi) return false;
                if (k.banliMi) return false;
                return true;
              }).toList();

              final gelenIstekKisileri = gorunurMotorcular
                  .where((k) => gelenIstekUidleri.contains(k.uid))
                  .toList();

              final onayliArkadaslar = gorunurMotorcular
                  .where((k) => arkadasUidleri.contains(k.uid))
                  .toList();

              final digerKisilerYoneticiIcin = gorunurMotorcular
                  .where((k) => !arkadasUidleri.contains(k.uid))
                  .toList();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('arkadas_gruplari')
                    .snapshots(),
                builder: (context, grupSnap) {
                  final tumGrupDocs = grupSnap.hasData
                      ? grupSnap.data!.docs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final banlilar =
                    List<String>.from(d['banliUyeler'] ?? []);
                    final aktif = d['aktifMi'] != false;
                    if (!aktif) return false;
                    if (benimUid != null && banlilar.contains(benimUid)) {
                      return false;
                    }
                    return true;
                  }).toList()
                      : <QueryDocumentSnapshot>[];

                  final ekliOlunanGruplar = benimUid == null
                      ? <QueryDocumentSnapshot>[]
                      : tumGrupDocs.where((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final uyeler = List<String>.from(d['uyeler'] ?? []);
                    return uyeler.contains(benimUid);
                  }).toList();

                  final List<_GrupIstekOgesi> gelenGrupIstekleri = [];
                  if (benimUid != null) {
                    for (final gDoc in ekliOlunanGruplar) {
                      final gd = gDoc.data() as Map<String, dynamic>;
                      if (gd['kurucuUid'] == benimUid) {
                        final istekler =
                        List<String>.from(gd['katilmaIstekleri'] ?? []);
                        for (final adayUid in istekler) {
                          final adayKisi = tumKisiler.firstWhere(
                                (k) => k.uid == adayUid,
                            orElse: () => _MotorcuKisi(
                              uid: adayUid,
                              adSoyad: 'Motorcu',
                              email: '',
                              telefon: '',
                              motorMarka: '',
                              motorModel: '',
                              yoneticiMi: false,
                              banliMi: false,
                            ),
                          );
                          gelenGrupIstekleri.add(
                            _GrupIstekOgesi(
                              grupId: gDoc.id,
                              grupAdi: (gd['grupAdi'] ?? 'Grup').toString(),
                              aday: adayKisi,
                            ),
                          );
                        }
                      }
                    }
                  }

                  if (_aramaMetni.isNotEmpty) {
                    final aranan = _trKucuk(_aramaMetni);

                    final bulunanGruplar = tumGrupDocs.where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final gAdi = (d['grupAdi'] ?? '').toString();
                      final kAdi = (d['kurucuAdi'] ?? '').toString();
                      return _trKucuk(gAdi).contains(aranan) ||
                          _trKucuk(kAdi).contains(aranan);
                    }).toList();

                    bulunanGruplar.sort((a, b) {
                      final aUye = benimUid != null &&
                          List<String>.from(
                              (a.data() as Map<String, dynamic>)['uyeler'] ??
                                  [])
                              .contains(benimUid);
                      final bUye = benimUid != null &&
                          List<String>.from(
                              (b.data() as Map<String, dynamic>)['uyeler'] ??
                                  [])
                              .contains(benimUid);
                      if (aUye && !bUye) return -1;
                      if (!aUye && bUye) return 1;
                      return 0;
                    });

                    final bulunanMotorcular = gorunurMotorcular.where((k) {
                      return _trKucuk(k.adSoyad).contains(aranan) ||
                          _trKucuk(k.motorBilgisi).contains(aranan);
                    }).toList();

                    if (bulunanGruplar.isEmpty && bulunanMotorcular.isEmpty) {
                      return Center(
                        child: Text(
                          '"$_aramaMetni" için arkadaş veya grup bulunamadı.',
                          style: const TextStyle(color: kIkincilGri),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(14),
                      children: [
                        if (bulunanGruplar.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.groups,
                                  size: 18, color: kMarkaKirmizi),
                              const SizedBox(width: 6),
                              Text(
                                'Gruplar (${bulunanGruplar.length})',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...bulunanGruplar.map((doc) => _grupKarti(
                            doc: doc,
                            benimUid: benimUid,
                          )),
                          const SizedBox(height: 12),
                        ],
                        if (bulunanMotorcular.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.two_wheeler,
                                  size: 18, color: kMarkaKirmizi),
                              const SizedBox(width: 6),
                              Text(
                                'Motorcular (${bulunanMotorcular.length})',
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...bulunanMotorcular.map((kisi) => _motorcuKarti(
                            kisi: kisi,
                            benimUid: benimUid,
                            benimYoneticiMi: benimYoneticiMi,
                            arkadasMi: arkadasUidleri.contains(kisi.uid),
                            istekGeldiMi:
                            gelenIstekUidleri.contains(kisi.uid),
                            istekGonderildiMi:
                            gonderilenIstekUidleri.contains(kisi.uid),
                          )),
                        ],
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      if (ekliOlunanGruplar.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.groups,
                                size: 19, color: kMarkaKirmizi),
                            const SizedBox(width: 6),
                            Text(
                              'Gruplarım (${ekliOlunanGruplar.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: kKoyuAntrasit,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...ekliOlunanGruplar.map((doc) => _grupKarti(
                          doc: doc,
                          benimUid: benimUid,
                        )),
                        const SizedBox(height: 14),
                      ],
                      if (gelenGrupIstekleri.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: kAcikKirmiziZemin,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: kMarkaKirmizi.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gruba Katılma İstekleri (${gelenGrupIstekleri.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...gelenGrupIstekleri.map((item) {
                                final aday = item.aday;
                                final gId = item.grupId;
                                final gAdi = item.grupAdi;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: kAnaBeyaz,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: kAcikKirmiziZemin,
                                      child: Icon(Icons.group_add,
                                          color: kMarkaKirmizi, size: 20),
                                    ),
                                    title: Text(
                                      aday.adSoyad,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kKoyuAntrasit),
                                    ),
                                    subtitle: Text(
                                      '"$gAdi" grubuna katılmak istiyor',
                                      style: const TextStyle(
                                          fontSize: 12, color: kIkincilGri),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            Colors.green.shade700,
                                            foregroundColor: kAnaBeyaz,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                          ),
                                          onPressed: () =>
                                              _grupKatilmaIstegiOnayla(
                                                  gId,
                                                  aday.uid,
                                                  aday.adSoyad,
                                                  gAdi),
                                          child: const Text('Onayla',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: kMarkaKirmizi, size: 20),
                                          onPressed: () =>
                                              _grupKatilmaIstegiReddet(
                                                  gId, aday.uid),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      if (gelenIstekKisileri.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: kAcikKirmiziZemin,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: kMarkaKirmizi.withValues(alpha: 0.35)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gelen Arkadaşlık İstekleri (${gelenIstekKisileri.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...gelenIstekKisileri.map((kisi) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: kAnaBeyaz,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: kAcikKirmiziZemin,
                                      child: Text(
                                        kisi.adSoyad.isNotEmpty
                                            ? kisi.adSoyad[0].toUpperCase()
                                            : 'M',
                                        style: const TextStyle(
                                          color: kMarkaKirmizi,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      kisi.adSoyad,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: kKoyuAntrasit),
                                    ),
                                    subtitle: Text(
                                      kisi.motorBilgisi.isNotEmpty
                                          ? kisi.motorBilgisi
                                          : 'Motorcu',
                                      style:
                                      const TextStyle(color: kIkincilGri),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                            Colors.green.shade700,
                                            foregroundColor: kAnaBeyaz,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10),
                                          ),
                                          onPressed: () {
                                            if (benimUid != null) {
                                              _istekOnayla(benimUid, kisi.uid,
                                                  kisi.adSoyad);
                                            }
                                          },
                                          child: const Text('Onayla',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.close,
                                              color: kMarkaKirmizi, size: 20),
                                          onPressed: () {
                                            if (benimUid != null) {
                                              _istekReddetVeyaCikar(
                                                  benimUid, kisi.uid);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        'Arkadaşlar (${onayliArkadaslar.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kKoyuAntrasit,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (onayliArkadaslar.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kAnaBeyaz,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: kInceCizgiGri),
                          ),
                          child: Text(
                            benimYoneticiMi
                                ? 'Henüz arkadaş listeniz boş. Yönetici olarak aşağıdaki listeden veya aramadan herkesi istek göndermeksizin doğrudan ekleyebilirsiniz.'
                                : 'Henüz onaylanmış arkadaşınız yok. Yukarıdaki arama çubuğundan motorcuları veya grupları arayabilirsiniz.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: kIkincilGri, fontSize: 13.5),
                          ),
                        )
                      else
                        ...onayliArkadaslar.map((kisi) {
                          return _motorcuKarti(
                            kisi: kisi,
                            benimUid: benimUid,
                            benimYoneticiMi: benimYoneticiMi,
                            arkadasMi: true,
                            istekGeldiMi: false,
                            istekGonderildiMi: false,
                          );
                        }),
                      if (benimYoneticiMi &&
                          digerKisilerYoneticiIcin.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.admin_panel_settings,
                                size: 18, color: kMarkaKirmizi),
                            const SizedBox(width: 6),
                            Text(
                              'Tüm Kullanıcılar — Direkt Ekle (${digerKisilerYoneticiIcin.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: kKoyuAntrasit,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...digerKisilerYoneticiIcin.map((kisi) {
                          return _motorcuKarti(
                            kisi: kisi,
                            benimUid: benimUid,
                            benimYoneticiMi: benimYoneticiMi,
                            arkadasMi: false,
                            istekGeldiMi: gelenIstekUidleri.contains(kisi.uid),
                            istekGonderildiMi:
                            gonderilenIstekUidleri.contains(kisi.uid),
                          );
                        }),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _grupKarti({
    required QueryDocumentSnapshot doc,
    required String? benimUid,
  }) {
    final d = doc.data() as Map<String, dynamic>;
    final grupAdi = (d['grupAdi'] ?? 'Sürüş Grubu').toString();
    final kurucuAdi = (d['kurucuAdi'] ?? 'Kurucu').toString();
    final uyeler = List<String>.from(d['uyeler'] ?? []);
    final istekler = List<String>.from(d['katilmaIstekleri'] ?? []);
    final bool uyeMi = benimUid != null && uyeler.contains(benimUid);
    final bool istekGonderildiMi =
        benimUid != null && istekler.contains(benimUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kAnaBeyaz,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: uyeMi
              ? kMarkaKirmizi.withValues(alpha: 0.4)
              : kInceCizgiGri,
          width: uyeMi ? 1.3 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: uyeMi ? kMarkaKirmizi : kAcikKirmiziZemin,
          child: Text(
            grupAdi.isNotEmpty ? grupAdi[0].toUpperCase() : 'G',
            style: TextStyle(
              color: uyeMi ? kAnaBeyaz : kMarkaKirmizi,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                grupAdi,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: kKoyuAntrasit,
                ),
              ),
            ),
            if (uyeMi) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: kAcikKirmiziZemin,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Üyesin',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kMarkaKirmizi,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${uyeler.length} Üye • Kurucu: $kurucuAdi',
          style: const TextStyle(fontSize: 12.5, color: kIkincilGri),
        ),
        onTap: () {
          if (benimUid == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Gruba girmek için önce giriş yapın.')),
            );
            return;
          }
          if (uyeMi) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GrupSohbetSayfasi(
                  grupId: doc.id,
                  mevcutUid: benimUid,
                ),
              ),
            );
          } else if (!istekGonderildiMi) {
            _grubaKatilmaIstegiGonder(benimUid, doc.id, grupAdi);
          }
        },
        trailing: uyeMi
            ? const Icon(Icons.chevron_right, color: kMarkaKirmizi)
            : istekGonderildiMi
            ? TextButton(
          onPressed: () {
            _grupKatilmaIsteginiGeriCek(benimUid, doc.id);
          },
          child: const Text(
            'İstek Gönderildi',
            style: TextStyle(color: kIkincilGri, fontSize: 12),
          ),
        )
            : ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kMarkaKirmizi,
            foregroundColor: kAnaBeyaz,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          onPressed: () {
            if (benimUid == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Gruba katılma isteği göndermek için önce giriş yapın.')),
              );
              return;
            }
            _grubaKatilmaIstegiGonder(benimUid, doc.id, grupAdi);
          },
          icon: const Icon(Icons.group_add, size: 16),
          label: const Text('Katılma İsteği',
              style: TextStyle(fontSize: 11.5)),
        ),
      ),
    );
  }

  Widget _motorcuKarti({
    required _MotorcuKisi kisi,
    required String? benimUid,
    required bool benimYoneticiMi,
    required bool arkadasMi,
    required bool istekGeldiMi,
    required bool istekGonderildiMi,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kAnaBeyaz,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInceCizgiGri),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: kAcikKirmiziZemin,
          child: Text(
            kisi.adSoyad.isNotEmpty ? kisi.adSoyad[0].toUpperCase() : 'M',
            style: const TextStyle(
                color: kMarkaKirmizi, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                kisi.adSoyad,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kKoyuAntrasit),
              ),
            ),
            if (kisi.yoneticiMi) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kAcikKirmiziZemin,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Yönetici',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: kMarkaKirmizi,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          kisi.motorBilgisi.isNotEmpty
              ? '🏍️ ${kisi.motorBilgisi}'
              : 'Motosiklet belirtilmemiş',
          style: const TextStyle(fontSize: 12.5, color: kIkincilGri),
        ),
        trailing: arkadasMi
            ? OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            side: BorderSide(color: Colors.green.shade300),
          ),
          onPressed: () {
            if (benimUid != null) {
              _istekReddetVeyaCikar(benimUid, kisi.uid);
            }
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('Arkadaş', style: TextStyle(fontSize: 12)),
        )
            : benimYoneticiMi
            ? ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kKoyuAntrasit,
            foregroundColor: kAnaBeyaz,
            elevation: 0,
          ),
          onPressed: () {
            if (benimUid != null) {
              _yoneticiDirektArkadasEkle(
                  benimUid, kisi.uid, kisi.adSoyad);
            }
          },
          icon: const Icon(Icons.person_add, size: 16),
          label: const Text('Direkt Ekle',
              style: TextStyle(fontSize: 12)),
        )
            : istekGeldiMi
            ? ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: kAnaBeyaz,
            elevation: 0,
          ),
          onPressed: () {
            if (benimUid != null) {
              _istekOnayla(benimUid, kisi.uid, kisi.adSoyad);
            }
          },
          child: const Text('Onayla',
              style: TextStyle(fontSize: 12)),
        )
            : istekGonderildiMi
            ? TextButton(
          onPressed: () {
            if (benimUid != null) {
              _istekReddetVeyaCikar(benimUid, kisi.uid);
            }
          },
          child: const Text(
            'İstek Gönderildi',
            style:
            TextStyle(color: kIkincilGri, fontSize: 12),
          ),
        )
            : ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: kMarkaKirmizi,
            foregroundColor: kAnaBeyaz,
            elevation: 0,
          ),
          onPressed: () {
            if (benimUid == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Arkadaşlık isteği göndermek için önce giriş yapın.')),
              );
              return;
            }
            _istekGonder(benimUid, kisi.uid, kisi.adSoyad);
          },
          icon: const Icon(Icons.person_add_alt_1, size: 16),
          label: const Text('Ekle',
              style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}

// ============================================================================
// SEKME 2 (SAĞ): PROFİL / HESABIM (Giriş • Arkadaş Grupları • Talepler • Yönetici)
// ============================================================================
class ProfilVeYonetimSayfasi extends StatelessWidget {
  const ProfilVeYonetimSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: kMarkaKirmizi));
        }
        final user = authSnap.data;
        if (user == null) {
          return const MotorcuGirisKayitEkrani();
        }
        return HesabimPaneli(kullaniciUid: user.uid);
      },
    );
  }
}

class MotorcuGirisKayitEkrani extends StatefulWidget {
  const MotorcuGirisKayitEkrani({super.key});

  @override
  State<MotorcuGirisKayitEkrani> createState() =>
      _MotorcuGirisKayitEkraniState();
}

class _MotorcuGirisKayitEkraniState extends State<MotorcuGirisKayitEkrani> {
  bool _kayitModu = false;
  bool _yukleniyor = false;

  final _adController = TextEditingController();
  final _telController = TextEditingController();
  final _modelController = TextEditingController();
  final _emailController = TextEditingController();
  final _sifreController = TextEditingController();
  String _secilenMarka = 'Yamaha';

  @override
  void dispose() {
    _adController.dispose();
    _telController.dispose();
    _modelController.dispose();
    _emailController.dispose();
    _sifreController.dispose();
    super.dispose();
  }

  Future<void> _islemYap() async {
    final email = _emailController.text.trim();
    final sifre = _sifreController.text.trim();

    if (email.isEmpty || sifre.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Geçerli bir e-posta ve en az 6 haneli şifre girin.')),
      );
      return;
    }

    setState(() => _yukleniyor = true);
    try {
      if (_kayitModu) {
        final ad = _adController.text.trim();
        if (ad.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Lütfen adınızı ve soyadınızı girin.')),
          );
          setState(() => _yukleniyor = false);
          return;
        }

        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: sifre,
        );

        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(cred.user!.uid)
            .set({
          'uid': cred.user!.uid,
          'adSoyad': ad,
          'email': email,
          'telefon': _telController.text.trim(),
          'motorMarka': _secilenMarka,
          'motorModel': _modelController.text.trim(),
          'rol': 'motorcu',
          'yoneticiMi': false,
          'banliMi': false,
          'arkadaslar': <String>[],
          'gelenIstekler': <String>[],
          'gonderilenIstekler': <String>[],
          'kayitTarihi': FieldValue.serverTimestamp(),
          'sonGirisTarihi': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: sifre,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: ${e.message ?? ""}')),
      );
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _sifremiUnuttumPenceresi() async {
    final sEmailController =
        TextEditingController(text: _emailController.text.trim());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAnaBeyaz,
        title: const Text('Şifremi Unuttum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hesabınıza bağlı e-posta adresinizi girin. Şifrenizi yenilemeniz için e-posta göndereceğiz.',
              style: TextStyle(fontSize: 13, color: kIkincilGri),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: sEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta Adresi',
                prefixIcon: Icon(Icons.email_outlined, color: kMarkaKirmizi),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kMarkaKirmizi,
              foregroundColor: kAnaBeyaz,
            ),
            onPressed: () async {
              final email = sEmailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lütfen geçerli bir e-posta adresi girin.')),
                );
                return;
              }

              try {
                await FirebaseAuth.instance
                    .sendPasswordResetEmail(email: email);
                if (context.mounted) Navigator.pop(context);
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade700,
                    content: Text(
                        '$email adresine şifre sıfırlama bağlantısı gönderildi. E-postanızı (ve spam kutunuzu) kontrol edin.'),
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Hata: ${e.message ?? "İşlem başarısız."}')),
                  );
                }
              }
            },
            child: const Text('Sıfırlama Bağlantısı Gönder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kAcikKirmiziZemin,
              borderRadius: BorderRadius.circular(18),
              border:
              Border.all(color: kMarkaKirmizi.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                const _UstamAppLogo(size: 54),
                const SizedBox(height: 10),
                Text(
                  _kayitModu ? '$kMarkaAdiBaslik Kayıt' : '$kMarkaAdiBaslik Giriş',
                  style: const TextStyle(
                    color: kKoyuAntrasit,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ustalara talep gönder, arkadaşlarınla grup kur ve tamir geçmişini takip et.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kIkincilGri, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_kayitModu) ...[
            TextField(
              controller: _adController,
              decoration: const InputDecoration(
                labelText: 'Ad Soyad *',
                prefixIcon: Icon(Icons.person_outline, color: kMarkaKirmizi),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _telController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon Numarası',
                prefixIcon: Icon(Icons.phone_outlined, color: kMarkaKirmizi),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _secilenMarka,
              decoration: const InputDecoration(
                labelText: 'Motosiklet Markası',
                prefixIcon: Icon(Icons.two_wheeler, color: kMarkaKirmizi),
              ),
              items: kMotorMarkalari
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _secilenMarka = v);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Motosiklet Modeli (Örn: MT-25, CBR250R)',
                prefixIcon: Icon(Icons.edit_note, color: kMarkaKirmizi),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta *',
              prefixIcon: Icon(Icons.email_outlined, color: kMarkaKirmizi),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _sifreController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Şifre (En az 6 karakter) *',
              prefixIcon: Icon(Icons.lock_outline, color: kMarkaKirmizi),
            ),
          ),
          if (!_kayitModu)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _sifremiUnuttumPenceresi,
                child: const Text(
                  'Şifremi Unuttum?',
                  style: TextStyle(
                    color: kMarkaKirmizi,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kMarkaKirmizi,
              foregroundColor: kAnaBeyaz,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _yukleniyor ? null : _islemYap,
            child: _yukleniyor
                ? const CircularProgressIndicator(color: kAnaBeyaz)
                : Text(
              _kayitModu ? 'Kayıt Ol' : 'Giriş Yap',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _kayitModu = !_kayitModu),
            child: Text(
              _kayitModu
                  ? 'Zaten hesabın var mı? Giriş Yap'
                  : 'Hesabın yok mu? Hemen Kayıt Ol',
              style: const TextStyle(
                  color: kMarkaKirmizi, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class HesabimPaneli extends StatelessWidget {
  final String kullaniciUid;

  const HesabimPaneli({super.key, required this.kullaniciUid});

  Future<void> _profilDuzenlePenceresi(
      BuildContext context, Map<String, dynamic> data) async {
    final adController =
    TextEditingController(text: (data['adSoyad'] ?? '').toString());
    final telController =
    TextEditingController(text: (data['telefon'] ?? '').toString());
    final modelController =
    TextEditingController(text: (data['motorModel'] ?? '').toString());
    String marka = kMotorMarkalari.contains(data['motorMarka'])
        ? data['motorMarka'].toString()
        : 'Yamaha';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: const Text('Profil & Motor Bilgilerim'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: adController,
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: telController,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: marka,
                    decoration:
                    const InputDecoration(labelText: 'Motosiklet Markası'),
                    items: kMotorMarkalari
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => marka = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: modelController,
                    decoration:
                    const InputDecoration(labelText: 'Motosiklet Modeli'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(kullaniciUid)
                      .set({
                    'adSoyad': adController.text.trim(),
                    'telefon': telController.text.trim(),
                    'motorMarka': marka,
                    'motorModel': modelController.text.trim(),
                  }, SetOptions(merge: true));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(kullaniciUid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = (snapshot.data?.data() as Map<String, dynamic>?) ?? {};
        final adSoyad = (data['adSoyad'] ?? 'Motorcu').toString();
        final motorBilgisi =
        '${data['motorMarka'] ?? ''} ${data['motorModel'] ?? ''}'.trim();
        final bool yoneticiMi =
            data['yoneticiMi'] == true || data['rol'] == 'yonetici';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kAnaBeyaz,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: kInceCizgiGri),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: kAcikKirmiziZemin,
                    child: Text(
                      adSoyad.isNotEmpty ? adSoyad[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        color: kMarkaKirmizi,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adSoyad,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kKoyuAntrasit,
                          ),
                        ),
                        Text(
                          motorBilgisi.isNotEmpty
                              ? '🏍️ $motorBilgisi'
                              : 'Motosiklet bilgisi ekle',
                          style: const TextStyle(
                              color: kIkincilGri, fontSize: 13.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Profili Düzenle',
                    onPressed: () => _profilDuzenlePenceresi(context, data),
                    icon: const Icon(Icons.edit, color: kMarkaKirmizi),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (yoneticiMi)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kAcikKirmiziZemin,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: kMarkaKirmizi.withValues(alpha: 0.4), width: 1.4),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: kMarkaKirmizi,
                    child: Icon(Icons.admin_panel_settings, color: kAnaBeyaz),
                  ),
                  title: const Text(
                    'Yönetici Paneli',
                    style: TextStyle(
                      color: kKoyuAntrasit,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: const Text(
                    'Sistem genel istatistikleri, servis, grup, kullanıcı ve yorum yönetimi',
                    style: TextStyle(color: kIkincilGri, fontSize: 12),
                  ),
                  trailing:
                  const Icon(Icons.chevron_right, color: kMarkaKirmizi),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const YoneticiPaneliSayfasi()),
                    );
                  },
                ),
              ),
            ArkadasGruplariMenuOgesi(kullaniciUid: kullaniciUid),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: kAnaBeyaz,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kInceCizgiGri),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kAcikKirmiziZemin,
                  child:
                  Icon(Icons.notifications_active, color: kMarkaKirmizi),
                ),
                title: const Text(
                  'Tamir & Yol Yardım Taleplerim',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: kKoyuAntrasit),
                ),
                subtitle: const Text(
                  'Ustalara gönderdiğiniz taleplerin canlı durumu',
                  style: TextStyle(fontSize: 12.5, color: kIkincilGri),
                ),
                trailing:
                const Icon(Icons.chevron_right, color: kIkincilGri),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          MotorcuTaleplerimSayfasi(kullaniciUid: kullaniciUid),
                    ),
                  );
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: kAnaBeyaz,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kInceCizgiGri),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: kAcikKirmiziZemin,
                  child: Icon(Icons.history, color: kMarkaKirmizi),
                ),
                title: const Text(
                  'Tamir & Bakım Geçmişim',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: kKoyuAntrasit),
                ),
                subtitle: const Text(
                  'Servislerde tamamlanan tüm işlemleriniz',
                  style: TextStyle(fontSize: 12.5, color: kIkincilGri),
                ),
                trailing:
                const Icon(Icons.chevron_right, color: kIkincilGri),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TamirGecmisimSayfasi(kullaniciUid: kullaniciUid),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: kAnaBeyaz,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kInceCizgiGri),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: kMarkaKirmizi),
                title: const Text(
                  'Çıkış Yap',
                  style: TextStyle(
                      color: kMarkaKirmizi, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================================
// MOTORCU TALEPLERİM & TAMİR GEÇMİŞİM SAYFALARI
// ============================================================================
class MotorcuTaleplerimSayfasi extends StatelessWidget {
  final String kullaniciUid;
  const MotorcuTaleplerimSayfasi({super.key, required this.kullaniciUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taleplerim')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('talepler')
            .where('motorcuUid', isEqualTo: kullaniciUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: kMarkaKirmizi));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz bir servis talebi oluşturmadınız.',
                style: TextStyle(color: kIkincilGri),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              final durum = (d['durum'] ?? 'bekliyor').toString();
              Color renk = Colors.orange.shade800;
              String etiket = 'Onay Bekliyor';
              if (durum == 'onaylandi') {
                renk = Colors.blue.shade700;
                etiket = 'Usta Onayladı';
              } else if (durum == 'tamamlandi') {
                renk = Colors.green.shade700;
                etiket = 'Tamamlandı';
              } else if (durum == 'reddedildi') {
                renk = kMarkaKirmizi;
                etiket = 'Reddedildi';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kAnaBeyaz,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kInceCizgiGri),
                ),
                child: ListTile(
                  title: Text(
                    '${d['servisAdi'] ?? 'Servis'} • ${d['talepTuru'] ?? ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: kKoyuAntrasit),
                  ),
                  subtitle: Text(
                    d['aciklama'] ?? '',
                    style: const TextStyle(color: kIkincilGri),
                  ),
                  trailing: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: renk.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      etiket,
                      style: TextStyle(
                        color: renk,
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TamirGecmisimSayfasi extends StatelessWidget {
  final String kullaniciUid;
  const TamirGecmisimSayfasi({super.key, required this.kullaniciUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tamir Geçmişim')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tamir_kayitlari')
            .where('kullaniciUid', isEqualTo: kullaniciUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: kMarkaKirmizi));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz tamamlanmış tamir kaydınız bulunmuyor.',
                style: TextStyle(color: kIkincilGri),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: kAnaBeyaz,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kInceCizgiGri),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: kAcikKirmiziZemin,
                    child: Icon(Icons.build, color: kMarkaKirmizi),
                  ),
                  title: Text(
                    d['servisAdi'] ?? 'Servis',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: kKoyuAntrasit),
                  ),
                  subtitle: Text(
                    '${d['yapilanIslem'] ?? ''} • Tarih: ${d['tarih'] ?? ''}',
                    style: const TextStyle(color: kIkincilGri),
                  ),
                  trailing: Text(
                    (d['ucret'] ?? '').toString().isNotEmpty
                        ? '${d['ucret']} ₺'
                        : '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: kMarkaKirmizi,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// HESABIM -> ARKADAŞ GRUPLARI MENÜ ÖĞESİ, LİSTE VE @BİLDİRİMLİ GRUP SOHBETİ
// ============================================================================
class ArkadasGruplariMenuOgesi extends StatelessWidget {
  final String kullaniciUid;

  const ArkadasGruplariMenuOgesi({super.key, required this.kullaniciUid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bildirimler')
          .where('aliciUid', isEqualTo: kullaniciUid)
          .where('okunduMu', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final okunmamisSayi = snap.hasData ? snap.data!.docs.length : 0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: kAnaBeyaz,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kInceCizgiGri),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: kAcikKirmiziZemin,
              child: Icon(Icons.groups, color: kMarkaKirmizi),
            ),
            title: const Text(
              'Arkadaş Grupları',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: kKoyuAntrasit,
              ),
            ),
            subtitle: const Text(
              'Sürüş grupları oluştur, arkadaşlarınla sohbet et',
              style: TextStyle(fontSize: 12.5, color: kIkincilGri),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (okunmamisSayi > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kMarkaKirmizi,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '@$okunmamisSayi',
                      style: const TextStyle(
                        color: kAnaBeyaz,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Icon(Icons.chevron_right, color: kIkincilGri),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ArkadasGruplariSayfasi(kullaniciUid: kullaniciUid),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ArkadasGruplariSayfasi extends StatefulWidget {
  final String kullaniciUid;

  const ArkadasGruplariSayfasi({super.key, required this.kullaniciUid});

  @override
  State<ArkadasGruplariSayfasi> createState() => _ArkadasGruplariSayfasiState();
}

class _ArkadasGruplariSayfasiState extends State<ArkadasGruplariSayfasi> {
  Future<void> _yeniGrupOlusturPenceresi() async {
    final grupAdiController = TextEditingController();
    final secilenArkadaslar = <String>[];

    final benimDoc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(widget.kullaniciUid)
        .get();
    final benimData = benimDoc.data() ?? {};
    final kurucuAdi = (benimData['adSoyad'] ?? 'Kurucu').toString();
    final arkadasUidleri = List<String>.from(benimData['arkadaslar'] ?? []);

    final tumKullanicilarSnap =
    await FirebaseFirestore.instance.collection('kullanicilar').get();
    final onayliArkadaslar = tumKullanicilarSnap.docs
        .map((d) => _MotorcuKisi.fromDoc(d))
        .where((k) => arkadasUidleri.contains(k.uid) && !k.banliMi)
        .toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: const Text('Yeni Arkadaş Grubu Oluştur'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: grupAdiController,
                    decoration: const InputDecoration(
                      labelText: 'Grup Adı (Örn: Pazar Sürüş Ekibi)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gruba Eklenecek Arkadaşlarını Seç:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  if (onayliArkadaslar.isEmpty)
                    const Text(
                      'Henüz onaylanmış arkadaşınız yok. Önce Arkadaşlar sekmesinden arkadaş ekleyin.',
                      style: TextStyle(fontSize: 12.5, color: kIkincilGri),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: onayliArkadaslar.length,
                        itemBuilder: (context, i) {
                          final arkadas = onayliArkadaslar[i];
                          final secili =
                          secilenArkadaslar.contains(arkadas.uid);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: kMarkaKirmizi,
                            title: Text(arkadas.adSoyad),
                            subtitle: Text(arkadas.motorBilgisi),
                            value: secili,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  secilenArkadaslar.add(arkadas.uid);
                                } else {
                                  secilenArkadaslar.remove(arkadas.uid);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: () async {
                  final ad = grupAdiController.text.trim();
                  if (ad.isEmpty) return;

                  final uyeler = <String>{
                    widget.kullaniciUid,
                    ...secilenArkadaslar,
                  }.toList();

                  final yeniGrup = await FirebaseFirestore.instance
                      .collection('arkadas_gruplari')
                      .add({
                    'grupAdi': ad,
                    'kurucuUid': widget.kullaniciUid,
                    'kurucuAdi': kurucuAdi,
                    'uyeler': uyeler,
                    'katilmaIstekleri': <String>[],
                    'banliUyeler': <String>[],
                    'aktifMi': true,
                    'sonMesaj': '$kurucuAdi grubu oluşturdu.',
                    'sonMesajTarihi': FieldValue.serverTimestamp(),
                    'olusturmaTarihi': FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GrupSohbetSayfasi(
                        grupId: yeniGrup.id,
                        mevcutUid: widget.kullaniciUid,
                      ),
                    ),
                  );
                },
                child: const Text('Grubu Kur'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kZeminKirikBeyaz,
      appBar: AppBar(
        title: const Text('Arkadaş Grupları'),
        actions: [
          IconButton(
            tooltip: 'Yeni Grup Oluştur',
            onPressed: _yeniGrupOlusturPenceresi,
            icon: const Icon(Icons.group_add, color: kMarkaKirmizi),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kMarkaKirmizi,
        foregroundColor: kAnaBeyaz,
        elevation: 1,
        onPressed: _yeniGrupOlusturPenceresi,
        icon: const Icon(Icons.add),
        label: const Text('Grup Oluştur'),
      ),
      body: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bildirimler')
                .where('aliciUid', isEqualTo: widget.kullaniciUid)
                .where('okunduMu', isEqualTo: false)
                .snapshots(),
            builder: (context, bildirimSnap) {
              if (!bildirimSnap.hasData || bildirimSnap.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              final ilkDoc = bildirimSnap.data!.docs.first;
              final b = ilkDoc.data() as Map<String, dynamic>;

              return Container(
                width: double.infinity,
                color: kAcikKirmiziZemin,
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email, color: kMarkaKirmizi),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${b['grupAdi'] ?? 'Grup'}: ${b['gonderenAdi'] ?? 'Üye'} sizden bahsetti -> "${b['mesaj'] ?? ''}"',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: kKoyuAntrasit,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await ilkDoc.reference.update({'okunduMu': true});
                        if (!context.mounted) return;
                        if ((b['grupId'] ?? '').toString().isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GrupSohbetSayfasi(
                                grupId: b['grupId'],
                                mevcutUid: widget.kullaniciUid,
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Git',
                        style: TextStyle(color: kMarkaKirmizi),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('arkadas_gruplari')
                  .where('uyeler', arrayContains: widget.kullaniciUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: kMarkaKirmizi));
                }

                final gruplar = snapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final banlilar = List<String>.from(d['banliUyeler'] ?? []);
                  return d['aktifMi'] != false &&
                      !banlilar.contains(widget.kullaniciUid);
                }).toList();

                if (gruplar.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined,
                              size: 60, color: kMarkaKirmizi),
                          SizedBox(height: 12),
                          Text(
                            'Henüz dahil olduğunuz bir arkadaş grubu yok.\nSağ alttaki "Grup Oluştur" butonuna basarak arkadaşlarınızla sohbet grubu kurabilirsiniz.',
                            textAlign: TextAlign.center,
                            style:
                            TextStyle(color: kIkincilGri, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: gruplar.length,
                  itemBuilder: (context, index) {
                    final doc = gruplar[index];
                    final d = doc.data() as Map<String, dynamic>;
                    final bool kurucuMu = d['kurucuUid'] == widget.kullaniciUid;
                    final uyeler = List<String>.from(d['uyeler'] ?? []);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: kAnaBeyaz,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kInceCizgiGri),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: kAcikKirmiziZemin,
                          child: Text(
                            (d['grupAdi'] ?? 'G')
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: kMarkaKirmizi,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                d['grupAdi'] ?? 'Grup',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                            ),
                            if (kurucuMu)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kAcikKirmiziZemin,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Kurucu',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: kMarkaKirmizi,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          '${uyeler.length} Üye • ${d['sonMesaj'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: kIkincilGri),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: kIkincilGri),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GrupSohbetSayfasi(
                                grupId: doc.id,
                                mevcutUid: widget.kullaniciUid,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GrupSohbetSayfasi extends StatefulWidget {
  final String grupId;
  final String mevcutUid;

  const GrupSohbetSayfasi({
    super.key,
    required this.grupId,
    required this.mevcutUid,
  });

  @override
  State<GrupSohbetSayfasi> createState() => _GrupSohbetSayfasiState();
}

class _GrupSohbetSayfasiState extends State<GrupSohbetSayfasi> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _etiketListesiAcik = false;
  String _etiketArama = '';

  @override
  void initState() {
    super.initState();
    _okunmamisEtiketleriTemizle();
  }

  Future<void> _okunmamisEtiketleriTemizle() async {
    final snap = await FirebaseFirestore.instance
        .collection('bildirimler')
        .where('aliciUid', isEqualTo: widget.mevcutUid)
        .where('grupId', isEqualTo: widget.grupId)
        .where('okunduMu', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'okunduMu': true});
    }
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _metinDegisti(String deger) {
    final sonAtIndeksi = deger.lastIndexOf('@');
    if (sonAtIndeksi != -1) {
      final parca = deger.substring(sonAtIndeksi + 1);
      if (!parca.contains('\n') && parca.length <= 20) {
        setState(() {
          _etiketListesiAcik = true;
          _etiketArama = parca;
        });
        return;
      }
    }
    if (_etiketListesiAcik) {
      setState(() => _etiketListesiAcik = false);
    }
  }

  void _uyeEtiketSec(String adSoyad) {
    final metin = _mesajController.text;
    final sonAt = metin.lastIndexOf('@');
    final yeniMetin = sonAt != -1
        ? '${metin.substring(0, sonAt)}@$adSoyad '
        : '$metin@$adSoyad ';
    _mesajController.value = TextEditingValue(
      text: yeniMetin,
      selection: TextSelection.collapsed(offset: yeniMetin.length),
    );
    setState(() {
      _etiketListesiAcik = false;
      _etiketArama = '';
    });
  }

  Future<void> _mesajGonder({
    required String grupAdi,
    required String gonderenAdi,
    required List<_MotorcuKisi> grupUyeleri,
  }) async {
    final metin = _mesajController.text.trim();
    if (metin.isEmpty) return;

    _mesajController.clear();
    setState(() => _etiketListesiAcik = false);

    final etiketlenenUidler = <String>[];
    final kucukMetin = _trKucuk(metin);

    for (final uye in grupUyeleri) {
      if (uye.uid == widget.mevcutUid) continue;
      final etiket = '@${_trKucuk(uye.adSoyad)}';
      if (kucukMetin.contains(etiket)) {
        etiketlenenUidler.add(uye.uid);
      }
    }

    final grupRef = FirebaseFirestore.instance
        .collection('arkadas_gruplari')
        .doc(widget.grupId);

    await grupRef.collection('mesajlar').add({
      'gonderenUid': widget.mevcutUid,
      'gonderenAdi': gonderenAdi,
      'metin': metin,
      'etiketlenenUidler': etiketlenenUidler,
      'tarih': FieldValue.serverTimestamp(),
    });

    await grupRef.update({
      'sonMesaj': '$gonderenAdi: $metin',
      'sonMesajTarihi': FieldValue.serverTimestamp(),
    });

    for (final hedefUid in etiketlenenUidler) {
      await FirebaseFirestore.instance.collection('bildirimler').add({
        'aliciUid': hedefUid,
        'gonderenUid': widget.mevcutUid,
        'gonderenAdi': gonderenAdi,
        'grupId': widget.grupId,
        'grupAdi': grupAdi,
        'mesaj': metin,
        'tur': 'grup_etiket',
        'okunduMu': false,
        'tarih': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _grubaArkadasEkle(
      List<String> mevcutUyeler, List<_MotorcuKisi> tumMotorcular) async {
    final benimDoc = await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(widget.mevcutUid)
        .get();
    final arkadaslar =
    List<String>.from((benimDoc.data() ?? {})['arkadaslar'] ?? []);

    final eklenebilirler = tumMotorcular.where((k) {
      return arkadaslar.contains(k.uid) &&
          !mevcutUyeler.contains(k.uid) &&
          !k.banliMi;
    }).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAnaBeyaz,
        title: const Text('Gruba Arkadaş Ekle'),
        content: eklenebilirler.isEmpty
            ? const Text('Gruba eklenebilecek başka onaylı arkadaşınız yok.')
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: eklenebilirler.length,
            itemBuilder: (context, i) {
              final kisi = eklenebilirler[i];
              return ListTile(
                title: Text(kisi.adSoyad),
                subtitle: Text(kisi.motorBilgisi),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMarkaKirmizi,
                    foregroundColor: kAnaBeyaz,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('arkadas_gruplari')
                        .doc(widget.grupId)
                        .update({
                      'uyeler': FieldValue.arrayUnion([kisi.uid]),
                      'katilmaIstekleri':
                      FieldValue.arrayRemove([kisi.uid]),
                      'banliUyeler': FieldValue.arrayRemove([kisi.uid]),
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Ekle'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('arkadas_gruplari')
          .doc(widget.grupId)
          .snapshots(),
      builder: (context, grupSnap) {
        if (!grupSnap.hasData) {
          return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator(color: kMarkaKirmizi)));
        }

        if (!grupSnap.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Grup')),
            body: const Center(child: Text('Bu grup kapatılmış veya silinmiş.')),
          );
        }

        final grupData =
            (grupSnap.data!.data() as Map<String, dynamic>?) ?? {};
        final grupAdi = (grupData['grupAdi'] ?? 'Arkadaş Grubu').toString();
        final kurucuUid = (grupData['kurucuUid'] ?? '').toString();
        final bool kurucuMu = kurucuUid == widget.mevcutUid;
        final bool aktifMi = grupData['aktifMi'] != false;
        final uyeUidleri = List<String>.from(grupData['uyeler'] ?? []);
        final katilmaIstekUidleri =
        List<String>.from(grupData['katilmaIstekleri'] ?? []);
        final banliUyeler = List<String>.from(grupData['banliUyeler'] ?? []);

        if (!aktifMi ||
            !uyeUidleri.contains(widget.mevcutUid) ||
            banliUyeler.contains(widget.mevcutUid)) {
          return Scaffold(
            appBar: AppBar(title: Text(grupAdi)),
            body: const Center(
              child: Text(
                'Bu grup kapatıldı veya gruptan çıkarıldınız.',
                style: TextStyle(color: kIkincilGri, fontSize: 15),
              ),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('kullanicilar')
              .snapshots(),
          builder: (context, kullaniciSnap) {
            final tumMotorcular = kullaniciSnap.hasData
                ? kullaniciSnap.data!.docs
                .map((d) => _MotorcuKisi.fromDoc(d))
                .toList()
                : <_MotorcuKisi>[];

            final grupUyeleri = tumMotorcular
                .where((k) => uyeUidleri.contains(k.uid))
                .toList();

            final bekleyenIstekKisileri = tumMotorcular
                .where((k) => katilmaIstekUidleri.contains(k.uid))
                .toList();

            String benimAdim = 'Motorcu';
            for (final k in tumMotorcular) {
              if (k.uid == widget.mevcutUid) {
                benimAdim = k.adSoyad;
                break;
              }
            }

            final filtrelenmisEtiketUyeleri = grupUyeleri.where((u) {
              if (u.uid == widget.mevcutUid) return false;
              if (_etiketArama.isEmpty) return true;
              return _trKucuk(u.adSoyad).contains(_trKucuk(_etiketArama));
            }).toList();

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: kZeminKirikBeyaz,
              drawer: Drawer(
                backgroundColor: kAnaBeyaz,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        color: kAcikKirmiziZemin,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              grupAdi,
                              style: const TextStyle(
                                color: kKoyuAntrasit,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Grup Üyeleri (${grupUyeleri.length} Kişi)',
                              style: const TextStyle(
                                color: kMarkaKirmizi,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (kurucuMu)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kMarkaKirmizi,
                              foregroundColor: kAnaBeyaz,
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              _grubaArkadasEkle(uyeUidleri, tumMotorcular);
                            },
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Arkadaş Ekle'),
                          ),
                        ),
                      if (kurucuMu && bekleyenIstekKisileri.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
                          child: Text(
                            'Katılma İstekleri',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: kMarkaKirmizi,
                            ),
                          ),
                        ),
                        ...bekleyenIstekKisileri.map((aday) {
                          return ListTile(
                            dense: true,
                            title: Text(aday.adSoyad,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(aday.motorBilgisi,
                                style: const TextStyle(fontSize: 11.5)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Onayla',
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.green.shade700, size: 22),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('arkadas_gruplari')
                                        .doc(widget.grupId)
                                        .update({
                                      'katilmaIstekleri':
                                      FieldValue.arrayRemove([aday.uid]),
                                      'uyeler':
                                      FieldValue.arrayUnion([aday.uid]),
                                    });
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Reddet',
                                  icon: const Icon(Icons.cancel,
                                      color: kMarkaKirmizi, size: 22),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('arkadas_gruplari')
                                        .doc(widget.grupId)
                                        .update({
                                      'katilmaIstekleri':
                                      FieldValue.arrayRemove([aday.uid]),
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(color: kInceCizgiGri),
                      ],
                      Expanded(
                        child: ListView.builder(
                          itemCount: grupUyeleri.length,
                          itemBuilder: (context, index) {
                            final uye = grupUyeleri[index];
                            final bool uyeKurucuMu = uye.uid == kurucuUid;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kAcikKirmiziZemin,
                                child: Text(
                                  uye.adSoyad.isNotEmpty
                                      ? uye.adSoyad[0].toUpperCase()
                                      : 'M',
                                  style: const TextStyle(
                                    color: kMarkaKirmizi,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      uye.adSoyad,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: kKoyuAntrasit,
                                      ),
                                    ),
                                  ),
                                  if (uyeKurucuMu)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: kAcikKirmiziZemin,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Kurucu',
                                        style: TextStyle(
                                          color: kMarkaKirmizi,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                uye.motorBilgisi,
                                style: const TextStyle(
                                    fontSize: 12, color: kIkincilGri),
                              ),
                              trailing: uye.uid == widget.mevcutUid
                                  ? null
                                  : PopupMenuButton<String>(
                                onSelected: (secim) async {
                                  if (secim == 'etiketle') {
                                    Navigator.pop(context);
                                    _uyeEtiketSec(uye.adSoyad);
                                  } else if (secim == 'devret' &&
                                      kurucuMu) {
                                    await FirebaseFirestore.instance
                                        .collection('arkadas_gruplari')
                                        .doc(widget.grupId)
                                        .update({
                                      'kurucuUid': uye.uid,
                                      'kurucuAdi': uye.adSoyad,
                                    });
                                  } else if (secim == 'cikar' &&
                                      kurucuMu) {
                                    await FirebaseFirestore.instance
                                        .collection('arkadas_gruplari')
                                        .doc(widget.grupId)
                                        .update({
                                      'uyeler': FieldValue.arrayRemove(
                                          [uye.uid]),
                                    });
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'etiketle',
                                    child: Text('@Etiketle ve Bildir'),
                                  ),
                                  if (kurucuMu) ...[
                                    const PopupMenuItem(
                                      value: 'devret',
                                      child: Text('Yöneticiliği Devret'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'cikar',
                                      child: Text(
                                        'Gruptan Çıkar',
                                        style: TextStyle(
                                            color: kMarkaKirmizi),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1, color: kInceCizgiGri),
                      if (kurucuMu)
                        ListTile(
                          leading:
                          const Icon(Icons.block, color: kMarkaKirmizi),
                          title: const Text(
                            'Grubu Kapat',
                            style: TextStyle(
                              color: kMarkaKirmizi,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('arkadas_gruplari')
                                .doc(widget.grupId)
                                .update({'aktifMi': false});
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          },
                        )
                      else
                        ListTile(
                          leading: const Icon(Icons.exit_to_app,
                              color: kMarkaKirmizi),
                          title: const Text(
                            'Gruptan Ayrıl',
                            style: TextStyle(color: kMarkaKirmizi),
                          ),
                          onTap: () async {
                            await FirebaseFirestore.instance
                                .collection('arkadas_gruplari')
                                .doc(widget.grupId)
                                .update({
                              'uyeler':
                              FieldValue.arrayRemove([widget.mevcutUid]),
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              appBar: AppBar(
                leading: IconButton(
                  tooltip: 'Grup Üyeleri',
                  icon: const Icon(Icons.menu, color: kKoyuAntrasit),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grupAdi,
                      style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: kKoyuAntrasit),
                    ),
                    Text(
                      '${grupUyeleri.length} Üye • Üyeler için sol üst menüye dokun',
                      style:
                      const TextStyle(fontSize: 11, color: kIkincilGri),
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('arkadas_gruplari')
                          .doc(widget.grupId)
                          .collection('mesajlar')
                          .orderBy('tarih', descending: true)
                          .snapshots(),
                      builder: (context, mesajSnap) {
                        if (!mesajSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: kMarkaKirmizi));
                        }
                        final mesajDocs = mesajSnap.data!.docs;

                        if (mesajDocs.isEmpty) {
                          return const Center(
                            child: Text(
                              'Henüz mesaj yok. İlk mesajı yazın veya @ ile bir arkadaşınızı etiketleyin!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: kIkincilGri),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.all(14),
                          itemCount: mesajDocs.length,
                          itemBuilder: (context, index) {
                            final m = mesajDocs[index].data()
                            as Map<String, dynamic>;
                            final bool benimMesajim =
                                m['gonderenUid'] == widget.mevcutUid;
                            final etiketlenenler = List<String>.from(
                                m['etiketlenenUidler'] ?? []);
                            final bool banaEtiketVar =
                            etiketlenenler.contains(widget.mevcutUid);

                            return Align(
                              alignment: benimMesajim
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                  MediaQuery.of(context).size.width * 0.76,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: benimMesajim
                                      ? kMarkaKirmizi
                                      : banaEtiketVar
                                      ? kAcikKirmiziZemin
                                      : kAnaBeyaz,
                                  borderRadius: BorderRadius.circular(14),
                                  border: !benimMesajim
                                      ? Border.all(
                                    color: banaEtiketVar
                                        ? kMarkaKirmizi
                                        : kInceCizgiGri,
                                    width: banaEtiketVar ? 1.4 : 1,
                                  )
                                      : null,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!benimMesajim)
                                      Padding(
                                        padding:
                                        const EdgeInsets.only(bottom: 3),
                                        child: Text(
                                          m['gonderenAdi'] ?? 'Üye',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: kMarkaKirmizi,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      m['metin'] ?? '',
                                      style: TextStyle(
                                        color: benimMesajim
                                            ? kAnaBeyaz
                                            : kKoyuAntrasit,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_etiketListesiAcik &&
                      filtrelenmisEtiketUyeleri.isNotEmpty)
                    Container(
                      height: 48,
                      color: kAnaBeyaz,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filtrelenmisEtiketUyeleri.length,
                        itemBuilder: (context, i) {
                          final u = filtrelenmisEtiketUyeleri[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            child: ActionChip(
                              backgroundColor: kAcikKirmiziZemin,
                              avatar: const Icon(Icons.alternate_email,
                                  size: 16, color: kMarkaKirmizi),
                              label: Text(
                                u.adSoyad,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                              onPressed: () => _uyeEtiketSec(u.adSoyad),
                            ),
                          );
                        },
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      color: kAnaBeyaz,
                      border: Border(top: BorderSide(color: kInceCizgiGri)),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Üye Etiketle (@)',
                            onPressed: () {
                              final guncel = '${_mesajController.text}@';
                              _mesajController.value = TextEditingValue(
                                text: guncel,
                                selection: TextSelection.collapsed(
                                    offset: guncel.length),
                              );
                              _metinDegisti(guncel);
                            },
                            icon: const Icon(Icons.alternate_email,
                                color: kMarkaKirmizi),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _mesajController,
                              onChanged: _metinDegisti,
                              decoration: InputDecoration(
                                hintText:
                                'Mesaj yaz (@ ile üyeye direkt bildirim gönder)...',
                                hintStyle: const TextStyle(
                                    fontSize: 13, color: kIkincilGri),
                                filled: true,
                                fillColor: kZeminKirikBeyaz,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            backgroundColor: kMarkaKirmizi,
                            child: IconButton(
                              icon: const Icon(Icons.send,
                                  color: kAnaBeyaz, size: 20),
                              onPressed: () => _mesajGonder(
                                grupAdi: grupAdi,
                                gonderenAdi: benimAdim,
                                grupUyeleri: grupUyeleri,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// YÖNETİCİ PANELİ
// (1. SERVİSLER EKLE/GÜNCELLE/ONAY/PASİF • 2. GRUPLAR • 3. MOTORCULAR • 4. YORUMLAR • 5. İSTATİSTİKLER)
// ============================================================================
class YoneticiPaneliSayfasi extends StatelessWidget {
  const YoneticiPaneliSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetici Paneli'),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: kMarkaKirmizi,
            labelColor: kMarkaKirmizi,
            unselectedLabelColor: kIkincilGri,
            tabs: [
              Tab(icon: Icon(Icons.store), text: 'Servisler'),
              Tab(icon: Icon(Icons.groups), text: 'Gruplar'),
              Tab(icon: Icon(Icons.two_wheeler), text: 'Motorcular'),
              Tab(icon: Icon(Icons.reviews), text: 'Yorumlar'),
              Tab(icon: Icon(Icons.bar_chart), text: 'İstatistikler'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            YoneticiServisOnayListesi(),
            YoneticiGrupYonetimiSayfasi(),
            YoneticiMotorcularListesi(),
            YoneticiYorumlarListesi(),
            YoneticiIstatistikSayfasi(),
          ],
        ),
      ),
    );
  }
}

class YoneticiServisOnayListesi extends StatefulWidget {
  const YoneticiServisOnayListesi({super.key});

  @override
  State<YoneticiServisOnayListesi> createState() =>
      _YoneticiServisOnayListesiState();
}

class _YoneticiServisOnayListesiState extends State<YoneticiServisOnayListesi> {
  String _seciliFiltre = 'tumu';

  String _telefonTemizle(String ham) {
    final rakamlar = ham.replaceAll(RegExp(r'\D'), '');
    if (rakamlar.length == 11 && rakamlar.startsWith('0')) {
      return '90${rakamlar.substring(1)}';
    }
    if (rakamlar.length == 10 && rakamlar.startsWith('5')) {
      return '90$rakamlar';
    }
    return rakamlar;
  }

  Future<void> _exceldenTopluYuklePenceresi() async {
    final veriController = TextEditingController();
    bool eskileriSil = true;
    bool yukleniyor = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: const Text('Excel\'den Toplu Servis Yükle'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excel\'de sütunları şu sırayla seçip kopyalayın (Ctrl+C) ve aşağıya yapıştırın:\n'
                          'Dükkan Adı | Usta Adı | Telefon | İl | İlçe | Adres | Enlem | Boylam | Markalar',
                      style: TextStyle(fontSize: 12, color: kIkincilGri),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: veriController,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        hintText: 'Excel satırlarını buraya yapıştırın (Ctrl+V)...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      activeColor: kMarkaKirmizi,
                      title: const Text(
                        'Yüklemeden önce mevcut tüm servisleri sil',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      value: eskileriSil,
                      onChanged: (v) =>
                          setDialogState(() => eskileriSil = v ?? true),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: yukleniyor ? null : () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: yukleniyor
                    ? null
                    : () async {
                  final hamMetin = veriController.text.trim();
                  if (hamMetin.isEmpty) return;

                  setDialogState(() => yukleniyor = true);
                  final db = FirebaseFirestore.instance;
                  final servisRef = db.collection('servisler');

                  if (eskileriSil) {
                    final eskiler = await servisRef.get();
                    for (var i = 0; i < eskiler.docs.length; i += 400) {
                      final silBatch = db.batch();
                      for (final doc
                      in eskiler.docs.skip(i).take(400)) {
                        silBatch.delete(doc.reference);
                      }
                      await silBatch.commit();
                    }
                  }

                  final satirlar = hamMetin
                      .split(RegExp(r'\r?\n'))
                      .where((s) => s.trim().isNotEmpty)
                      .toList();

                  final yeniKayitlar = <Map<String, dynamic>>[];

                  for (final satir in satirlar) {
                  final sutun = satir.split('\t');
                  final dukkanAdi =
                  sutun.isNotEmpty ? sutun[0].trim() : '';
                  if (dukkanAdi.isEmpty) continue;

                  final ustaAdi =
                  sutun.length > 1 && sutun[1].trim().isNotEmpty
                  ? sutun[1].trim()
                      : 'Yetkili Usta';
                  final telefon = sutun.length > 2
                  ? _telefonTemizle(sutun[2])
                      : '';
                  final il =
                  sutun.length > 3 ? sutun[3].trim() : '';
                  final ilce =
                  sutun.length > 4 ? sutun[4].trim() : '';
                  final adres =
                  sutun.length > 5 ? sutun[5].trim() : '';

                  final enlem = sutun.length > 6
                  ? double.tryParse(sutun[6]
                      .trim()
                      .replaceAll(',', '.')) ??
                  41.0082
                      : 41.0082;
                  final boylam = sutun.length > 7
                  ? double.tryParse(sutun[7]
                      .trim()
                      .replaceAll(',', '.')) ??
                  28.9784
                      : 28.9784;

                  final markaMetni =
                  sutun.length > 8 ? sutun[8].trim() : '';
                  final markalar = markaMetni.isNotEmpty
                  ? markaMetni
                      .split(',')
                      .map((m) => m.trim())
                      .where((m) => m.isNotEmpty)
                      .toList()
                      : List<String>.from(kMotorMarkalari);

                  yeniKayitlar.add({
                  'dukkanAdi': dukkanAdi,
                  'ustaAdi': ustaAdi,
                  'ustalar': [ustaAdi],
                  'telefon': telefon,
                  'il': il,
                  'ilce': ilce,
                  'adres': adres,
                  'enlem': enlem,
                  'boylam': boylam,
                  'baktigiMarkalar': markalar,
                  'verilenHizmetler': [
                  'Periyodik Bakım',
                  'Motor Mekanik & Rektefiye'
                  ],
                  'calismaSaatleri': 'Hafta içi 09:00 - 19:00',
                  'dukkanAcikMi': true,
                  'yoneticiOnayliMi': true,
                  'onayDurumu': 'onaylandi',
                  'banliMi': false,
                  'ortalamaPuan': 5.0,
                  'yorumSayisi': 0,
                  'begeniSayisi': 0,
                  'tamamlananHizmetSayisi': 0,
                  'aylikHizmetSayisi': 0,
                  'sistemIndirimAktifMi': false,
                  'sistemIndirimTutari': 200,
                  'olusturmaTarihi': FieldValue.serverTimestamp(),
                  });
                  }

                  for (var i = 0; i < yeniKayitlar.length; i += 400) {
                  final ekleBatch = db.batch();
                  for (final veri
                  in yeniKayitlar.skip(i).take(400)) {
                  ekleBatch.set(servisRef.doc(), veri);
                  }
                  await ekleBatch.commit();
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                  backgroundColor: Colors.green.shade700,
                  content: Text(
                  '${yeniKayitlar.length} servis başarıyla yüklendi!'),
                  ),
                  );
                },
                child: Text(yukleniyor ? 'Yükleniyor...' : 'Toplu Yükle'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _servisEkleVeyaGuncellePenceresi({_ServisModeli? servis}) async {
    final bool duzenlemeModu = servis != null;

    final dukkanController =
    TextEditingController(text: servis?.dukkanAdi ?? '');
    final ustaController =
    TextEditingController(text: servis?.ustaAdi ?? '');
    final telController =
    TextEditingController(text: servis?.telefon ?? '');
    final ilController = TextEditingController(text: servis?.il ?? '');
    final ilceController = TextEditingController(text: servis?.ilce ?? '');
    final adresController = TextEditingController(text: servis?.adres ?? '');
    final saatController = TextEditingController(
        text: servis?.calismaSaatleri ?? 'Hafta içi 09:00 - 19:00');
    final enlemController =
    TextEditingController(text: (servis?.enlem ?? 41.0082).toString());
    final boylamController =
    TextEditingController(text: (servis?.boylam ?? 28.9784).toString());
    final hizmetlerController = TextEditingController(
        text: servis != null ? servis.verilenHizmetler.join(', ') : '');
    final indirimTutarController = TextEditingController(
        text: (servis?.sistemIndirimTutari ?? 200).toString());

    final secilenMarkalar = List<String>.from(
        servis != null ? servis.baktigiMarkalar : kMotorMarkalari);
    bool dukkanAcik = servis?.dukkanAcikMi ?? true;
    bool yayindaOnayli = servis != null
        ? (servis.yoneticiOnayliMi && servis.onayDurumu == 'onaylandi')
        : true;
    bool sistemIndirim = servis?.sistemIndirimAktifMi ?? false;
    bool konumAliniyor = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: Text(duzenlemeModu
                ? 'Servisi Güncelle: ${servis.dukkanAdi}'
                : 'Yeni Servis Ekle'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: dukkanController,
                      decoration:
                      const InputDecoration(labelText: 'Dükkan Adı *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ustaController,
                      decoration:
                      const InputDecoration(labelText: 'Usta Adı Soyadı *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: telController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Telefon'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ilController,
                            decoration: const InputDecoration(labelText: 'İl'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: ilceController,
                            decoration:
                            const InputDecoration(labelText: 'İlçe'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: adresController,
                      maxLines: 2,
                      decoration:
                      const InputDecoration(labelText: 'Açık Adres'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: saatController,
                      decoration:
                      const InputDecoration(labelText: 'Çalışma Saatleri'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: enlemController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                            const InputDecoration(labelText: 'Enlem (Lat)'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: boylamController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Boylam (Lng)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kMarkaKirmizi,
                        side: const BorderSide(color: kMarkaKirmizi),
                      ),
                      onPressed: konumAliniyor
                          ? null
                          : () async {
                        setDialogState(() => konumAliniyor = true);
                        try {
                          LocationPermission izin =
                          await Geolocator.checkPermission();
                          if (izin == LocationPermission.denied) {
                            izin = await Geolocator.requestPermission();
                          }
                          final pos =
                          await Geolocator.getCurrentPosition();
                          setDialogState(() {
                            enlemController.text =
                                pos.latitude.toStringAsFixed(6);
                            boylamController.text =
                                pos.longitude.toStringAsFixed(6);
                          });
                        } catch (_) {}
                        setDialogState(() => konumAliniyor = false);
                      },
                      icon: const Icon(Icons.my_location, size: 17),
                      label: Text(konumAliniyor
                          ? 'Konum Alınıyor...'
                          : 'Mevcut Konumumu Kullan'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Baktığı Markalar:',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: kMotorMarkalari.map((marka) {
                        final secili = secilenMarkalar.contains(marka);
                        return FilterChip(
                          label: Text(marka,
                              style: const TextStyle(fontSize: 11.5)),
                          selected: secili,
                          selectedColor: kAcikKirmiziZemin,
                          checkmarkColor: kMarkaKirmizi,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                secilenMarkalar.add(marka);
                              } else {
                                secilenMarkalar.remove(marka);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: hizmetlerController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Verilen Hizmetler (Virgülle ayırın)',
                        hintText: 'Örn: Periyodik Bakım, Lastik Değişimi, Fren',
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: kMarkaKirmizi,
                      title: const Text('Dükkan Şu An Açık'),
                      value: dukkanAcik,
                      onChanged: (v) => setDialogState(() => dukkanAcik = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: Colors.green,
                      title: const Text('Onaylı ve Yayında (Aktif)'),
                      subtitle: const Text(
                        'Kapalıysa pasif olarak kaydedilir, motorculara görünmez',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: yayindaOnayli,
                      onChanged: (v) =>
                          setDialogState(() => yayindaOnayli = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: kMarkaKirmizi,
                      title: const Text('Sistem Destekli İndirim Aktif'),
                      value: sistemIndirim,
                      onChanged: (v) =>
                          setDialogState(() => sistemIndirim = v),
                    ),
                    if (sistemIndirim) ...[
                      const SizedBox(height: 6),
                      TextField(
                        controller: indirimTutarController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Sistem İndirim Tutarı (TL)'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: () async {
                  final dukkanAdi = dukkanController.text.trim();
                  final ustaAdi = ustaController.text.trim();
                  if (dukkanAdi.isEmpty || ustaAdi.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Dükkan adı ve usta adı zorunludur.')),
                    );
                    return;
                  }

                  final hizmetListesi = hizmetlerController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  final enlem = double.tryParse(
                      enlemController.text.trim().replaceAll(',', '.')) ??
                      41.0082;
                  final boylam = double.tryParse(
                      boylamController.text.trim().replaceAll(',', '.')) ??
                      28.9784;
                  final indirimTutar =
                      int.tryParse(indirimTutarController.text.trim()) ?? 200;

                  final veri = <String, dynamic>{
                    'dukkanAdi': dukkanAdi,
                    'ustaAdi': ustaAdi,
                    'ustalar': [ustaAdi],
                    'telefon': telController.text.trim(),
                    'il': ilController.text.trim(),
                    'ilce': ilceController.text.trim(),
                    'adres': adresController.text.trim(),
                    'calismaSaatleri': saatController.text.trim(),
                    'enlem': enlem,
                    'boylam': boylam,
                    'baktigiMarkalar': secilenMarkalar,
                    'verilenHizmetler': hizmetListesi,
                    'dukkanAcikMi': dukkanAcik,
                    'yoneticiOnayliMi': yayindaOnayli,
                    'onayDurumu': yayindaOnayli ? 'onaylandi' : 'pasif',
                    'sistemIndirimAktifMi': sistemIndirim,
                    'sistemIndirimTutari': indirimTutar,
                  };

                  if (duzenlemeModu) {
                    await FirebaseFirestore.instance
                        .collection('servisler')
                        .doc(servis.id)
                        .update(veri);
                  } else {
                    veri['banliMi'] = false;
                    veri['ortalamaPuan'] = 5.0;
                    veri['yorumSayisi'] = 0;
                    veri['begeniSayisi'] = 0;
                    veri['olusturmaTarihi'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance
                        .collection('servisler')
                        .add(veri);
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade700,
                      content: Text(duzenlemeModu
                          ? '$dukkanAdi bilgileri güncellendi.'
                          : '$dukkanAdi servisi eklendi.'),
                    ),
                  );
                },
                child: Text(duzenlemeModu ? 'Güncelle' : 'Servisi Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _servisiOnayla(String docId, String dukkanAdi) async {
    await FirebaseFirestore.instance.collection('servisler').doc(docId).update({
      'yoneticiOnayliMi': true,
      'onayDurumu': 'onaylandi',
      'redNedeni': FieldValue.delete(),
      'onayTarihi': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('$dukkanAdi onaylandı ve motorculara yayına açıldı.'),
      ),
    );
  }

  Future<void> _servisOnayiKaldirPasifEt(String docId, String dukkanAdi) async {
    await FirebaseFirestore.instance.collection('servisler').doc(docId).update({
      'yoneticiOnayliMi': false,
      'onayDurumu': 'pasif',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange.shade800,
        content: Text('$dukkanAdi onayı kaldırıldı (pasif duruma alındı).'),
      ),
    );
  }

  Future<void> _servisiReddet(String docId, String dukkanAdi) async {
    final sebepController = TextEditingController();

    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAnaBeyaz,
        title: Text('$dukkanAdi Başvurusunu Reddet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ustanın panelinde görünecek red sebebini yazabilirsiniz (isteğe bağlı):',
              style: TextStyle(fontSize: 13, color: kIkincilGri),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sebepController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Örn: Adres ve telefon bilgilerini eksiksiz girin.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kMarkaKirmizi,
              foregroundColor: kAnaBeyaz,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reddet'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    final sebep = sebepController.text.trim().isEmpty
        ? 'Bilgileriniz yönetici kriterlerine uygun bulunmadı. Düzenleyip tekrar onaya gönderebilirsiniz.'
        : sebepController.text.trim();

    await FirebaseFirestore.instance.collection('servisler').doc(docId).update({
      'yoneticiOnayliMi': false,
      'onayDurumu': 'reddedildi',
      'redNedeni': sebep,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kMarkaKirmizi,
        content: Text('$dukkanAdi başvurusu reddedildi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('servisler').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: kMarkaKirmizi));
        }

        final tumServisler = snapshot.data!.docs
            .map((d) => _ServisModeli.fromDoc(d))
            .toList();

        final bekleyenSayisi = tumServisler
            .where((s) => s.onayDurumu == 'onay_bekliyor')
            .length;
        final pasifSayisi =
            tumServisler.where((s) => s.onayDurumu == 'pasif').length;

        final filtrelenmis = tumServisler.where((s) {
          if (_seciliFiltre == 'tumu') return true;
          return s.onayDurumu == _seciliFiltre;
        }).toList();

        filtrelenmis.sort((a, b) {
          if (a.onayDurumu == 'onay_bekliyor' &&
              b.onayDurumu != 'onay_bekliyor') {
            return -1;
          }
          if (a.onayDurumu != 'onay_bekliyor' &&
              b.onayDurumu == 'onay_bekliyor') {
            return 1;
          }
          return 0;
        });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kKoyuAntrasit,
                        side: const BorderSide(color: kMarkaKirmizi),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _exceldenTopluYuklePenceresi,
                      icon: const Icon(Icons.paste_rounded, color: kMarkaKirmizi),
                      label: const Text(
                        'Excel\'den Toplu Yükle',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kMarkaKirmizi,
                        foregroundColor: kAnaBeyaz,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _servisEkleVeyaGuncellePenceresi(),
                      icon: const Icon(Icons.add_business),
                      label: const Text(
                        'Yeni Servis',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  _filtreCipi('tumu', 'Tümü (${tumServisler.length})'),
                  const SizedBox(width: 8),
                  _filtreCipi(
                      'onay_bekliyor', 'Onay Bekleyen ($bekleyenSayisi)'),
                  const SizedBox(width: 8),
                  _filtreCipi('onaylandi', 'Onaylı'),
                  const SizedBox(width: 8),
                  _filtreCipi('pasif', 'Pasif ($pasifSayisi)'),
                  const SizedBox(width: 8),
                  _filtreCipi('reddedildi', 'Reddedilen'),
                ],
              ),
            ),
            Expanded(
              child: filtrelenmis.isEmpty
                  ? const Center(
                child: Text(
                  'Bu filtrede servis kaydı bulunmuyor.',
                  style: TextStyle(color: kIkincilGri),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtrelenmis.length,
                itemBuilder: (context, index) {
                  final s = filtrelenmis[index];

                  Color rozetRenk = Colors.green;
                  String rozetMetin = 'Yayında (Onaylı)';
                  if (s.onayDurumu == 'onay_bekliyor') {
                    rozetRenk = Colors.orange.shade800;
                    rozetMetin = 'Onay Bekliyor';
                  } else if (s.onayDurumu == 'pasif') {
                    rozetRenk = Colors.grey.shade700;
                    rozetMetin = 'Pasif (Onay Kaldırıldı)';
                  } else if (s.onayDurumu == 'reddedildi') {
                    rozetRenk = kMarkaKirmizi;
                    rozetMetin = 'Reddedildi';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kAnaBeyaz,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: s.onayDurumu == 'onay_bekliyor'
                            ? kMarkaKirmizi
                            : kInceCizgiGri,
                        width: s.onayDurumu == 'onay_bekliyor' ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.dukkanAdi,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: rozetRenk.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                rozetMetin,
                                style: TextStyle(
                                  color: rozetRenk,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Usta: ${s.ustaAdi} • Tel: ${s.telefon}',
                          style: const TextStyle(
                              fontSize: 13, color: kKoyuAntrasit),
                        ),
                        if (s.adres.isNotEmpty)
                          Text(
                            'Adres: ${s.adres}',
                            style: const TextStyle(
                                fontSize: 12.5, color: kIkincilGri),
                          ),
                        if (s.baktigiMarkalar.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Markalar: ${s.baktigiMarkalar.join(", ")}',
                              style: const TextStyle(
                                  fontSize: 12, color: kIkincilGri),
                            ),
                          ),
                        if (s.onayDurumu == 'reddedildi' &&
                            s.redNedeni.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Red Sebebi: ${s.redNedeni}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMarkaKirmizi,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const Divider(height: 20, color: kInceCizgiGri),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (s.onayDurumu != 'onaylandi' ||
                                !s.yoneticiOnayliMi)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade700,
                                  foregroundColor: kAnaBeyaz,
                                  elevation: 0,
                                ),
                                onPressed: () =>
                                    _servisiOnayla(s.id, s.dukkanAdi),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Onayla'),
                              ),
                            if (s.onayDurumu == 'onaylandi' &&
                                s.yoneticiOnayliMi)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange.shade800,
                                  side: BorderSide(
                                      color: Colors.orange.shade700),
                                ),
                                onPressed: () =>
                                    _servisOnayiKaldirPasifEt(
                                        s.id, s.dukkanAdi),
                                icon: const Icon(
                                    Icons.pause_circle_outline,
                                    size: 18),
                                label:
                                const Text('Onayı Kaldır (Pasif)'),
                              ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kKoyuAntrasit,
                                side: const BorderSide(
                                    color: kInceCizgiGri),
                              ),
                              onPressed: () =>
                                  _servisEkleVeyaGuncellePenceresi(
                                      servis: s),
                              icon: const Icon(Icons.edit, size: 17),
                              label: const Text('Güncelle'),
                            ),
                            if (s.onayDurumu != 'reddedildi')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kMarkaKirmizi,
                                  side: const BorderSide(
                                      color: kMarkaKirmizi),
                                ),
                                onPressed: () =>
                                    _servisiReddet(s.id, s.dukkanAdi),
                                icon: const Icon(Icons.close, size: 18),
                                label: const Text('Reddet'),
                              ),
                            IconButton(
                              tooltip: 'Servisi Sil',
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('servisler')
                                    .doc(s.id)
                                    .delete();
                              },
                              icon: const Icon(Icons.delete_outline,
                                  color: kIkincilGri),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filtreCipi(String deger, String etiket) {
    final secili = _seciliFiltre == deger;
    return ChoiceChip(
      label: Text(etiket),
      selected: secili,
      backgroundColor: kAnaBeyaz,
      selectedColor: kAcikKirmiziZemin,
      side: BorderSide(color: secili ? kMarkaKirmizi : kInceCizgiGri),
      labelStyle: TextStyle(
        color: secili ? kMarkaKirmizi : kKoyuAntrasit,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) => setState(() => _seciliFiltre = deger),
    );
  }
}

class YoneticiGrupYonetimiSayfasi extends StatelessWidget {
  const YoneticiGrupYonetimiSayfasi({super.key});

  Future<void> _yoneticiUyeEklePenceresi(
      BuildContext context,
      String grupId,
      List<String> mevcutUyeler,
      List<_MotorcuKisi> tumMotorcular,
      ) async {
    final adaylar =
    tumMotorcular.where((k) => !mevcutUyeler.contains(k.uid)).toList();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAnaBeyaz,
        title: const Text('Gruba Kullanıcı Ekle (Yönetici)'),
        content: adaylar.isEmpty
            ? const Text('Eklenebilecek kullanıcı bulunamadı.')
            : SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: adaylar.length,
            itemBuilder: (context, i) {
              final k = adaylar[i];
              return ListTile(
                title: Text(k.adSoyad),
                subtitle: Text(k.motorBilgisi),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMarkaKirmizi,
                    foregroundColor: kAnaBeyaz,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('arkadas_gruplari')
                        .doc(grupId)
                        .update({
                      'uyeler': FieldValue.arrayUnion([k.uid]),
                      'katilmaIstekleri':
                      FieldValue.arrayRemove([k.uid]),
                      'banliUyeler': FieldValue.arrayRemove([k.uid]),
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Ekle'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('kullanicilar').snapshots(),
      builder: (context, kullaniciSnap) {
        final tumMotorcular = kullaniciSnap.hasData
            ? kullaniciSnap.data!.docs
            .map((d) => _MotorcuKisi.fromDoc(d))
            .toList()
            : <_MotorcuKisi>[];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('arkadas_gruplari')
              .snapshots(),
          builder: (context, grupSnap) {
            if (!grupSnap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: kMarkaKirmizi));
            }

            final gruplar = grupSnap.data!.docs;
            if (gruplar.isEmpty) {
              return const Center(
                child: Text(
                  'Sistemde henüz oluşturulmuş arkadaş grubu bulunmuyor.',
                  style: TextStyle(color: kIkincilGri),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: gruplar.length,
              itemBuilder: (context, index) {
                final doc = gruplar[index];
                final d = doc.data() as Map<String, dynamic>;
                final grupAdi = (d['grupAdi'] ?? 'İsimsiz Grup').toString();
                final kurucuUid = (d['kurucuUid'] ?? '').toString();
                final kurucuAdi = (d['kurucuAdi'] ?? 'Belirsiz').toString();
                final bool aktifMi = d['aktifMi'] != false;
                final uyeUidleri = List<String>.from(d['uyeler'] ?? []);
                final banliUidleri =
                List<String>.from(d['banliUyeler'] ?? []);

                final grupUyeleri = tumMotorcular
                    .where((k) => uyeUidleri.contains(k.uid))
                    .toList();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: kAnaBeyaz,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kInceCizgiGri),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      '$grupAdi ${aktifMi ? "" : "(KAPALI)"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kKoyuAntrasit,
                      ),
                    ),
                    subtitle: Text(
                      'Kurucu: $kurucuAdi • ${uyeUidleri.length} Üye • ${banliUidleri.length} Banlı',
                      style: const TextStyle(fontSize: 12, color: kIkincilGri),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kKoyuAntrasit,
                                foregroundColor: kAnaBeyaz,
                                elevation: 0,
                              ),
                              onPressed: () => _yoneticiUyeEklePenceresi(
                                context,
                                doc.id,
                                uyeUidleri,
                                tumMotorcular,
                              ),
                              icon: const Icon(Icons.person_add, size: 17),
                              label: const Text('Üye Ekle'),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: kMarkaKirmizi),
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('arkadas_gruplari')
                                    .doc(doc.id)
                                    .delete();
                              },
                              icon: const Icon(Icons.delete_forever, size: 18),
                              label: const Text('Grubu Sil'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: kInceCizgiGri),
                      ...grupUyeleri.map((uye) {
                        final bool buKurucu = uye.uid == kurucuUid;
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${uye.adSoyad} ${buKurucu ? "(Kurucu)" : ""}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(uye.motorBilgisi),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              if (!buKurucu)
                                TextButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('arkadas_gruplari')
                                        .doc(doc.id)
                                        .update({
                                      'kurucuUid': uye.uid,
                                      'kurucuAdi': uye.adSoyad,
                                    });
                                  },
                                  child: const Text('Yönetici Yap',
                                      style: TextStyle(fontSize: 11.5)),
                                ),
                              IconButton(
                                tooltip: 'Gruptan Çıkar',
                                icon: const Icon(Icons.person_remove,
                                    color: Colors.orange, size: 20),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('arkadas_gruplari')
                                      .doc(doc.id)
                                      .update({
                                    'uyeler':
                                    FieldValue.arrayRemove([uye.uid]),
                                  });
                                },
                              ),
                              IconButton(
                                tooltip: 'Gruptan Banla',
                                icon: const Icon(Icons.block,
                                    color: kMarkaKirmizi, size: 20),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('arkadas_gruplari')
                                      .doc(doc.id)
                                      .update({
                                    'uyeler':
                                    FieldValue.arrayRemove([uye.uid]),
                                    'banliUyeler':
                                    FieldValue.arrayUnion([uye.uid]),
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      if (banliUidleri.isNotEmpty) ...[
                        const Divider(color: kInceCizgiGri),
                        const Padding(
                          padding: EdgeInsets.only(left: 16, top: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Banlı Üyeler:',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: kMarkaKirmizi),
                            ),
                          ),
                        ),
                        ...banliUidleri.map((bUid) {
                          final banliKisi = tumMotorcular.firstWhere(
                                (k) => k.uid == bUid,
                            orElse: () => _MotorcuKisi(
                              uid: bUid,
                              adSoyad: 'Banlı Kullanıcı',
                              email: '',
                              telefon: '',
                              motorMarka: '',
                              motorModel: '',
                              yoneticiMi: false,
                              banliMi: false,
                            ),
                          );
                          return ListTile(
                            dense: true,
                            title: Text(banliKisi.adSoyad),
                            trailing: TextButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('arkadas_gruplari')
                                    .doc(doc.id)
                                    .update({
                                  'banliUyeler':
                                  FieldValue.arrayRemove([bUid]),
                                  'uyeler': FieldValue.arrayUnion([bUid]),
                                });
                              },
                              child: const Text('Banı Kaldır'),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class YoneticiMotorcularListesi extends StatefulWidget {
  const YoneticiMotorcularListesi({super.key});

  @override
  State<YoneticiMotorcularListesi> createState() =>
      _YoneticiMotorcularListesiState();
}

class _YoneticiMotorcularListesiState
    extends State<YoneticiMotorcularListesi> {
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = '';

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _kullaniciBilgiGuncellePenceresi(
      _MotorcuKisi kisi, bool kendisiMi) async {
    final adController = TextEditingController(text: kisi.adSoyad);
    final telController = TextEditingController(text: kisi.telefon);
    final emailController = TextEditingController(text: kisi.email);
    final modelController = TextEditingController(text: kisi.motorModel);
    String secilenMarka = kMotorMarkalari.contains(kisi.motorMarka)
        ? kisi.motorMarka
        : kMotorMarkalari.first;
    bool yoneticiMi = kisi.yoneticiMi;
    bool banliMi = kisi.banliMi;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kAnaBeyaz,
            title: Text('Kullanıcıyı Güncelle: ${kisi.adSoyad}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: adController,
                    decoration: const InputDecoration(labelText: 'Ad Soyad'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: telController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: secilenMarka,
                    decoration:
                    const InputDecoration(labelText: 'Motosiklet Markası'),
                    items: kMotorMarkalari
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => secilenMarka = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: modelController,
                    decoration:
                    const InputDecoration(labelText: 'Motosiklet Modeli'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: kMarkaKirmizi,
                    title: const Text('Yönetici Yetkisi'),
                    subtitle: kendisiMi
                        ? const Text('Kendi yöneticiliğinizi kapatamazsınız')
                        : null,
                    value: yoneticiMi,
                    onChanged: kendisiMi
                        ? null
                        : (v) => setDialogState(() => yoneticiMi = v),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: kMarkaKirmizi,
                    title: const Text('Hesap Banlı'),
                    value: banliMi,
                    onChanged: kendisiMi
                        ? null
                        : (v) => setDialogState(() => banliMi = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMarkaKirmizi,
                  foregroundColor: kAnaBeyaz,
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('kullanicilar')
                      .doc(kisi.uid)
                      .set({
                    'adSoyad': adController.text.trim(),
                    'email': emailController.text.trim(),
                    'telefon': telController.text.trim(),
                    'motorMarka': secilenMarka,
                    'motorModel': modelController.text.trim(),
                    'yoneticiMi': yoneticiMi,
                    'rol': yoneticiMi ? 'yonetici' : 'motorcu',
                    'banliMi': banliMi,
                  }, SetOptions(merge: true));

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  if (!mounted) return;
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade700,
                      content: Text('${adController.text.trim()} güncellendi.'),
                    ),
                  );
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _yoneticilikDegistir(_MotorcuKisi kisi) async {
    final yeniDurum = !kisi.yoneticiMi;
    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(kisi.uid)
        .update({
      'yoneticiMi': yeniDurum,
      'rol': yeniDurum ? 'yonetici' : 'motorcu',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: yeniDurum ? Colors.green.shade700 : kKoyuAntrasit,
        content: Text(yeniDurum
            ? '${kisi.adSoyad} artık Yönetici yetkisine sahip.'
            : '${kisi.adSoyad} yöneticilik yetkisi geri alındı.'),
      ),
    );
  }

  Future<void> _direktArkadasEkle(
      String benimUid, String hedefUid, String hedefAdi) async {
    final db = FirebaseFirestore.instance;
    await db.collection('kullanicilar').doc(benimUid).set({
      'arkadaslar': FieldValue.arrayUnion([hedefUid]),
      'gelenIstekler': FieldValue.arrayRemove([hedefUid]),
      'gonderilenIstekler': FieldValue.arrayRemove([hedefUid]),
    }, SetOptions(merge: true));

    await db.collection('kullanicilar').doc(hedefUid).set({
      'arkadaslar': FieldValue.arrayUnion([benimUid]),
      'gelenIstekler': FieldValue.arrayRemove([benimUid]),
      'gonderilenIstekler': FieldValue.arrayRemove([benimUid]),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('$hedefAdi doğrudan arkadaş olarak eklendi.'),
      ),
    );
  }

  Future<void> _kullaniciSil(_MotorcuKisi kisi) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kAnaBeyaz,
        title: const Text('Kullanıcıyı Sil'),
        content: Text(
          '${kisi.adSoyad} adlı kullanıcıyı sistemden kalıcı olarak silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kMarkaKirmizi,
              foregroundColor: kAnaBeyaz,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true) return;

    await FirebaseFirestore.instance
        .collection('kullanicilar')
        .doc(kisi.uid)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kMarkaKirmizi,
        content: Text('${kisi.adSoyad} silindi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final benimUid = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: TextField(
            controller: _aramaController,
            onChanged: (v) => setState(() => _aramaMetni = v.trim()),
            decoration: InputDecoration(
              hintText: 'Kullanıcı adı, e-posta veya motor ara...',
              prefixIcon: const Icon(Icons.search, color: kMarkaKirmizi),
              suffixIcon: _aramaMetni.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _aramaController.clear();
                  setState(() => _aramaMetni = '');
                },
              )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('kullanicilar')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: kMarkaKirmizi));
              }

              final tumKisiler = snapshot.data!.docs
                  .map((d) => _MotorcuKisi.fromDoc(d))
                  .toList();

              List<String> benimArkadaslarim = [];
              if (benimUid != null) {
                for (final doc in snapshot.data!.docs) {
                  if (doc.id == benimUid) {
                    final d = (doc.data() as Map<String, dynamic>?) ?? {};
                    benimArkadaslarim =
                    List<String>.from(d['arkadaslar'] ?? []);
                    break;
                  }
                }
              }

              final filtrelenmis = tumKisiler.where((k) {
                if (_aramaMetni.isEmpty) return true;
                final q = _trKucuk(_aramaMetni);
                return _trKucuk(k.adSoyad).contains(q) ||
                    _trKucuk(k.email).contains(q) ||
                    _trKucuk(k.motorBilgisi).contains(q);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: filtrelenmis.length,
                itemBuilder: (context, index) {
                  final k = filtrelenmis[index];
                  final bool kendisiMi = k.uid == benimUid;
                  final bool arkadasMi = benimArkadaslarim.contains(k.uid);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: kAnaBeyaz,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: k.yoneticiMi
                            ? kMarkaKirmizi.withValues(alpha: 0.45)
                            : kInceCizgiGri,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${k.adSoyad} ${kendisiMi ? "(Sen)" : ""}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                            ),
                            if (k.yoneticiMi)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kAcikKirmiziZemin,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Yönetici',
                                  style: TextStyle(
                                    color: kMarkaKirmizi,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            if (k.banliMi)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Banlı',
                                  style: TextStyle(
                                    color: kKoyuKirmizi,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${k.email}${k.telefon.isNotEmpty ? " • ${k.telefon}" : ""}',
                          style: const TextStyle(
                              fontSize: 12.5, color: kIkincilGri),
                        ),
                        if (k.motorBilgisi.isNotEmpty)
                          Text(
                            '🏍️ ${k.motorBilgisi}',
                            style: const TextStyle(
                                fontSize: 12.5, color: kKoyuAntrasit),
                          ),
                        const Divider(height: 18, color: kInceCizgiGri),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // 1. BİLGİLERİ GÜNCELLE
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kKoyuAntrasit,
                                side: const BorderSide(color: kInceCizgiGri),
                              ),
                              onPressed: () => _kullaniciBilgiGuncellePenceresi(
                                  k, kendisiMi),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Güncelle',
                                  style: TextStyle(fontSize: 12)),
                            ),

                            // 2. YÖNETİCİLİK VER / AL
                            if (!kendisiMi)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: k.yoneticiMi
                                      ? Colors.orange.shade800
                                      : Colors.blue.shade800,
                                  side: BorderSide(
                                    color: k.yoneticiMi
                                        ? Colors.orange.shade400
                                        : Colors.blue.shade400,
                                  ),
                                ),
                                onPressed: () => _yoneticilikDegistir(k),
                                icon: Icon(
                                  k.yoneticiMi
                                      ? Icons.remove_moderator
                                      : Icons.add_moderator,
                                  size: 16,
                                ),
                                label: Text(
                                  k.yoneticiMi
                                      ? 'Yöneticiliği Al'
                                      : 'Yönetici Yap',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),

                            // 3. İSTEKSİZ DİREKT ARKADAŞ EKLE
                            if (!kendisiMi && benimUid != null)
                              arkadasMi
                                  ? OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green.shade700,
                                  side: BorderSide(
                                      color: Colors.green.shade300),
                                ),
                                onPressed: null,
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Arkadaşsınız',
                                    style: TextStyle(fontSize: 12)),
                              )
                                  : ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kKoyuAntrasit,
                                  foregroundColor: kAnaBeyaz,
                                  elevation: 0,
                                ),
                                onPressed: () => _direktArkadasEkle(
                                    benimUid, k.uid, k.adSoyad),
                                icon: const Icon(Icons.person_add,
                                    size: 16),
                                label: const Text('Direkt Arkadaş Ekle',
                                    style: TextStyle(fontSize: 12)),
                              ),

                            // 4. BANLA / BANI KALDIR
                            if (!kendisiMi)
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                  k.banliMi ? Colors.green : kMarkaKirmizi,
                                  side: BorderSide(
                                    color: k.banliMi
                                        ? Colors.green
                                        : kMarkaKirmizi,
                                  ),
                                ),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('kullanicilar')
                                      .doc(k.uid)
                                      .update({'banliMi': !k.banliMi});
                                },
                                icon: Icon(
                                    k.banliMi ? Icons.lock_open : Icons.block,
                                    size: 16),
                                label: Text(
                                  k.banliMi ? 'Banı Kaldır' : 'Banla',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),

                            // 5. KULLANICIYI SİL
                            if (!kendisiMi)
                              IconButton(
                                tooltip: 'Kullanıcıyı Sil',
                                onPressed: () => _kullaniciSil(k),
                                icon: const Icon(Icons.delete_outline,
                                    color: kMarkaKirmizi),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class YoneticiYorumlarListesi extends StatefulWidget {
  const YoneticiYorumlarListesi({super.key});

  @override
  State<YoneticiYorumlarListesi> createState() =>
      _YoneticiYorumlarListesiState();
}

class _YoneticiYorumlarListesiState extends State<YoneticiYorumlarListesi> {
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = '';

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _aramaController,
            onChanged: (val) => setState(() => _aramaMetni = val.trim()),
            decoration: InputDecoration(
              hintText: 'Servis adı, yorum yapan veya yorum metni ara...',
              prefixIcon: const Icon(Icons.search, color: kMarkaKirmizi),
              suffixIcon: _aramaMetni.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear, color: kIkincilGri),
                onPressed: () {
                  _aramaController.clear();
                  setState(() => _aramaMetni = '');
                },
              )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('yorumlar')
                .orderBy('tarih', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: kMarkaKirmizi));
              }

              final docs = snapshot.data!.docs;
              final aranan = _trKucuk(_aramaMetni);

              final filtrelenmis = docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                if (_aramaMetni.isEmpty) return true;
                final servisAdi = (d['servisAdi'] ?? '').toString();
                final kullaniciAdi = (d['kullaniciAdi'] ?? '').toString();
                final yorumMetni = (d['yorumMetni'] ?? '').toString();
                return _trKucuk(servisAdi).contains(aranan) ||
                    _trKucuk(kullaniciAdi).contains(aranan) ||
                    _trKucuk(yorumMetni).contains(aranan);
              }).toList();

              if (filtrelenmis.isEmpty) {
                return const Center(
                  child: Text(
                    'Yorum bulunamadı.',
                    style: TextStyle(color: kIkincilGri),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtrelenmis.length,
                itemBuilder: (context, index) {
                  final doc = filtrelenmis[index];
                  final d = doc.data() as Map<String, dynamic>;
                  final servisId = (d['servisId'] ?? '').toString();
                  final bool gizliMi = d['gizliMi'] == true;
                  final int puan = (d['puan'] ?? 5).toInt();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kAnaBeyaz,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: gizliMi ? kMarkaKirmizi : kInceCizgiGri,
                        width: gizliMi ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                d['servisAdi'] ?? 'Servis',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: kKoyuAntrasit,
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                    (i) => Icon(
                                  i < puan ? Icons.star : Icons.star_border,
                                  size: 16,
                                  color: kMarkaKirmizi,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Yazan: ${d['kullaniciAdi'] ?? 'Motorcu'}',
                          style: const TextStyle(
                              fontSize: 12, color: kIkincilGri),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          d['yorumMetni'] ?? '',
                          style: const TextStyle(
                              fontSize: 13.5, color: kKoyuAntrasit),
                        ),
                        const Divider(height: 16, color: kInceCizgiGri),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await doc.reference
                                    .update({'gizliMi': !gizliMi});
                                await _servisPuaniniYenidenHesapla(servisId);
                              },
                              icon: Icon(
                                gizliMi
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                size: 18,
                                color: gizliMi ? Colors.green : kIkincilGri,
                              ),
                              label: Text(
                                gizliMi ? 'Yorumu Göster' : 'Yorumu Gizle',
                                style: TextStyle(
                                  color: gizliMi ? Colors.green : kIkincilGri,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Yorumu Sil',
                              icon: const Icon(Icons.delete_outline,
                                  color: kMarkaKirmizi, size: 20),
                              onPressed: () async {
                                await doc.reference.delete();
                                await _servisPuaniniYenidenHesapla(servisId);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// YÖNETİCİ - İSTATİSTİKLER SAYFASI
// ============================================================================
class YoneticiIstatistikSayfasi extends StatelessWidget {
  const YoneticiIstatistikSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('kullanicilar').snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('servisler').snapshots(),
          builder: (context, servisSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tamir_kayitlari').snapshots(),
              builder: (context, tamirSnap) {

                final int toplamKullanici = userSnap.hasData ? userSnap.data!.docs.length : 0;
                final int toplamServis = servisSnap.hasData ? servisSnap.data!.docs.length : 0;
                final int toplamTamir = tamirSnap.hasData ? tamirSnap.data!.docs.length : 0;

                int onlineKullanici = 0;
                if(userSnap.hasData){
                  final simdi = DateTime.now();
                  for(final doc in userSnap.data!.docs){
                    final veri = doc.data() as Map<String, dynamic>;
                    if (veri['sonGirisTarihi'] != null) {
                      final sonGiris = (veri['sonGirisTarihi'] as Timestamp).toDate();
                      if (simdi.difference(sonGiris).inMinutes < 15) {
                        onlineKullanici++;
                      }
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Genel Durum',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: kKoyuAntrasit,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _istatistikKarti(
                              baslik: 'Kayıtlı\nKullanıcı',
                              deger: '$toplamKullanici',
                              ikon: Icons.group,
                              renk: Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _istatistikKarti(
                              baslik: 'Aktif / Çevrimiçi\nKullanıcı (Son 15 Dk)',
                              deger: '$onlineKullanici',
                              ikon: Icons.online_prediction,
                              renk: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _istatistikKarti(
                              baslik: 'Toplam\nKayıtlı Servis',
                              deger: '$toplamServis',
                              ikon: Icons.store,
                              renk: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _istatistikKarti(
                              baslik: 'Gerçekleşen\nTamir İşlemi',
                              deger: '$toplamTamir',
                              ikon: Icons.handyman,
                              renk: kMarkaKirmizi,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _istatistikKarti({
    required String baslik,
    required String deger,
    required IconData ikon,
    required Color renk,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAnaBeyaz,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kInceCizgiGri),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(ikon, color: renk, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            deger,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: renk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: kIkincilGri,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}