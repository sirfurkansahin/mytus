import 'package:app/core/renkler.dart';
import 'package:app/features/auth/kimlik_servisi.dart';
import 'package:app/features/auth/kvkk_dialogu.dart';
import 'package:flutter/material.dart';

/// İlk açılışta (oturum yokken) gösterilen Giriş Yap / Kayıt Ol / Şifremi Unuttum ekranı.
class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key, this.kimlikServisi});

  final KimlikServisi? kimlikServisi;

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  final _epostaDenetci = TextEditingController();
  final _sifreDenetci = TextEditingController();
  final _takmaAdDenetci = TextEditingController();

  bool _kayitModu = false;
  bool _kvkkOnay = false;
  bool _sifreGizli = true;
  bool _islemSuruyor = false;
  String? _hataMesaji;

  @override
  void dispose() {
    _epostaDenetci.dispose();
    _sifreDenetci.dispose();
    _takmaAdDenetci.dispose();
    super.dispose();
  }

  KimlikServisi _servis(BuildContext context) {
    return widget.kimlikServisi ?? KimlikKapsami.of(context);
  }

  void _modDegistir(bool kayitMi) {
    if (_kayitModu == kayitMi || _islemSuruyor) return;
    setState(() {
      _kayitModu = kayitMi;
      _hataMesaji = null;
    });
  }

  Future<void> _gonder() async {
    final eposta = _epostaDenetci.text.trim();
    final sifre = _sifreDenetci.text;
    final takmaAd = _takmaAdDenetci.text.trim();

    if (eposta.isEmpty || !eposta.contains('@')) {
      setState(() => _hataMesaji = 'Lütfen geçerli bir e-posta adresi girin.');
      return;
    }
    if (sifre.length < 6) {
      setState(() => _hataMesaji = 'Şifre en az 6 karakter olmalıdır.');
      return;
    }
    if (_kayitModu && !_kvkkOnay) {
      setState(
        () => _hataMesaji =
            'Kayıt olmak için KVKK aydınlatma metnini onaylamalısın.',
      );
      return;
    }

    setState(() {
      _islemSuruyor = true;
      _hataMesaji = null;
    });

    try {
      final servis = _servis(context);
      if (_kayitModu) {
        await servis.kayitOl(
          eposta: eposta,
          sifre: sifre,
          takmaAd: takmaAd.isEmpty ? null : takmaAd,
        );
      } else {
        await servis.girisYap(eposta: eposta, sifre: sifre);
      }
    } on KimlikHatasi catch (e) {
      if (!mounted) return;
      setState(() => _hataMesaji = e.mesaj);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _hataMesaji = 'Bağlantı kurulamadı. Lütfen tekrar deneyin.',
      );
    } finally {
      if (mounted) {
        setState(() => _islemSuruyor = false);
      }
    }
  }

  Future<void> _sifreSifirlaDialogu() async {
    final denetci = TextEditingController(text: _epostaDenetci.text.trim());
    final eposta = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifremi Unuttum'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kayıtlı e-posta adresini gir. Şifre sıfırlama bağlantısını göndereceğiz.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: denetci,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta adresi',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(denetci.text.trim()),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
    denetci.dispose();
    if (eposta == null || eposta.isEmpty || !mounted) return;

    try {
      await _servis(context).sifreSifirlamaGonder(eposta: eposta);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '$eposta adresine şifre sıfırlama bağlantısı gönderildi.',
            ),
          ),
        );
    } on KimlikHatasi catch (e) {
      if (!mounted) return;
      setState(() => _hataMesaji = e.mesaj);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final soluk = tema.colorScheme.onSurfaceVariant;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: morAna,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'MY TUS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _kayitModu ? 'Yeni Hesap Oluştur' : 'Hesabına Giriş Yap',
                    style: tema.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Çalışma planın, derslerin ve deneme analizlerin bulutta güvenle saklanır ve tüm cihazlarında eşitlenir.',
                    style: tema.textTheme.bodyMedium?.copyWith(color: soluk),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Giriş Yap'),
                        icon: Icon(Icons.login_rounded),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Kayıt Ol'),
                        icon: Icon(Icons.person_add_alt_1_rounded),
                      ),
                    ],
                    selected: {_kayitModu},
                    onSelectionChanged: (secim) => _modDegistir(secim.first),
                  ),
                  const SizedBox(height: 20),
                  if (_kayitModu) ...[
                    TextField(
                      key: const ValueKey('giris_takma_ad'),
                      controller: _takmaAdDenetci,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Adın veya Takma Adın (isteğe bağlı)',
                        hintText: 'Örn. Dr. Furkan',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextField(
                    key: const ValueKey('giris_eposta'),
                    controller: _epostaDenetci,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'E-posta adresi',
                      hintText: 'ornek@eposta.com',
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const ValueKey('giris_sifre'),
                    controller: _sifreDenetci,
                    obscureText: _sifreGizli,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _gonder(),
                    decoration: InputDecoration(
                      labelText: 'Şifre (en az 6 karakter)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _sifreGizli ? 'Şifreyi göster' : 'Şifreyi gizle',
                        onPressed: () =>
                            setState(() => _sifreGizli = !_sifreGizli),
                        icon: Icon(
                          _sifreGizli
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  if (!_kayitModu) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _islemSuruyor ? null : _sifreSifirlaDialogu,
                        child: const Text('Şifremi unuttum'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      key: const ValueKey('giris_kvkk_onay'),
                      value: _kvkkOnay,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) => setState(() => _kvkkOnay = v ?? false),
                      title: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('KVKK Aydınlatma Metni\'ni okudum, '),
                          InkWell(
                            onTap: () => kvkkAydinlatmaDialoguGoster(context),
                            child: Text(
                              'incele ve onayla',
                              style: TextStyle(
                                color: tema.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_hataMesaji != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _hataMesaji!,
                        style: TextStyle(
                          color: tema.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    key: const ValueKey('giris_onay_butonu'),
                    onPressed: _islemSuruyor ? null : _gonder,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _islemSuruyor
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(_kayitModu ? 'Hesap Oluştur ve Başla' : 'Giriş Yap'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Oturumun bu cihazda açık kalır, her girişte şifre sorulmaz.',
                          style: tema.textTheme.bodySmall?.copyWith(color: soluk),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
