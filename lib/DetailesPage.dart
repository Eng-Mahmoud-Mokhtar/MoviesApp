import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:url_launcher/url_launcher.dart';

class MovieDetails {
  final int id;
  final String title;
  final String thumbnailUrl;
  final String? seriesName;
  final String? year;
  final String? seasonNumber;
  final int? episodeNumber;
  final String? quality;
  final String? rating;
  final int? likesCount;
  final int? categoryId;
  final String? deletedAt;
  final int? isVisible;
  final List<String> categories;
  final MovieDetails? details;
  final List<DownloadLink>? downloadLinks;
  final List<WatchServer>? watchServers;
  final String? arabicName;
  final String? story;
  final String? genres;
  final String? breadcrumb;

  MovieDetails({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    this.seriesName,
    this.year,
    this.seasonNumber,
    this.episodeNumber,
    this.quality,
    this.rating,
    this.likesCount,
    this.categoryId,
    this.deletedAt,
    this.isVisible,
    required this.categories,
    this.details,
    this.downloadLinks,
    this.watchServers,
    this.arabicName,
    this.story,
    this.genres,
    this.breadcrumb,
  });

  factory MovieDetails.fromJson(Map<String, dynamic> json) {
    return MovieDetails(
      id: json['id'],
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      seriesName: json['series_name']?.toString() ?? 'لا يوجد',
      year: json['year']?.toString() ?? 'غير متوفر',
      seasonNumber: json['season_number']?.toString() ?? 'غير متوفر',
      episodeNumber:
          json['episode_number'] != null
              ? int.tryParse(json['episode_number'].toString())
              : null,
      quality: json['quality'],
      rating: json['rating']?.toString() ?? 'لا يوجد تقييم',
      likesCount:
          json['likes_count'] != null
              ? int.tryParse(json['likes_count'].toString())
              : null,
      categoryId: json['category_id'],
      deletedAt: json['deleted_at'],
      isVisible:
          json['is_visible'] != null
              ? int.tryParse(json['is_visible'].toString())
              : null,
      details:
          json['details'] != null
              ? MovieDetails.fromJson(json['details'])
              : null,
      categories: List<String>.from(json['categories'] ?? []),
      downloadLinks:
          json['download_links'] != null
              ? List<DownloadLink>.from(
                json['download_links'].map((x) => DownloadLink.fromJson(x)),
              )
              : null,
      watchServers:
          json['watch_servers'] != null
              ? List<WatchServer>.from(
                json['watch_servers'].map((x) => WatchServer.fromJson(x)),
              )
              : null,
      arabicName: json['arabic_name'],
      story: json['story'],
      genres: json['genres'] ?? 'غير متوفر',
      breadcrumb: json['breadcrumb'],
    );
  }
}

//-----------------------------------------------------------------------
class DownloadLink {
  final String quality;
  final String resolution;
  final String downloadUrl;
  final String? fileSize;

  DownloadLink({
    required this.quality,
    required this.resolution,
    required this.downloadUrl,
    this.fileSize,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      quality: json['quality'] ?? '',
      resolution: json['resolution'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      fileSize: json['file_size']?.toString(),
    );
  }
}

//-----------------------------------------------------------------------

class WatchServer {
  final String name;
  final String url;
  final String? color;

  WatchServer({required this.name, required this.url, this.color});

  factory WatchServer.fromJson(Map<String, dynamic> json) {
    return WatchServer(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      color: json['color'],
    );
  }
}

//-----------------------------------------------------------------------
//MovieDetails
//-----------------------------------------------------------------------

abstract class MovieDetailsState {}

class MovieDetailsInitial extends MovieDetailsState {}

class MovieDetailsLoading extends MovieDetailsState {}

class MovieDetailsLoaded extends MovieDetailsState {
  final MovieDetails movie;
  final String? currentVideoUrl;

  MovieDetailsLoaded(this.movie, {this.currentVideoUrl});
}

class MovieDetailsError extends MovieDetailsState {
  final String message;

