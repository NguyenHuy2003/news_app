import 'dart:convert';

import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'article_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ngày tháng
              Text(
                DateFormat('EEE, dd\'th\' MMMM yyyy').format(DateTime.now()),
              ),
              const Text(
                'Explore',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              // Title
              const SizedBox(height: 24),
              // Input tìm kiếm
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: TextFormField(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade300,
                    filled: true,
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search for article',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Thanh danh sách thể loại
              const SizedBox(
                height: 40,
                child: CategoriesBar(),
              ),
              // Danh sách bài báo
              const SizedBox(height: 24),
              const Expanded(child: ArticleList()),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoriesBar extends StatefulWidget {
  const CategoriesBar({super.key});

  @override
  State<CategoriesBar> createState() => _CategoriesBarState();
}

class _CategoriesBarState extends State<CategoriesBar> {
  List<String> categories = const [
    'All',
    'Politics',
    'Sports',
    'Health',
    'Music',
    'Tech'
  ];

  int currentCategory = 0;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            currentCategory = index;
            setState(() {});
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(
              // vertical: 8.0,
              horizontal: 20.0,
            ),
            decoration: BoxDecoration(
              color: currentCategory == index ? Colors.black : Colors.white,
              border: Border.all(),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Center(
              child: Text(
                categories.elementAt(index),
                style: TextStyle(
                  color: currentCategory == index ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ArticleList extends StatelessWidget {
  const ArticleList({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getArticles(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return const Center(
              child: CircularProgressIndicator(),
            );
          case ConnectionState.done:
            final data = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.only(right: 16.0),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ArticleTile(
                  article: data.elementAt(index),
                );
              },
            );
        }
      },
    );
  }

  Future<List<Article>> getArticles() async {
    const url =
        'https://newsapi.org/v2/everything?q=tesla&from=2024-02-20&sortBy=publishedAt&apiKey=393e2281d6b44ccda1a66b5f8a7e11b2';
    final res = await http.get(Uri.parse(url));

    final body = json.decode(res.body) as Map<String, dynamic>;

    final List<Article> result = [];
    for (final article in body['articles']) {
      result.add(
        Article(
            title: article['title'],
            urlToImage: article['urlToImage'],
            author: article['author'],
            publishedAt: article['publishedAt']),
      );
    }

    return result;
  }
}

class ArticleTile extends StatelessWidget {
  const ArticleTile({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    // Kiểm tra xem article.publishedAt có null hay không trước khi chuyển đổi
    final publishedDateTime = article.publishedAt != null
        ? DateTime.parse(article.publishedAt!)
        : DateTime.now(); // Nếu null, sử dụng thời gian hiện tại

    // Định dạng thời gian đăng bài từ đối tượng DateTime
    final formattedDateTime =
        DateFormat.yMMMMd().add_jm().format(publishedDateTime);

    // Tính toán khoảng cách thời gian
    final timeDifference = DateTime.now().difference(publishedDateTime);

    // Chuyển khoảng cách thời gian thành chuỗi phù hợp
    String formattedTimeDifference;
    if (timeDifference.inDays > 0) {
      formattedTimeDifference = '${timeDifference.inDays} days ago';
    } else if (timeDifference.inHours > 0) {
      formattedTimeDifference = '${timeDifference.inHours} hours ago';
    } else if (timeDifference.inMinutes > 0) {
      formattedTimeDifference = '${timeDifference.inMinutes} minutes ago';
    } else {
      formattedTimeDifference = 'just now';
    }

    return Container(
      height: 128,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              article.urlToImage ?? '',
              fit: BoxFit.cover,
              height: 128,
              width: 128,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 128,
                  width: 128,
                  color: Colors.lightBlue,
                );
              },
            ),
          ),
          // TODO: Thêm thông tin bài báo
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3, // Giới hạn số dòng của tiêu đề
                  overflow: TextOverflow.ellipsis, // Tránh tràn dòng
                ),
                const SizedBox(
                    height:
                        4), // Khoảng cách giữa tiêu đề và văn bản "viết bởi"
                Text(
                  'By ${article.author ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 14, // Kích thước văn bản nhỏ hơn tiêu đề
                    color: Colors.grey,
                    // Màu xám
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      formattedTimeDifference,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const SizedBox(width: 4),
                    const Text(
                      'Unknown',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const SizedBox(width: 4),
                    const Text(
                      '5 mins',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
