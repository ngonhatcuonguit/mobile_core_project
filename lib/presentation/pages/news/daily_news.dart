import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:flutter_core_project/presentation/widgets/appbar/app_bar.dart';
import 'package:flutter_core_project/services/network_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_core_project/presentation/widgets/no_internet_ui.dart';
import '../../../core/configs/assets/app_vectors.dart';
import '../../bloc/article/remote/remote_article_event.dart';
import '../../widgets/article_widget.dart';

class DailyNews extends StatefulWidget {
  const DailyNews({super.key});

  @override
  State<DailyNews> createState() => _DailyNewsState();
}

class _DailyNewsState extends State<DailyNews> {
  bool _hasNoInternet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkNetworkAndLoadArticles();
      }
    });
  }

  Future<void> _checkNetworkAndLoadArticles() async {
    debugPrint('🔍 Checking network...');
    final hasInternet = await NetworkService().hasInternetConnection();
    debugPrint('📶 Has Internet: $hasInternet');

    if (!hasInternet) {
      debugPrint('❌ No internet detected');
      if (mounted) {
        setState(() {
          _hasNoInternet = true;
        });
      }
      return;
    }

    debugPrint('✅ Internet available, loading articles...');
    if (mounted) {
      setState(() {
        _hasNoInternet = false;
      });
      try {
        final bloc = context.read<RemoteArticlesBloc>();
        if (!bloc.isClosed) {
          debugPrint('📰 Dispatching GetArticles event');
          bloc.add(const GetArticles());
        }
      } catch (e) {
        debugPrint('❌ RemoteArticlesBloc error: $e');
      }
    }
  }

  Widget _buildNoInternetUI() {
    return NoInternetUI(
      onRetry: () async {
        debugPrint('🔄 User tapped Retry');
        await _checkNetworkAndLoadArticles();
      },
      onDismiss: () {
        debugPrint('❌ User dismissed No Internet UI');
        // Simply hide the no internet UI
        // User can still navigate to other tabs freely
        if (mounted) {
          setState(() {
            _hasNoInternet = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppBar(
        title: SvgPicture.asset(
          AppVectors.thp_logo_horizontal,
          height: 30,
          width: 30,
        ),
        hideLeading: true,
      ),
      body: _hasNoInternet ? _buildNoInternetUI() : _buildBody(),
      // Ensure body is not blocking interactions
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _buildBody() {
    return BlocBuilder<RemoteArticlesBloc, RemoteArticleState>(
      builder: (context, state) {
        if (state is RemoteArticleLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is RemoteArticleError) {
          // Parse error message to detect connection issues
          final errorMessage = state.error?.toString() ?? '';
          final isConnectionError =
              errorMessage.contains('Failed host lookup') ||
                  errorMessage.contains('SocketException') ||
                  errorMessage.contains('connection error') ||
                  errorMessage.contains('No address associated');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isConnectionError ? Icons.wifi_off : Icons.cloud_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isConnectionError
                        ? 'No Internet Connection'
                        : 'Failed to load articles',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConnectionError
                        ? 'Please check your internet connection.\nMake sure you can access newsapi.org.'
                        : 'Something went wrong.\nPlease try again later.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  if (isConnectionError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'DNS lookup failed for newsapi.org',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasNoInternet = false;
                      });
                      _checkNetworkAndLoadArticles();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        } else if (state is RemoteArticleDone) {
          if (state.articles == null || state.articles!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No articles available',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for new articles.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: state.articles?.length,
            itemBuilder: (context, index) {
              return ArticleWidget(article: state.articles![index]);
            },
          );
        }

        // Default state: Show empty state with action to load
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to Daily News',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the button below to load latest articles.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkNetworkAndLoadArticles,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Load Articles'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
