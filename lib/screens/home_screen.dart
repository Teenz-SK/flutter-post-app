import 'dart:ui';
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
  final Set<int> loadedIds = {};

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
      setState(() => isError = true);
    } finally {
      setState(() => isLoading = false);
    }
  }

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

  Future<void> _refresh() async {
    await fetchInitialPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildShimmer()
          : isError
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildSliverHeader(),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < visiblePosts.length) {
                        return _buildPostCard(visiblePosts[index], index);
                      } else {
                        return _buildBottomLoader();
                      }
                    }, childCount: visiblePosts.length + 1),
                  ),
                ],
              ),
            ),
    );
  }

  // 🌈 SLIVER HEADER (PRO)
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text("Discover Posts"),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8F94FB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // 🧊 GLASS CARD
  Widget _buildPostCard(PostModel post, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 50)),
      tween: Tween(begin: 50.0, end: 0.0),
      builder: (context, value, child) {
        return Transform.translate(offset: Offset(0, value), child: child);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 400),
              pageBuilder: (_, __, ___) => DetailScreen(post: post),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),

                    // ❤️ Micro interaction row
                    Row(
                      children: [
                        Icon(Icons.favorite_border, size: 20),
                        SizedBox(width: 10),
                        Icon(Icons.share, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔄 Bottom Loader
  Widget _buildBottomLoader() {
    if (hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text("🎉 You're all caught up")),
      );
    }
  }

  // ❌ Error
  Widget _buildError() {
    return Center(
      child: ElevatedButton(
        onPressed: fetchInitialPosts,
        child: const Text("Retry"),
      ),
    );
  }

  // ✨ SHIMMER LOADING
  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }
}