  MovieDetailsError(this.message);
}
//-----------------------------------------------------------------------
class MovieDetailsCubit extends Cubit<MovieDetailsState> {
  final Dio _dio = Dio();

  MovieDetailsCubit() : super(MovieDetailsInitial());

  Future<void> fetchMovie(int movieId) async {
    emit(MovieDetailsLoading());
    try {
      final String url =
          'https://scraping.jokerapp24.com/public/api/movies/$movieId';
      Response response = await _dio.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = response.data;
        if (jsonResponse['success'] == true) {
          final movie = MovieDetails.fromJson(jsonResponse['data']);
          emit(MovieDetailsLoaded(movie));
        } else {
          emit(MovieDetailsError("حدث خطأ في API (success=false)"));
        }
      } else {
        emit(MovieDetailsError("فشل في جلب تفاصيل الفيلم"));
      }
    } catch (e) {
      emit(MovieDetailsError("فشل في جلب تفاصيل الفيلم: $e"));
    }
  }

  void updateVideoUrl(String url) {
    if (state is MovieDetailsLoaded) {
      final currentState = state as MovieDetailsLoaded;
      emit(MovieDetailsLoaded(currentState.movie, currentVideoUrl: url));
    }
  }
}

//-----------------------------------------------------------------------

class MovieDetailsScreen extends StatelessWidget {
  final int movieId;
  const MovieDetailsScreen({super.key, required this.movieId});
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieDetailsCubit()..fetchMovie(movieId),
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            actions:[Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                'مشاهدة',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),]
        ),
        body: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
          builder: (context, state) {
            if (state is MovieDetailsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (state is MovieDetailsError) {
              return Center(
                child: Text(
                  "فشل الاتصال",
                  style: const TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),
                ),
              );
            } else if (state is MovieDetailsLoaded) {
              final movie = state.movie;
              final currentVideoUrl =
                  state.currentVideoUrl ?? movie.watchServers?.first.url;
              return _buildMovieDetails(context, movie, currentVideoUrl);
            } else {
              return const Center(
                child: Text(
                  "لا توجد بيانات",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildMovieDetails(
    BuildContext context,
    MovieDetails movie,
    String? currentVideoUrl,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final mainTextSize = screenSize.width * 0.04;
    final subTextSize = screenSize.width * 0.035;
    final videoHeight = screenSize.height * 0.3;
    final mainTextStyle = TextStyle(
      color: Colors.white,
      fontSize: mainTextSize,
      fontWeight: FontWeight.bold,
    );
    final subTextStyle = TextStyle(color: Colors.white, fontSize: subTextSize);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InlineVlcPlayer(
            videoUrl: currentVideoUrl ?? '',
            height: videoHeight,
            thumbnailUrl: movie.thumbnailUrl,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: DefaultTextStyle(
                style: subTextStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: screenSize.width * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "قصة العرض:",
                      style: mainTextStyle.copyWith(fontSize: mainTextSize),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.details?.story ?? "لا يوجد وصف .",
                      style: subTextStyle,
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 16),
                    if (movie.details != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "الجودة: ${movie.details!.quality ?? 'N/A'}",
                            style: subTextStyle,
                          ),
                          Text(
                            "السنة: ${movie.year ?? 'غير متوفر'}",
                            style: subTextStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "النوع: ${movie.details?.genres != null && movie.details!.genres!.isNotEmpty ? movie.details!.genres : 'غير متوفر'}",
                              style: subTextStyle.copyWith(
                                fontSize: subTextSize,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "الحالة: ${movie.isVisible == 1 ? 'مرئي' : 'غير مرئي'}",
                            style: subTextStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          "خوادم المشاهدة",
                          style: mainTextStyle.copyWith(fontSize: mainTextSize),
                        ),
                        children:
                            (movie.watchServers != null &&
                                    movie.watchServers!.isNotEmpty)
                                ? [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: movie.watchServers!.length,
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 3,
                                          ),
                                      itemBuilder: (context, index) {
                                        final server =
                                            movie.watchServers![index];
                                        return GestureDetector(
                                          onTap: () {
                                            context
                                                .read<MovieDetailsCubit>()
                                                .updateVideoUrl(server.url);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  server.color != null
                                                      ? HexColor(server.color!)
                                                      : Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                server.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: subTextSize,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ]
                                : [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "لا توجد خوادم متاحة",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: EdgeInsets.zero,
                        title: Text(
                          "روابط التحميل",
                          style: mainTextStyle.copyWith(fontSize: mainTextSize),
                        ),
                        children:
                            (movie.downloadLinks != null &&
                                    movie.downloadLinks!.isNotEmpty)
                                ? movie.downloadLinks!.map((link) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _launchURL(link.downloadUrl),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Icon(
                                              Icons.download,
                                              color: Colors.white,
                                            ),
                                            Expanded(
                                              child: Text(
                                                "اضغط هنا للتحميل (${link.quality} - ${link.resolution} - ${link.fileSize ?? 'غير معروف'})",
                                                style: subTextStyle.copyWith(
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList()
                                : [
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      "لا توجد روابط متاحة",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      if (!['http', 'https'].contains(uri.scheme)) return;

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint(' لا يمكن فتح الرابط: $url');
      }
    } catch (e) {
      debugPrint('️ خطأ أثناء محاولة فتح الرابط: $e');
    }
  }
} //-----------------------------------------------------------------------
// Video
//-----------------------------------------------------------------------

abstract class VlcPlayerState {}

class VlcPlayerInitial extends VlcPlayerState {}

class VlcPlayerLoading extends VlcPlayerState {}

class VlcPlayerPlaying extends VlcPlayerState {}

class VlcPlayerError extends VlcPlayerState {
  final String message;
  VlcPlayerError(this.message);
}

//-----------------------------------------------------------------------
class VlcPlayerCubit extends Cubit<VlcPlayerState> {
  final VlcPlayerController _vlcController;

  VlcPlayerCubit(String videoUrl)
    : _vlcController = VlcPlayerController.network(
        videoUrl,
        autoPlay: false,
        options: VlcPlayerOptions(),
      ),
      super(VlcPlayerInitial());

  VlcPlayerController get controller => _vlcController;

  void playVideo() {
    emit(VlcPlayerLoading());
    _vlcController
        .play()
        .then((_) {
          emit(VlcPlayerPlaying());
        })
        .catchError((error) {
          emit(VlcPlayerError("حدث خطأ أثناء التشغيل"));
        });
  }

  void checkError() {
    _vlcController.addListener(() {
      if (_vlcController.value.playingState == PlayingState.error) {
        emit(VlcPlayerError("تعذر تشغيل الفيديو. تأكد من الرابط."));
      }
    });
  }

  @override
  Future<void> close() {
    _vlcController.dispose();
    return super.close();
  }
}

//-----------------------------------------------------------------------
class InlineVlcPlayer extends StatelessWidget {
  final String videoUrl;
  final double height;
  final String? thumbnailUrl;

  const InlineVlcPlayer({
    super.key,
    required this.videoUrl,
    required this.height,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => VlcPlayerCubit(videoUrl)..checkError(),
      child: BlocBuilder<VlcPlayerCubit, VlcPlayerState>(
        builder: (context, state) {
          final cubit = context.read<VlcPlayerCubit>();
          return GestureDetector(
            onTap: state is! VlcPlayerPlaying ? cubit.playVideo : null,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state is VlcPlayerPlaying)
                    VlcPlayer(
                      controller: cubit.controller,
                      aspectRatio: 16 / 9,
                      placeholder: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                    Image.network(
                      thumbnailUrl!,
                      height: height,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox(),
                    ),
                  if (state is! VlcPlayerPlaying && state is! VlcPlayerError)
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  if (state is VlcPlayerError)
                    Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            state.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
//-----------------------------------------------------------------------
// HexColorServer
//-----------------------------------------------------------------------

class HexColor extends Color {
  static int _getColorFromHex(String hex) {
    hex = hex.toUpperCase().replaceAll("#", "");
    if (hex.length == 6) {
      hex = "FF$hex";
    }
    return int.parse(hex, radix: 16);
  }
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}
