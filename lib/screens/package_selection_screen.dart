import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_cfast/constants.dart';
import '../models/package_model.dart';
import 'login_page.dart';

class PackageSelectionScreen extends StatefulWidget {
  final Function(Package) onPackageSelected;
  final String token;

  const PackageSelectionScreen({Key? key, required this.onPackageSelected, required this.token}) : super(key: key);

  @override
  _PackageSelectionScreenState createState() => _PackageSelectionScreenState();
}

class _PackageSelectionScreenState extends State<PackageSelectionScreen> {
  List<Package> _packages = [];
  bool _isLoading = true;
  String _error = '';
  bool _hasActiveAds = false;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
    _checkActiveAds();
  }

  Future<void> _checkActiveAds() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cfastapi/my_ads.php?token=${widget.token}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _hasActiveAds = data.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('Error checking ads: $e');
    }
  }

  Future<void> _fetchPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/packages?embed=currency&sort=-lft'),
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Content-Language': 'en',
            'X-AppApiToken': 'WXhEdVFMT3VuVHRWTlFRQWQyMzdVSHN5ZnRZWlJEOEw=',
            'X-AppType': 'docs'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List<dynamic> results = data['result']['data'];
            setState(() {
              _packages = results.map((json) => Package.fromJson(json)).toList();
              // Sort packages so free ones come first
              _packages.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
              _isLoading = false;
            });
        } else {
             setState(() {
            _error = 'Failed to load packages';
            _isLoading = false;
          });
        }
       
      } else {
        setState(() {
          _error = 'Error fetching packages: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
       elevation: 0.0,
       backgroundColor: Colors.transparent,
       child: Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.white,
             borderRadius: BorderRadius.circular(16),
           ),
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Text(
                 "Select a Package",
                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
               ),
               const SizedBox(height: 16),
               if (_isLoading)
                 const CircularProgressIndicator()
               else if (_error.isNotEmpty)
                 Text(_error, style: const TextStyle(color: Colors.red))
               else
                 SizedBox(
                   height: 300, // Limit height
                   child: ListView.builder(
                     shrinkWrap: true,
                     itemCount: _packages.length,
                     itemBuilder: (context, index) {
                       final package = _packages[index];
                       final isFree = double.parse(package.price) == 0;
                       // Disable free package if user already has active ads
                       final bool isDisabled = isFree && _hasActiveAds;

                       return Card(
                         elevation: 2,
                         margin: const EdgeInsets.symmetric(vertical: 8),
                         child: Padding(
                           padding: const EdgeInsets.all(12.0),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 package.shortName.isNotEmpty ? package.shortName : package.name,
                                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                               ),
                               const SizedBox(height: 12),
                               Row(
                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                 children: [
                                   Expanded(
                                     child: Row(
                                       children: [
                                         CircleAvatar(
                                           radius: 18,
                                           backgroundColor: isFree ? Colors.grey : Colors.orange,
                                           child: Icon(isFree ? Icons.money_off : Icons.star, color: Colors.white, size: 20),
                                         ),
                                         const SizedBox(width: 8),
                                         Expanded(
                                           child: Text(
                                              package.currencyCode == 'NGN' ? '₦${package.price.replaceAll(RegExp(r'\.00$'), '')}' : '${package.currencyCode} ${package.price.replaceAll(RegExp(r'\.00$'), '')}',
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                   const SizedBox(width: 8),
                                   ElevatedButton(
                                     onPressed: isDisabled ? null : () {
                                       widget.onPackageSelected(package);
                                     },
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: isFree ? Colors.grey : Colors.green,
                                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                       disabledBackgroundColor: Colors.grey[300],
                                     ),
                                     child: Text(
                                         isDisabled ? "Limit Reached" : (isFree ? "Select" : "Pay"),
                                         style: TextStyle(color: isDisabled ? Colors.black54 : Colors.white),
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                       );
                     },
                   ),
                 ),
                const SizedBox(height: 16),
                TextButton(child: const Text("Cancel"), onPressed: (){
                    Navigator.of(context).pop();
                })
             ],
           ),
       ),
    );
  }
}
