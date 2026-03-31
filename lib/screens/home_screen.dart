import 'package:flutter/material.dart';
import 'package:post_app/screens/detail_screen.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();

  List<PostModel> allPosts = [];
  List<PostModel> visiblePosts = [];

  final Set<int> loadedIds = {}; // duplication check

  int page = 0;
  final int limit = 10;

  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool isError = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchInitialPosts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          hasMore) {
        loadMorePosts();
      }
    });
  }

  // 🔹 Initial Fetch
  Future<void> fetchInitialPosts() async {
    try {
      setState(() {
        isLoading = true;
        isError = false;
      });

      final data = await apiService.fetchPosts();

      allPosts = data;
      visiblePosts.clear();
      loadedIds.clear();
      page = 0;
      hasMore = true;

      loadMorePosts();
    } catch (e) {
      setState(() {
        isError = true;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 🔹 Load More (Pagination)
  void loadMorePosts() {
    if (!hasMore) return;

    setState(() => isLoadingMore = true);

    int start = page * limit;
    int end = start + limit;

    final newPosts = allPosts.sublist(
      start,
      end > allPosts.length ? allPosts.length : end,
    );

    if (newPosts.isEmpty) {
      hasMore = false;
    } else {
      for (var post in newPosts) {
        if (!loadedIds.contains(post.id)) {
          visiblePosts.add(post);
          loadedIds.add(post.id);
        }
      }
      page++;
    }

    setState(() => isLoadingMore = false);
  }

  // 🔹 Pull to Refresh
  Future<void> _refresh() async {
    await fetchInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🌈 Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8F94FB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            ),
            child: const Center(
              child: Text(
                "Posts",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 📦 Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : isError
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: visiblePosts.length + 1,
                      itemBuilder: (context, index) {
                        if (index < visiblePosts.length) {
                          return _buildPostCard(visiblePosts[index], index);
                        } else {
                          if (hasMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text("No more posts")),
                            );
                          }
                        }
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ❌ Error UI
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Something went wrong"),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: fetchInitialPosts,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  // 🧾 Post Card UI with Animation
  Widget _buildPostCard(PostModel post, int index) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300 + (index * 50)),
      opacity: 1,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => DetailScreen(post: post),
              transitionsBuilder: (_, animation, __, child) {
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Card(
            elevation: 4,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
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
