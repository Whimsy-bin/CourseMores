import '../controller/getx_controller.dart';
import 'package:flutter/material.dart';
import '../course_search/elastic_search.dart';
import '../course_search/search.dart' as search;
import '../course_search/search.dart';
import '../course_search/search_filter.dart';
import './carousel.dart' as carousel;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_multi_select_items/flutter_multi_select_items.dart';
import 'package:lottie/lottie.dart';
import '../auth/auth_dio.dart';

final homeController = Get.put(HomeScreenInfo());
final pageController = Get.put(PageNum());
final locationController = Get.put(LocationInfo());

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  List<Map<String, Object>> hotCourse = [];
  List<Map<String, Object>> nearCourse = [];

  Widget _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
      case '01n':
        return Lottie.asset('assets/weather_sunny.json', fit: BoxFit.fitWidth, width: 200);
      case '02d':
      case '02n':
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Lottie.asset('assets/weather_cloudy.json', fit: BoxFit.fitWidth, width: 200);
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Lottie.asset('assets/weather_rainy.json', fit: BoxFit.fitWidth, width: 200);
      case '11d':
      case '11n':
        return Lottie.asset('assets/weather_thunderstorm.json', fit: BoxFit.fitWidth, width: 200);
      case '13d':
      case '13n':
        return Lottie.asset('assets/weather_snow.json', fit: BoxFit.fitWidth, width: 200);
      case '50d':
      case '50n':
        return Lottie.asset('assets/weather_mist.json', fit: BoxFit.fitWidth, width: 200);
      default:
        return Lottie.asset('assets/weather_sunny.json', fit: BoxFit.fitWidth, width: 200);
    }
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // 권한이 거부됨
      return;
    }
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
      locationController.saveLatitude(_currentPosition?.latitude);
      locationController.saveLongitude(_currentPosition?.longitude);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getHotCourse();
    getNearCourse();
    _getCurrentLocation();
    searchController.getMainThemeList();
    print(searchController.courseList);
  }

  Future<void> getHotCourse() async {
    final tokenStorage = Get.put(TokenStorage());
    final dio = await authDio();

    final response =
        await dio.get('course/hot', options: Options(headers: {'Authorization': 'Bearer ${tokenStorage.accessToken}'}));

    List<dynamic> data = response.data['courseList'];
    hotCourse = data.map((item) => Map<String, Object>.from(item)).toList();
    homeController.saveHotCourse(hotCourse);
    setState(() {
      hotCourse = homeController.hotCourse;
    });
  }

  Future<void> getNearCourse() async {
    final tokenStorage = Get.put(TokenStorage());
    final dio = await authDio();
    final response = await dio.get(
        'course/around?latitude=${locationController.latitude}&longitude=${locationController.longitude}',
        options: Options(headers: {'Authorization': 'Bearer ${tokenStorage.accessToken}'}));

    List<dynamic> data = response.data['courseList'];
    nearCourse = data.map((item) => Map<String, Object>.from(item)).toList();
    homeController.saveNearCourse(nearCourse);
    setState(() {
      nearCourse = homeController.nearCourse;
    });
  }

  // openweathermap의 api키
  final String apiKey = dotenv.get('OPENWEATHER_API_KEY');
  final String apiBaseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<Map<String, dynamic>> getWeatherData(double lat, double lon) async {
    try {
      final dio = await authDio();
      final response = await dio.get(apiBaseUrl, queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'appid': apiKey,
        'units': 'metric',
        'lang': 'kr'
      });
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Failed to load weather data: $e');
    }
  }

  Future<Map<String, dynamic>> _getWeather() async {
    if (_currentPosition == null) {
      await _getCurrentLocation();
    }
    final lat = _currentPosition?.latitude;
    final lon = _currentPosition?.longitude;
    if (lat != null && lon != null) {
      final weatherData = await getWeatherData(lat, lon);
      return weatherData;
    }
    throw Exception('Failed to get current location');
  }

  Future<String> _getAddress(double lat, double lon) async {
    final List<geocoding.Placemark> placemarks =
        await geocoding.placemarkFromCoordinates(lat, lon, localeIdentifier: 'ko');
    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      final String address = '${placemark.subLocality} ${placemark.thoroughfare} ';
      return address;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    searchController.getThemeList();
    searchController.getSidoList();

    return Scaffold(
        body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Color.fromARGB(255, 0, 90, 129),
                  Color.fromARGB(232, 255, 218, 218),
                ],
                stops: const [0.0, 0.3],
              ),
              // image: DecorationImage(
              // image: AssetImage('assets/background-pink.jpg'),
              // image: AssetImage('assets/background.gif'),
              // image: AssetImage('assets/blue_background.gif'),
              // opacity: 1,
              // fit: BoxFit.cover),
            ),
            child: Obx(
              () => SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Center(
                          child: Column(children: [
                            FutureBuilder<Map<String, dynamic>>(
                              future: _getWeather(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final weatherData = snapshot.data!;
                                  final temp = weatherData['main']['temp'].toString();
                                  final weather = weatherData['weather'][0]['description'].toString();
                                  final iconCode = weatherData['weather'][0]['icon'].toString();
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              color: Color.fromARGB(168, 255, 255, 255),
                                              borderRadius: BorderRadius.circular(20)),
                                          padding: EdgeInsets.symmetric(vertical: 20),
                                          alignment: Alignment.bottomCenter,
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${temp.split('.')[0]} °C',
                                                style: TextStyle(fontSize: 26, color: Colors.black),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                weather,
                                                style: TextStyle(fontSize: 14, color: Colors.black),
                                              ),
                                              SizedBox(height: 16),
                                              FutureBuilder<String>(
                                                future: _getAddress(
                                                    _currentPosition?.latitude ?? 0, _currentPosition?.longitude ?? 0),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Text('검색중...');
                                                  } else if (snapshot.hasData) {
                                                    final address = snapshot.data!;
                                                    return Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.location_on, color: Colors.purple),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          address.length > 10
                                                              ? '${address.substring(0, 10)}...'
                                                              : address,
                                                          style: TextStyle(fontSize: 16, color: Colors.purple),
                                                        ),
                                                      ],
                                                    );
                                                  } else if (snapshot.hasError) {
                                                    return Text('Error: ${snapshot.error}');
                                                  } else {
                                                    return Text('');
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _getWeatherIcon(iconCode),
                                      // Expanded(
                                      //     flex: 5, child: _getWeatherIcon(iconCode)),
                                    ],
                                  );
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  return CircularProgressIndicator();
                                }
                              },
                            ),
                          ]),
                        ),
                      ),
                      buttonBar1(),
                      ButtonBar2(),
                      popularCourse(),
                      themeList(),
                      myNearCourse(),
                    ],
                  ),
                ),
              ),
            )));
  }
}

