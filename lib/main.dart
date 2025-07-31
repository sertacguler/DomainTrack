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
      title: 'Domain Query Application', // Application title updated
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

  List<String> _allExtensions = [];
  List<String> _selectedExtensions = [];

  @override
  void initState() {
    super.initState();
    _fetchExtensions();
  }

  @override
  void dispose() {
    _domainController.dispose();
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
            'An error occurred while fetching data: ${e.toString()}', // Error message in English
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

  // --- Info Dialog Function ---
  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Information'), // Title in English
          content: const Text(
            'This application queries whether the domain address you entered is available or which company registered it. Domain query operations are performed via public WHOIS databases. The currency and accuracy of the data depend on the WHOIS servers.', // Content updated
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'), // Button in English
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  // --- Extension Filter Dialog Function ---
  void _showExtensionFilterDialog(BuildContext context) {
    // Create a copy to temporarily hold selections within the dialog
    final List<String> tempSelectedExtensions = List.from(_selectedExtensions);

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          // We use StatefulBuilder to update the state within the dialog
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Filter Extensions'),
              content: SizedBox(
                width: double.maxFinite, // Increase dialog width
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Size according to content
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setStateInDialog(() {
                              tempSelectedExtensions
                                  .clear(); // Clear selections
                            });
                          },
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setStateInDialog(() {
                              tempSelectedExtensions.clear();
                              tempSelectedExtensions.addAll(
                                _allExtensions,
                              ); // Select All
                            });
                          },
                          icon: const Icon(Icons.select_all),
                          label: const Text('Select All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      // Expanded for scrollable Checkbox list
                      child: GridView.builder(
                        shrinkWrap: true, // Size according to content
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 3 columns side by side
                              childAspectRatio: 3.5, // Aspect ratio of items
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
                                // Flexibility for long texts
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
                  child: const Text('OK'),
                  onPressed: () {
                    setState(() {
                      // Update the main widget's state
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

  // Helper function to format dates for better readability
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'N/A';
    }
    try {
      final DateTime dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      if (dateTimeString.startsWith('[datetime.datetime(') &&
          dateTimeString.endsWith(')]')) {
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
            return 'Invalid Date Format';
          }
        }
      }
      return 'Invalid Date Format';
    }
  }

  // Helper function to format emails, placing each on a new line
  String _formatEmails(dynamic emailData) {
    if (emailData == null) {
      return 'N/A';
    } else if (emailData is List) {
      // If it's already a list of emails
      return emailData.join('\n');
    } else if (emailData is String) {
      // If it's a single string, try splitting by common delimiters like comma or semicolon
      if (emailData.contains(',')) {
        return emailData.split(',').map((e) => e.trim()).join('\n');
      } else if (emailData.contains(';')) {
        return emailData.split(';').map((e) => e.trim()).join('\n');
      } else {
        return emailData.trim(); // Just return the single email
      }
    }
    return 'N/A'; // Fallback for unexpected types
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
                  'Domain Track', // Title updated
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
              _showInfoDialog(context); // Show info dialog
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
                    controller: _domainController, // Controller updated
                    decoration: InputDecoration(
                      labelText:
                          'Enter Domain Address', // Label in English and updated
                      hintText: '', // Hint text updated
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(
                        Icons.language,
                      ), // Icon suitable for domain
                    ),
                    keyboardType:
                        TextInputType.url, // Keyboard type suitable for URL
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
                                    'Please enter a domain address.', // Message in English
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                  icon: const Icon(Icons.search),
                  label: const Text('Search'), // Button text in English
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
            const SizedBox(height: 10), // Space between search and filter area
            // --- New Filtering Area ---
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
                    height: 40, // Give a fixed height
                    child:
                        _selectedExtensions.isEmpty
                            ? const Center(
                              child: Text(
                                'No filter applied (All extensions)',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              scrollDirection:
                                  Axis.horizontal, // Scrollable horizontally
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
                                              : ' |'), // Add pipe
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
                    _showExtensionFilterDialog(context); // Show filter dialog
                  },
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filter'),
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
                    'No domain queried yet or no results found. Please enter a domain address and query.', // Message in English and updated
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                : Expanded(
                  child: ListView.builder(
                    itemCount: _backendData.length,
                    itemBuilder: (context, index) {
                      final item = _backendData[index];
                      final String domain = item['Domain'] ?? 'Unknown Domain';
                      final String status = item['Status'] ?? 'Unknown';

                      // Choose color based on status
                      Color statusColor;
                      if (status.contains('Available')) {
                        statusColor = Colors.green;
                      } else if (status.contains('Registered')) {
                        statusColor = Colors.red;
                      } else {
                        statusColor = Colors.blue; // Default color
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
                            'Status: $status',
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          onTap: () {
                            // Show details only if status is 'Registered'
                            if (status.contains('Registered')) {
                              final String registrar =
                                  item['Registrar'] ?? 'Unknown';
                              final dynamic emailData =
                                  item['Emails']; // Keep as dynamic to handle list or string
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
                                    title: const Text('Domain Details'),
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
                                              text: 'Status: ',
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
                                              text: 'Registrar: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$registrar\n'),
                                            const TextSpan(
                                              text:
                                                  'Email(s): ', // Changed label to plural
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '${_formatEmails(emailData)}\n',
                                            ), // Use the new function
                                            const TextSpan(
                                              text: 'Creation Date: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$creationDate\n'),
                                            const TextSpan(
                                              text: 'Expiration Date: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(text: '$expirationDate\n'),
                                            const TextSpan(
                                              text: 'Updated Date: ',
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
                                        child: const Text('OK'),
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
