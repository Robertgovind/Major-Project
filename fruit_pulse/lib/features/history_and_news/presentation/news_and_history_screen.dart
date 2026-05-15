import 'package:flutter/material.dart';
import 'package:fruit_pulse/features/history_and_news/widgets/history_tab.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/providers/news_provider.dart';
import '../../../shared/providers/sensor_provider.dart';
import '../../../shared/widgets/news_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('News & Sensor History'),
          backgroundColor: AppColors.primaryGreen,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'News'),
              Tab(text: 'Sensor History'),
            ],
          ),
        ),
        body: Consumer2<NewsProvider, SensorProvider>(
          builder: (context, newsProvider, sensorProvider, _) {
            return TabBarView(
              children: [
                _buildNewsTab(context, newsProvider),
                HistoryTab(provider: sensorProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsTab(BuildContext context, NewsProvider newsProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await newsProvider.loadNews(
          category: newsProvider.selectedCategory == 'All'
              ? null
              : newsProvider.selectedCategory,
        );
      },
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: newsProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = newsProvider.categories[index];
                        final isSelected =
                            newsProvider.selectedCategory == category;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) {
                              newsProvider.selectCategory(category);
                            },
                            backgroundColor: Colors.grey[200],
                            selectedColor: AppColors.primaryGreen,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Latest Produce News',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: newsProvider.isLoading
                        ? null
                        : () => newsProvider.loadNews(
                            category: newsProvider.selectedCategory == 'All'
                                ? null
                                : newsProvider.selectedCategory,
                          ),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (newsProvider.isLoading)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Loading live news...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            else if (newsProvider.articles.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        newsProvider.errorMessage == null
                            ? Icons.newspaper
                            : Icons.cloud_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        newsProvider.errorMessage ?? 'No news available',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 0.95,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: newsProvider.articles.length,
                  itemBuilder: (context, index) {
                    final article = newsProvider.articles[index];

                    return NewsCard(
                      article: article,
                      onTap: () {
                        context.push('/news/${article.id}');
                      },
                    );
                  },
                ),
              ),
            if (newsProvider.errorMessage != null &&
                newsProvider.articles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  newsProvider.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
