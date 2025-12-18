import 'package:flutter/material.dart';
import 'package:happbit/pages/auth/sign_in_page.dart';
import 'package:happbit/services/data_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtl = TextEditingController();

  final data = DataService();
  List<Map<String, dynamic>> news = [];
  List<Map<String, dynamic>> filteredNews = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadNews();
  }

  Future<void> loadNews() async {
    try {
      final res = await data.fetchNews();
      setState(() {
        news = res;
        filteredNews = res;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint('Error load news: $e');
    }
  }

  void searchNews(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredNews = news;
      });
      return;
    }

    final result = news.where((item) {
      final title = item['title'].toString().toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredNews = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (news.isEmpty) {
      return const Center(child: Text('Belum ada berita'));
    }
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Explore",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 24),
            ),
            SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: _FloatingTextField(
                controller: _searchCtl,
                onChanged: searchNews,
                label: "Search Articles",
                prefix: const Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : news.isEmpty
                  ? const Center(child: Text('Belum ada data'))
                  : ListView.builder(
                      itemBuilder: (context, index) {
                        final item = filteredNews[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(10),
                                child: Image.asset(
                                  "assets/images/" + item['image'] ?? "",
                                  // "assets/images/quality_sleep.jpg",
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? "",
                                      // "Tidur Berkualitas, Kunci Kesehatan Mental",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      item['description'] ?? "",
                                      // "Tidur yang cukup dan berkualitas memiliki peran besar dalam menjaga kesehatan mental dan emosional. Kurang tidur dapat menyebabkan stres, mudah lelah, dan menurunnya daya konsentrasi. Hapbit membantu pengguna memantau durasi serta pola tidur untuk memastikan tubuh mendapatkan waktu istirahat yang optimal setiap malam.",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      item['date'] ?? "",
                                      // "2025-10-10",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Image.asset(
                                // Menambahkan fallback jika image null
                                "assets/images/${item['image'] ?? 'placeholder.jpg'}", 
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                // Menangani jika file asset tidak ditemukan
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      itemCount: filteredNews.length,
                      // itemCount: 10,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTextField extends StatelessWidget {
  const _FloatingTextField({
    required this.controller,
    required this.label,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(10),
      child: TextField(
        onChanged: onChanged,
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14, color: Colors.black),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: prefix,
          prefixIconColor: Colors.black,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.all(16),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
            borderRadius: BorderRadius.circular(10),
          ),
          // focusColor:
        ),
      ),
    );
  }
}