buttonBar1() {
  return Padding(
    padding: EdgeInsets.fromLTRB(0, 0, 0, 15),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.4),
                  spreadRadius: 2,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: searchButtonBar(),
          ),
        )
      ],
    ),
  );
}

class ButtonBar2 extends StatefulWidget {
  const ButtonBar2({super.key});

  @override
  State<ButtonBar2> createState() => _ButtonBar2State();
}

class _ButtonBar2State extends State<ButtonBar2> {
  var pageNum = pageController.pageNum.value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              pageController.changePageNum(1);
            },
            child: Container(
              width: 110,
              height: 80,
              decoration: boxDeco(),
              child: SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.route, color: Colors.purple, size: 30),
                    Text(
                      '코스 작성',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    )
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              pageController.changePageNum(3);
            },
            child: Container(
              width: 110,
              height: 80,
              decoration: boxDeco(),
              child: SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.star_outline, color: Colors.purple, size: 30),
                    Text('관심 목록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                  ],
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              pageController.changePageNum(4);
            },
            child: Container(
              width: 110,
              height: 80,
              decoration: boxDeco(),
              child: SizedBox(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.account_circle, color: Colors.purple, size: 30),
                    Text('마이페이지', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

iconBoxDeco() {
  return BoxDecoration(border: Border.all(color: Colors.black), borderRadius: BorderRadius.circular(10));
}

boxDeco() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.4),
        spreadRadius: 2,
        blurRadius: 3,
        offset: Offset(0, 2),
      ),
    ],
  );
}

