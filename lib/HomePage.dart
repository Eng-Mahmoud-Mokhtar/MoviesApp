import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'CategoryPage.dart';
import 'DetailesPage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class CategoriesState {}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesLoaded extends CategoriesState {
  final Map<String, List<dynamic>> categorizedMovies;
  CategoriesLoaded(this.categorizedMovies);
}

class CategoriesError extends CategoriesState {
  final String message;
  CategoriesError(this.message);
}

//-----------------------------------------------------------------------
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit() : super(CategoriesInitial());

  Future<void> fetchMovies() async {
    emit(CategoriesLoading());
    try {
      final dio = Dio();
      final response = await dio.get('https://scraping.jokerapp24.com/public/api/v2/categories/detailed');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data["data"] is Map && data["data"]["data"] is List) {
          Map<String, List<dynamic>> tempCategories = {};

          for (var category in data["data"]["data"]) {
            if (category is Map &&
                category["name"] is String &&
                category["movies"] is Map &&
                category["movies"]["data"] is List) {
              tempCategories[category["name"]] = List<Map<String, dynamic>>.from(category["movies"]["data"]);
            }
          }
          emit(CategoriesLoaded(tempCategories));
        } else {
          emit(CategoriesError("لا توجد بيانات متاحة."));
        }
      } else {
        emit(CategoriesError("فشل تحميل البيانات"));
      }
    } catch (e) {
      emit(CategoriesError("فشل الاتصال"));
    }
  }
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------

class AllCategories {
  final int id;
  final String title;
  final String thumbnailUrl;

  AllCategories({required this.id, required this.title, required this.thumbnailUrl});

  factory AllCategories.fromJson(Map<String, dynamic> json) {
    return AllCategories(
      id: json['id'],
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }
}
class AllCategoriesState {
  final List<AllCategories> movies;
  final bool isLoading;
  final bool isSearching;
  final String searchQuery;

  AllCategoriesState({required this.movies, this.isLoading = false, this.isSearching = false, this.searchQuery = ''});

  AllCategoriesState copyWith({
    List<AllCategories>? movies,
    bool? isLoading,
    bool? isSearching,
    String? searchQuery,
  }) {
    return AllCategoriesState(
      movies: movies ?? this.movies,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
class AllCategoriesCubit extends Cubit<AllCategoriesState> {
  final Dio _dio = Dio();

  AllCategoriesCubit() : super(AllCategoriesState(movies: []));

  Future<void> fetchMovies(String query) async {
    emit(state.copyWith(isLoading: true, movies: [], searchQuery: query));

    String url = 'https://scraping.jokerapp24.com/public/api/movies/search';

    Map<String, dynamic> params = {'query': query, 'per_page': 5000};

    try {
      final response = await _dio.get(url, queryParameters: params);
      if (response.statusCode == 200) {
        final List<dynamic> moviesJson = response.data['data']['data'];
        emit(state.copyWith(
          movies: moviesJson.map((json) => AllCategories.fromJson(json)).toList(),
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(movies: [], isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(movies: [], isLoading: false));
    }
  }

  void toggleSearch() {
    final newState = !state.isSearching;
    emit(state.copyWith(isSearching: newState, isLoading: true));

    if (!newState) {
      fetchMovies('');
    }
  }
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
enum ConnectivityStatus { connected, disconnected }
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final Connectivity _connectivity = Connectivity();

  ConnectivityCubit() : super(ConnectivityStatus.connected) {
    _connectivity.onConnectivityChanged.listen((result) {
      emit(result == ConnectivityResult.none
          ? ConnectivityStatus.disconnected
          : ConnectivityStatus.connected);
    });
  }
}

//-----------------------------------------------------------------------
//-----------------------------------------------------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CategoriesCubit()..fetchMovies()),
        BlocProvider(create: (context) => AllCategoriesCubit()..fetchMovies('')),
        BlocProvider(create: (context) => ConnectivityCubit()),
      ],
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: BlocBuilder<AllCategoriesCubit, AllCategoriesState>(
            builder: (context, state) {
              return state.isSearching
                  ? TextField(
                controller: _searchController,
                autofocus: true,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.white),
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: '...ابحث',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  context.read<AllCategoriesCubit>().fetchMovies(value.trim());
                },
              )
                  : Align(
                alignment: Alignment.centerRight,
                child: const Text(
                  'الصفحه الرئيسية',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          leading:
            BlocBuilder<AllCategoriesCubit, AllCategoriesState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state.isSearching ? Icons.close : Icons.search,
                    size: 25,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    context.read<AllCategoriesCubit>().toggleSearch();
                    if (!state.isSearching) {
                      context.read<AllCategoriesCubit>().fetchMovies('');
                      _searchController.clear();
                    }
                  },
                );
              },
            ),
        ),
        body: BlocBuilder<ConnectivityCubit, ConnectivityStatus>(
          builder: (context, connectivityStatus) {
            if (connectivityStatus == ConnectivityStatus.disconnected) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const Text(
                      "فشل الاتصال",
                      style: const TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 30),
                      onPressed: () {
                        context.read<CategoriesCubit>().fetchMovies();
                        context.read<AllCategoriesCubit>().fetchMovies('');
                      },
                    ),
                  ],
                ),
              );
            } else {
              return BlocBuilder<AllCategoriesCubit, AllCategoriesState>(
                builder: (context, state) {
                  if (state.isSearching) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (state.movies.isEmpty) {
                      return const Center(
                        child: Text(
                          'No movies found',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      itemCount: state.movies.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2 / 3,
                      ),
                      itemBuilder: (context, index) {
                        final movie = state.movies[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailsScreen(movieId: movie.id),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(movie.thumbnailUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  movie.title,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return BlocBuilder<CategoriesCubit, CategoriesState>(
                      builder: (context, state) {
                        if (state is CategoriesLoading) {
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        } else if (state is CategoriesError) {
                          return Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.white,fontSize: 15,fontWeight: FontWeight.bold),
                            ),
                          );
                        } else if (state is CategoriesLoaded) {
                          return ListView(
                            children: state.categorizedMovies.entries.map((entry) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CategoryPage(categoryName: entry.key, movies: entry.value),
                                              ),
                                            );
                                          },
                                          child: const Text("المزيد", style: TextStyle(color: Colors.grey, fontSize: 15)),
                                        ),
                                        Text(
                                          entry.key,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: entry.value.length,
                                      itemBuilder: (context, index) {
                                        var movie = entry.value[index];
                                        return GestureDetector(
                                          onTap: () {
                                            if (movie["page_url"] != null) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => MovieDetailsScreen(movieId: movie["id"]),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            width: 130,
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(10),
                                              image: DecorationImage(
                                                image: NetworkImage(movie["thumbnail_url"] ?? ''),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            child: Align(
                                              alignment: Alignment.bottomCenter,
                                              child: Container(
                                                width: double.infinity,
                                                color: Colors.black.withOpacity(0.6),
                                                padding: const EdgeInsets.all(5),
                                                child: Text(
                                                  movie["title"] ?? "عنوان غير متوفر",
                                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          );
                        }
                        return const SizedBox();
                      },
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }
}
