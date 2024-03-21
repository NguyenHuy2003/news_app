import 'dart:convert';

import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'article_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Article> articles = [];
  List<Article> searchResults = [];
  String currentCategory = 'All';
  List<Article> displayArticles = [];

  @override
  void initState() {
    super.initState();
    fetchArticles();
  }

  Future<void> fetchArticles() async {
    const url =
        'https://newsapi.org/v2/everything?q=tesla&from=2024-02-21&sortBy=publishedAt&apiKey=393e2281d6b44ccda1a66b5f8a7e11b2';
    final res = await http.get(Uri.parse(url));

    final body = json.decode(res.body) as Map<String, dynamic>;

    final List<Article> result = [];
    for (final article in body['articles']) {
      result.add(Article(
        title: article['title'],
        urlToImage: article['urlToImage'],
        author: article['author'],
        publishedAt: article['publishedAt'],
        categories: article['categories'],
      ));
    }

    setState(() {
      articles = result;
      filterByCategory(currentCategory);
    });
  }

  void performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
        filterByCategory(currentCategory);
      });
    } else {
      setState(() {
        searchResults = articles
            .where((article) =>
                article.title!.toLowerCase().contains(query.toLowerCase()))
            .toList();
        filterByCategory(currentCategory);
      });
    }
  }

  void filterByCategory(String category) {
    setState(() {
      currentCategory = category;
      if (category == 'All') {
        displayArticles = searchResults.isNotEmpty ? searchResults : articles;
      } else {
        displayArticles = searchResults.isNotEmpty
            ? searchResults
                .where((article) =>
                    article.categories?.contains(category) ?? false)
                .toList()
            : articles
                .where((article) =>
                    article.categories?.contains(category) ?? false)
                .toList();
      }
      if (displayArticles.isEmpty && category != 'All') {
        displayArticles = articles
            .where((article) =>
                article.categories == null ||
                !article.categories!.contains(category))
            .toList();
      }
    });
  }

  List<Article> getFilteredArticles() {
    if (currentCategory == 'All') {
      return searchResults.isNotEmpty ? searchResults : articles;
    } else {
      return searchResults.isNotEmpty
          ? searchResults
              .where((article) =>
                  article.categories?.contains(currentCategory) ?? false)
              .toList()
          : articles
              .where((article) =>
                  article.categories?.contains(currentCategory) ?? false)
              .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 24),
              SearchBar(
                onSearch: (searchQuery) {
                  performSearch(searchQuery);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 40,
                child: CategoriesBar(
                  onCategorySelected: (category) {
                    filterByCategory(category);
                  },
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ArticleList(articles: getFilteredArticles()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoriesBar extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesBar({Key? key, required this.onCategorySelected})
      : super(key: key);

  @override
  State<CategoriesBar> createState() => _CategoriesBarState();
}

class _CategoriesBarState extends State<CategoriesBar> {
  List<String> categories = const [
    'All',
    'Politics',
    'Unknown',
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
            setState(() {
              currentCategory = index;
            });
            widget.onCategorySelected(categories[index]);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(
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
  final List<Article> articles;

  const ArticleList({Key? key, required this.articles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(right: 16.0),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return ArticleTile(article: articles[index]);
      },
    );
  }
}

class ArticleTile extends StatelessWidget {
  final Article article;

  const ArticleTile({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final publishedDateTime = article.publishedAt != null
        ? DateTime.parse(article.publishedAt!)
        : DateTime.now();

    final timeDifference = DateTime.now().difference(publishedDateTime);

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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${article.author ?? 'Unknown'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                    Text(
                      '${article.categories ?? 'Unknown'}',
                      style: const TextStyle(
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

class SearchBar extends StatefulWidget {
  final Function(String) onSearch;

  const SearchBar({Key? key, required this.onSearch}) : super(key: key);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: TextFormField(
        controller: _searchController,
        onChanged: (value) {
          widget.onSearch(value);
        },
        decoration: InputDecoration(
          fillColor: Colors.grey.shade300,
          filled: true,
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search for article',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