popularCourse() {
  if (homeController.hotCourse.isEmpty) {
    return Center(child: CircularProgressIndicator());
  } else {
    return Container(
      width: double.maxFinite,
      height: 280,
      decoration: boxDeco(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
        child: SizedBox(
          height: 280.0,
          child: carousel.CourseCarousel(),
        ),
      ),
    );
  }
}

myNearCourse() {
  if (homeController.nearCourse.isEmpty) {
    return Center(child: CircularProgressIndicator());
  } else {
    return Container(
      width: double.maxFinite,
      height: 280,
      decoration: boxDeco(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 0),
        child: SizedBox(
          height: 280.0,
          child: carousel.NearCarousel(),
        ),
      ),
    );
  }
}

themeList() {
  late var themeList = searchController.homeThemeList;

  return Padding(
    padding: EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
    child: Container(
      clipBehavior: Clip.hardEdge,
      width: double.maxFinite,
      decoration: boxDeco(),
      child: Center(
        child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 25),
                  child: Text(
                    '이런 테마는 어때요? 😊',
                    style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 25),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.start,
                    textDirection: TextDirection.ltr,
                    runAlignment: WrapAlignment.start,
                    verticalDirection: VerticalDirection.down,
                    clipBehavior: Clip.none,
                    children: themeList.map((theme) {
                      return InkWell(
                        onTap: () {
                          pageController.changePageNum(2);
                          search.Search();
                          searchController.queryParameters['themeIds'] = [theme['themeId']];
                          searchController.isSearchResults.value = true;
                          searchController.changePage(page: 0);
                          searchController.searchCourse();
                          search.Search();
                        },
                        child: Container(
                          margin: EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Text(
                              theme['name'],
                              style: TextStyle(color: Colors.black, fontSize: 12.0),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            )),
      ),
    ),
  );
}

emptyTheTextFormField() {
  searchTextEditingController.clear();
}

controlSearching(str) {}

searchButtonBar() {
  return SizedBox(
    height: 45,
    child: TextFormField(
      textAlignVertical: TextAlignVertical.center,
      controller: searchTextEditingController,
      onTap: () => Get.to(SearchScreen()),
      onChanged: (value) {
        searchController.changeWord(word: searchTextEditingController.text);
      },
      decoration: InputDecoration(
        hintText: "코스, 장소, 해시태그 등을 검색해보세요",
        hintStyle: TextStyle(color: Color.fromARGB(152, 144, 59, 159), fontSize: 12, height: 2),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
        prefixIcon: IconButton(
            icon: Icon(Icons.tune),
            color: Colors.purple,
            iconSize: 25,
            onPressed: () {
              Get.to(() => SearchFilter());
            }),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.clear),
              color: Colors.purple,
              visualDensity: VisualDensity.comfortable,
              onPressed: () {
                searchTextEditingController.clear();
                searchController.changeWord(word: '');
                searchController.getElasticList();
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              color: Colors.purple,
              iconSize: 25,
              padding: EdgeInsets.symmetric(horizontal: 0),
              onPressed: () {
                Get.back();
                pageController.changePageNum(2);
                searchController.isSearchResults.value = true;
                searchController.changePage(page: 0);
                searchController.searchCourse();
              },
            ),
          ],
        ),
      ),
      style: TextStyle(fontSize: 14, color: Colors.black),
      onFieldSubmitted: controlSearching,
    ),
  );
}
