import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_state.dart';
import 'package:flutter_core_project/presentation/widgets/appbar/app_bar.dart';
import 'package:flutter_core_project/services/localization_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5),
      appBar: BasicAppBar(
        title: SvgPicture.asset(
          AppVectors.thp_logo_horizontal,
          height: 30,
          width: 30,
        ),
        hideLeading: true,
      ),
      body: _hasNoInternet ? _buildNoInternetUI() : _buildBody(isDark),
      resizeToAvoidBottomInset: false,
    );
  }

  Widget _buildNoInternetUI() {
    return NoInternetUI(
      onRetry: () async {
        debugPrint('🔄 User tapped Retry');
        await _checkNetworkAndLoadArticles();
      },
      onDismiss: () {
        if (mounted) {
          setState(() {
            _hasNoInternet = false;
          });
        }
      },
    );
  }

  Widget _buildBody(bool isDark) {
    return BlocBuilder<RemoteArticlesBloc, RemoteArticleState>(
      builder: (context, state) {
        if (state is RemoteArticleLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? const Color(0xFF42C83C) : null,
            ),
          );
        } else if (state is RemoteArticleError) {
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
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isConnectionError
                        ? context.tr('news_no_internet')
                        : context.tr('news_failed_load'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isConnectionError
                        ? 'Please check your internet connection.'
                        : 'Something went wrong. Please try again later.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isConnectionError) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900.withOpacity(0.2)
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? Colors.orange.shade800
                              : Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              color: isDark
                                  ? Colors.orange.shade400
                                  : Colors.orange.shade700,
                              size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              context.tr('news_dns_info'),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.orange.shade300
                                    : Colors.orange.shade900,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2A) : null,
                      foregroundColor:
                          isDark ? const Color(0xFF42C83C) : null,
                    ),
                    onPressed: () {
                      setState(() => _hasNoInternet = false);
                      _checkNetworkAndLoadArticles();
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.tr('news_retry')),
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
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('news_empty'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('news_check_back'),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
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

        // Default state
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 80,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('news_welcome'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('news_check_back'),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2A) : null,
                    foregroundColor:
                        isDark ? const Color(0xFF42C83C) : null,
                  ),
                  onPressed: _checkNetworkAndLoadArticles,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('news_load_articles')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkNetworkAndLoadArticles() async {
    debugPrint('🔍 Checking network...');
    final hasInternet = await NetworkService().hasInternetConnection();
    debugPrint('📶 Has Internet: $hasInternet');

    if (!hasInternet) {
      if (mounted) setState(() => _hasNoInternet = true);
      return;
    }

    if (mounted) {
      setState(() => _hasNoInternet = false);
      try {
        final bloc = context.read<RemoteArticlesBloc>();
        if (!bloc.isClosed) {
          bloc.add(const GetArticles());
        }
      } catch (e) {
        debugPrint('❌ RemoteArticlesBloc error: $e');
      }
    }
  }
}
