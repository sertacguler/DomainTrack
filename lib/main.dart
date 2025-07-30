import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher package
import 'package:flutter/services.dart'; // Import for clipboard functionality
import 'service.dart'; // Importing the service.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Domain Sorgulama Uygulaması', // Uygulama başlığı güncellendi
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const EmailListScreen(),
    );
  }
}

class EmailListScreen extends StatefulWidget {
  const EmailListScreen({super.key});

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  final TextEditingController _domainController = TextEditingController();

  // List to hold data from the backend
  List<Map<String, dynamic>> _backendData = [];

  bool _isLoading = false;

  // --- Yeni Filtreleme Alanı Değişkenleri ---
  List<String> _allExtensions = [];
  List<String> _selectedExtensions = []; // Seçili uzantılar listesi

  @override
  void initState() {
    super.initState();
    _fetchExtensions();
  }

  @override
  void dispose() {
    _domainController.dispose(); // Controller güncellendi
    super.dispose();
  }

  Future<void> _fetchExtensions() async {
    final fetchedExtensions = await getExtensions();
    setState(() {
      _selectedExtensions = fetchedExtensions;
      _allExtensions = fetchedExtensions;
    });
  }

  Future<void> _fetchDataFromBackend(String domain) async {
    setState(() {
      _isLoading = true; // Start loading
      _backendData = []; // Clear list for new search
    });

    try {
      // Varsayım: getSearchByEmailOrUsernameService fonksiyonu filtreleri de alabilir.
      // Şu an için sadece domain gönderiyoruz, ancak API'nizi uzantı filtrelerini alacak şekilde güncellemeyi düşünebilirsiniz.
      // Örneğin: final data = await getSearchByEmailOrUsernameService(domain, selectedExtensions: _selectedExtensions);
      final data = await getSearchByEmailOrUsernameService(
        domain,
        _selectedExtensions,
      );
      setState(() {
        _backendData = data; // Assign incoming data to state
      });
    } catch (e) {
      // Error handling: Show an error message to the user
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Veri getirilirken bir hata oluştu: ${e.toString()}', // Hata mesajı Türkçe
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Loading finished
      });
    }
  }

  // --- Bilgi Dialog Fonksiyonu ---
  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Bilgi'), // Başlık Türkçe
          content: const Text(
            'Bu uygulama, girdiğiniz domain adresinin boşta olup olmadığını veya hangi firma tarafından kaydedildiğini sorgular. Domain sorgulama işlemleri halka açık WHOIS veritabanları üzerinden yapılır. Verilerin güncelliği ve doğruluğu WHOIS sunucularına bağlıdır.', // İçerik güncellendi
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'), // Buton Türkçe
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  // --- Uzantı Filtreleme Dialog Fonksiyonu ---
  void _showExtensionFilterDialog(BuildContext context) {
    // Dialog içinde seçilenleri geçici olarak tutmak için kopya oluştur
    final List<String> tempSelectedExtensions = List.from(_selectedExtensions);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // Dialog içindeki state'i güncellemek için StatefulBuilder kullanıyoruz
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Uzantıları Filtrele'),
              content: SizedBox(
                width: double.maxFinite, // Dialogun genişliğini artır
                child: Column(
                  mainAxisSize: MainAxisSize.min, // İçeriğe göre boyutlan
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setStateInDialog(() {
                              tempSelectedExtensions
                                  .clear(); // Seçimleri temizle
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Temizle'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setStateInDialog(() {
                              tempSelectedExtensions.clear();
                              tempSelectedExtensions.addAll(
                                _allExtensions,
                              ); // Tümünü seç
                            });
                          },
                          icon: const Icon(Icons.select_all),
                          label: const Text('Tümünü Seç'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      // Checkbox listesinin kaydırılabilir olması için Expanded
                      child: GridView.builder(
                        shrinkWrap: true, // İçeriğine göre boyutlan
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Yan yana 3 sütun
                              childAspectRatio: 3.5, // Öğelerin en-boy oranı
                            ),
                        itemCount: _allExtensions.length,
                        itemBuilder: (context, index) {
                          final extension = _allExtensions[index];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: tempSelectedExtensions.contains(
                                  extension,
                                ),
                                onChanged: (bool? isChecked) {
                                  setStateInDialog(() {
                                    if (isChecked == true) {
                                      tempSelectedExtensions.add(extension);
                                    } else {
                                      tempSelectedExtensions.remove(extension);
                                    }
                                  });
                                },
                              ),
                              Flexible(
                                // Uzun metinler için esneklik
                                child: Text(
                                  extension,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Tamam'),
                  onPressed: () {
                    setState(() {
                      // Ana widget'ın state'ini güncelle
                      _selectedExtensions = List.from(tempSelectedExtensions);
                    });
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Tarihleri daha okunaklı hale getiren yardımcı fonksiyon
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'Yok';
    }
    try {
      // Gelen tarih formatı "2024-03-30 18:03:52" veya "[datetime.datetime(2025, 3, 31, 7, 32, 43), ...]" olabilir.
      // İlk duruma göre parse etmeye çalışalım.
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      // Eğer doğrudan parse edilemezse, "[datetime.datetime(...)]" formatını kontrol et
      if (dateTimeString.startsWith('[datetime.datetime(') &&
          dateTimeString.endsWith(')]')) {
        // Regex ile tarihi ayıklama
        final RegExp regExp = RegExp(
          r'datetime\.datetime\((\d{4}), (\d{1,2}), (\d{1,2}), (\d{1,2}), (\d{1,2}), (\d{1,2})',
        );
        final Match? match = regExp.firstMatch(dateTimeString);
        if (match != null && match.groupCount >= 6) {
          try {
            final int year = int.parse(match.group(1)!);
            final int month = int.parse(match.group(2)!);
            final int day = int.parse(match.group(3)!);
            final int hour = int.parse(match.group(4)!);
            final int minute = int.parse(match.group(5)!);
            final int second = int.parse(match.group(6)!);
            final DateTime dateTime = DateTime(
              year,
              month,
              day,
              hour,
              minute,
              second,
            );
            return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
          } catch (_) {
            return 'Geçersiz Tarih Formatı';
          }
        }
      }
      return 'Geçersiz Tarih Formatı'; // Her iki format da uymazsa
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domain Track', // Başlık güncel
                  style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.grey[400],
              radius: 14,
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            onPressed: () {
              _showInfoDialog(context); // Bilgi dialogunu göster
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Domain input field and search button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _domainController, // Controller güncellendi
                    decoration: InputDecoration(
                      labelText:
                          'Domain Adresi Girin', // Etiket Türkçe ve güncellendi
                      hintText: '', // Örnek metin güncellendi
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(
                        Icons.language,
                      ), // İkon domain için uygun
                    ),
                    keyboardType:
                        TextInputType.url, // Klavye tipi URL için uygun
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            // Perform search if domain field is not empty
                            if (_domainController.text.trim().isNotEmpty) {
                              _fetchDataFromBackend(
                                _domainController.text.trim(),
                              );
                            } else {
                              // Inform user if domain is empty
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Lütfen bir domain adresi girin.', // Mesaj Türkçe
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  icon: const Icon(Icons.search),
                  label: const Text('Sorgula'), // Buton metni Türkçe
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 20.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ), // Arama alanı ile filtre alanı arasına boşluk
            // --- Yeni Filtreleme Alanı ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    height: 40, // Sabit bir yükseklik verelim
                    child:
                        _selectedExtensions.isEmpty
                            ? const Center(
                              child: Text(
                                'Filtre uygulanmadı (Tüm uzantılar)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection:
                                  Axis.horizontal, // Yatay kaydırılabilir
                              itemCount: _selectedExtensions.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _selectedExtensions[index] +
                                          (index ==
                                                  _selectedExtensions.length - 1
                                              ? ''
                                              : ' |'), // Pipe ekle
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _showExtensionFilterDialog(
                      context,
                    ); // Filtre dialogunu göster
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filtrele'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 20.0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Loading indicator or results list
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _backendData.isEmpty
                ? const Center(
                  child: Text(
                    'Henüz bir domain sorgulanmadı veya sonuç bulunamadı. Lütfen bir domain adresi girip sorgulayın.', // Mesaj Türkçe ve güncel
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                : Expanded(
                  child: ListView.builder(
                    itemCount: _backendData.length,
                    itemBuilder: (context, index) {
                      final item = _backendData[index];
                      final String domain =
                          item['Domain'] ?? 'Bilinmeyen Domain';
                      final String status = item['Status'] ?? 'Bilinmiyor';

                      // Duruma göre renk seçimi
                      Color statusColor;
                      if (status.contains('Available')) {
                        statusColor = Colors.green;
                      } else if (status.contains('Registered')) {
                        statusColor = Colors.red;
                      } else {
                        statusColor = Colors.blue; // Varsayılan renk
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(
                            domain,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Durum: $status',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onTap: () {
                            // Sadece 'Registered' durumundaysa detayları göster
                            if (status.contains('Registered')) {
                              final String registrar =
                                  item['Registrar'] ?? 'Bilinmiyor';
                              final String creationDate = _formatDateTime(
                                item['CreationDate'],
                              );
                              final String expirationDate = _formatDateTime(
                                item['ExpirationDate'],
                              );
                              final String updatedDate = _formatDateTime(
                                item['UpdatedDate'],
                              );

                              showDialog<void>(
                                context: context,
                                builder: (BuildContext dialogContext) {
                                  return AlertDialog(
                                    title: const Text('Domain Detayları'),
                                    content: SingleChildScrollView(
                                      child: RichText(
                                        text: TextSpan(
                                          style: DefaultTextStyle.of(
                                            context,
                                          ).style.copyWith(fontSize: 16),
                                          children: <TextSpan>[
                                            const TextSpan(
                                              text: 'Domain: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$domain\n'),
                                            const TextSpan(
                                              text: 'Durum: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '$status\n\n',
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: 'Kayıtçı: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$registrar\n'),
                                            const TextSpan(
                                              text: 'Oluşturulma Tarihi: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$creationDate\n'),
                                            const TextSpan(
                                              text: 'Bitiş Tarihi: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$expirationDate\n'),
                                            const TextSpan(
                                              text: 'Güncellenme Tarihi: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$updatedDate\n'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Tamam'),
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
