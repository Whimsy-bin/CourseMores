import 'package:coursemores/controller/make_controller.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditItemPage2 extends StatefulWidget {
  const EditItemPage2({Key? key, required this.locationData}) : super(key: key);

  final LocationData locationData;

  @override
  State<EditItemPage2> createState() =>
      // ignore: no_logic_in_create_state
      _EditItemPage2State(locationData: locationData);
}

class _EditItemPage2State extends State<EditItemPage2> {
  final GlobalKey<_AddImageState> _addImageKey = GlobalKey();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _sidoController = TextEditingController();
  final TextEditingController _gugunController = TextEditingController();
  bool isImageUploadEnabled = false; // AddImage 위젯의 활성화/비활성화 상태를 관리하기 위한 변수

  late LocationData _itemData;
  final LocationData locationData;

  @override
  void initState() {
    super.initState();
    // ignore: unused_local_variable
    final LocationController locationController = Get.find();
    _itemData = locationData;
    _titleController.text = _itemData.title ?? '';
    _contentController.text = _itemData.content ?? '';
    _sidoController.text = _itemData.sido;
    _gugunController.text = _itemData.gugun;

    // 이곳에서 저장된 이미지 목록을 불러옵니다.
    // ignore: unused_local_variable
    List<XFile> savedImages = _itemData.getSavedImageList();
    if (_addImageKey.currentState != null) {
      // Make sure currentState is not null before calling getTemporaryImageList
      locationData.saveImageList(_addImageKey.currentState!
          .getTemporaryImageList()); // Save images in initState
    }
  }

  _EditItemPage2State({required this.locationData}) {
    _itemData = locationData;
    isImageUploadEnabled = false; // isImageUploadEnabled를 false로 초기화
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final CourseController courseController = Get.find();
    final LocationController locationController = Get.find();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 80, 170, 208),
        // 없어도 <- 모양의 뒤로가기가 기본으로 있으나 < 모양으로 바꾸려고 추가함
        leading: IconButton(
          icon: Icon(Icons.navigate_before, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // 알림 아이콘과 텍스트 같이 넣으려고 RichText 사용
        title: Center(
          child: RichText(
              text: const TextSpan(
            children: [
              // WidgetSpan(child: Icon(Icons.edit_note, color: Colors.black)),
              WidgetSpan(child: SizedBox(width: 5)),
              TextSpan(
                text: '장소 추가 정보 작성',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ],
          )),
        ),
        // 피그마와 모양 맞추려고 close 아이콘 하나 넣어둠
        // <와 X 중 하나만 있어도 될 것 같아서 상의 후 삭제 필요
        actions: [
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close, color: Colors.white)),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          // height: double.infinity,
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PlaceName(
                locationName: widget.locationData.name,
                latitude: widget.locationData.latitude,
                longitude: widget.locationData.longitude,
              ),
              // Text('수정할 Item: ${widget.item.title}'),
              SizedBox(height: 10),
              // AddImage(),
              // Toggle 버튼 추가
              Center(
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isImageUploadEnabled =
                              !isImageUploadEnabled; // 토글 버튼의 상태 변경
                        });
                        print(isImageUploadEnabled);
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Color.fromARGB(255, 119, 181, 212)), // 버튼의 배경색을 설정
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          // 버튼의 모양을 둥글게 만듭니다
                          RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30.0), // 둥근 모서리의 반경을 설정
                          ),
                        ),
                      ),
                      child:
                          Text(isImageUploadEnabled ? '기존 사진 유지' : '사진 수정하기'),
                    ),
                    SizedBox(
                      height: 10,
                    )
                    // Text(
                    //   '기존에 ${locationController.numberOfImage.value}장의 사진이 있습니다.',
                    //   style: TextStyle(
                    //     fontSize: 16,
                    //     color: Colors.black,
                    //   ),
                    // ),
                  ],
                ),
              ),
              // AddImage 위젯에 isUpdate 값을 전달하여 상태를 제어
              if (isImageUploadEnabled)
                AddImage(
                  key: _addImageKey,
                  locationData: widget.locationData,
                  isUpdate: isImageUploadEnabled, // 동적으로 isUpdate 값을 변경
                ),
              SizedBox(height: 20),
              AddTitle(titleController: _titleController),
              SizedBox(height: 20),
              // AddText(textController: _textController),
              AddText(contentController: _contentController),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  List<XFile> imageList = [];
                  if (isImageUploadEnabled &&
                      _addImageKey.currentState != null) {
                    imageList =
                        _addImageKey.currentState!.getTemporaryImageList();
                  } else {
                    // 이미지를 수정하지 않는 경우 이전의 이미지 리스트를 사용
                    imageList = _itemData.getSavedImageList();
                  }

                  final updatedLocationData = LocationData(
                    key: widget.locationData.key,
                    courseLocationId: widget.locationData.courseLocationId,
                    name: widget.locationData.name,
                    latitude: widget.locationData.latitude,
                    longitude: widget.locationData.longitude,
                    roadViewImage: widget.locationData.roadViewImage,
                    isUpdate:
                        isImageUploadEnabled, // isUpdate 값을 isImageUploadEnabled 값으로 변경
                    numberOfImage: imageList.length,
                    title: _titleController.text.isNotEmpty
                        ? _titleController.text
                        : '',
                    content: _contentController.text.isNotEmpty
                        ? _contentController.text
                        : '',
                    sido: widget.locationData.sido,
                    gugun: widget.locationData.gugun,
                    temporaryImageList: imageList,
                  );
                  _itemData.title = updatedLocationData.title;
                  _itemData.content = updatedLocationData.content;
                  _itemData.sido = updatedLocationData.sido;
                  _itemData.gugun = updatedLocationData.gugun;
                  _itemData.numberOfImage = updatedLocationData.numberOfImage;

                  _itemData.saveImageList(imageList);

                  _itemData = updatedLocationData;

                  locationController.updateLocationData(updatedLocationData);
                  // 프린트 테스트 for images
                  print('33333333333333');
                  print(_itemData.numberOfImage);
                  print(_itemData.temporaryImageList);
                  print(_itemData.isUpdate);
                  //
                  Navigator.pop(context, updatedLocationData);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      Color.fromARGB(255, 119, 181, 212)), // 버튼의 배경색을 설정
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    // 버튼의 모양을 둥글게 만듭니다
                    RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30.0), // 둥근 모서리의 반경을 설정
                    ),
                  ),
                ),
                child: Text("저장하기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaceName extends StatefulWidget {
  const PlaceName({
    Key? key,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  final String locationName;
  final double latitude;
  final double longitude;

  @override
  State<StatefulWidget> createState() => _PlaceNameState();
}

class _PlaceNameState extends State<PlaceName> {
  late String _address;
  late String _imgUrl;
  final String _apiKey = dotenv.get('GOOGLE_MAP_API_KEY');

  @override
  void initState() {
    super.initState();
    _getAddress();
    _imgUrl =
        "https://maps.googleapis.com/maps/api/streetview?size=400x400&location=${widget.latitude},${widget.longitude}&fov=90&heading=235&pitch=10&key=$_apiKey";
  }

  Future<void> _getAddress() async {
    final List<geocoding.Placemark> placemarks = await geocoding
        .placemarkFromCoordinates(widget.latitude, widget.longitude,
            localeIdentifier: 'ko');

    if (placemarks.isNotEmpty) {
      final geocoding.Placemark place = placemarks.first;
      final String thoroughfare = place.thoroughfare ?? '';
      final String subThoroughfare = place.subThoroughfare ?? '';
      final String locality = place.locality ?? '';
      final String subLocality = place.subLocality ?? '';
      final String administrativeArea = place.administrativeArea ?? '';

      setState(() {
        _address =
            '$administrativeArea $locality $subLocality $thoroughfare $subThoroughfare';
      });
    } else {
      setState(() {
        _address = '주소를 가져올 수 없습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '장소 상세 내용',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        FractionallySizedBox(
          widthFactor: 0.95,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text(
                        widget.locationName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8),
                      // Text(_address),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(_address),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      image: DecorationImage(
                        // image: AssetImage('assets/img1.jpg'),
                        image: NetworkImage(_imgUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AddTitle extends StatelessWidget {
  const AddTitle({
    super.key,
    required TextEditingController titleController,
  }) : _titleController = titleController;

  final TextEditingController _titleController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("요약 정보 (25자 이내)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
        SizedBox(height: 10),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // 그림자 위치 조절
              ),
            ],
          ),
          padding: EdgeInsets.all(10),
          child: TextField(
            maxLength: 25,
            maxLines: null, // 여러 줄 입력 가능
            controller: _titleController,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '장소에 대해 간략히 설명',
              prefixText: ' ',
              prefixStyle: TextStyle(color: Colors.transparent),
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}

class AddText extends StatelessWidget {
  const AddText({
    super.key,
    required TextEditingController contentController,
  }) : _contentController = contentController;

  final TextEditingController _contentController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "장소에 대한 설명 📝",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: 200,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(10),
            child: TextField(
              controller: _contentController,
              maxLength: 5000,
              maxLines: null,
              expands: true, // TextField의 높이를 가능한 한 최대로 확장
              minLines: null, // 최소 줄 수를 지정하지 않음
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '최대 5000자까지 작성할 수 있어요',
                prefixText: ' ',
                prefixStyle: TextStyle(color: Colors.transparent),
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AddImage extends StatefulWidget {
  const AddImage(
      {Key? key,
      this.locationData,
      required this.isUpdate // Assuming locationData is optional. If it's required, change this to 'required this.locationData'.
      })
      : super(key: key);

  final LocationData? locationData;
  final bool isUpdate;
  // final LocationData locationData; // Added locationData

  @override
  State<AddImage> createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {
  final GlobalKey<_ImageUploaderState> _imageUploaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.locationData != null) {
      // Check if locationData is not null
      _imageUploaderKey.currentState?.initializeImageList(widget.locationData!
          .getSavedImageList()); // Make sure currentState is not null before calling initializeImageList
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.95,
      child: Card(
        elevation: 4, // 그림자 높이
        shape: RoundedRectangleBorder(
          // 모서리 둥글기 설정
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Text("이미지를 첨부해보세요 📷",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                )),
            SizedBox(height: 10),
            Text("이미지는 최대 5장까지 첨부할 수 있어요",
                style: TextStyle(color: Colors.black45)),
            SizedBox(height: 10),
            // 활성화/비활성화 상태에 따라
            SizedBox(
              child: widget.isUpdate
                  ? ImageUploader(key: _imageUploaderKey)
                  : _buildDisabledButton(),
            ),
            // SizedBox(
            //   // height: 250,
            //   child: ImageUploader(key: _imageUploaderKey),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledButton() {
    return ElevatedButton(
      onPressed: null, // 버튼을 비활성화합니다.
      child: Text("이미지 업로드 비활성화"),
    );
  }

  // List<XFile> get temporaryImageList =>
  //     _imageUploaderKey.currentState!._temporaryImageList;
  List<XFile> getTemporaryImageList() {
    return _imageUploaderKey.currentState!._temporaryImageList;
  }
}

// 5개까지만 선택 가능하고 그 이상은 동작하지 않고, 카메라로 찍기, 선택된 사진 취소도 가능한 코드
class ImageUploader extends StatefulWidget {
  // const ImageUploader({super.key});
  const ImageUploader({Key? key}) : super(key: key);

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final List<XFile> _temporaryImageList = []; // 수정된 부분
  final picker = ImagePicker();
  final int maxImageCount = 5; // 최대 업로드 가능한 이미지 수

  void initializeImageList(List<XFile> savedImageList) {
    // Added method to initialize image list
    _temporaryImageList.addAll(savedImageList);
  }

  int getNumberOfImage() {
    return _temporaryImageList.length;
  }

  Future getImage() async {
    // ignore: deprecated_member_use
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        if (_temporaryImageList.length < maxImageCount) {
          // _temporaryImageList.add(File(pickedFile.path));
          _temporaryImageList.add(XFile(pickedFile.path));
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("최대 이미지 개수 초과"),
              content: Text("이미지는 최대 $maxImageCount개까지만 업로드 가능해요."),
              actions: <Widget>[
                TextButton(
                  child: Text("확인"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        }
      } else {
        print('선택된 이미지가 없어요.');
      }
    });
    // Update numberOfImage to match the length of _temporaryImageList.
    final LocationController locationController = Get.find();
    locationController.numberOfImage.value = _temporaryImageList.length;
    print(_temporaryImageList);
  }

  void _removeImage(int index) {
    setState(() {
      _temporaryImageList.removeAt(index);
    });

    // Update numberOfImage to match the length of _temporaryImageList.
    final LocationController locationController = Get.find();
    locationController.numberOfImage.value = _temporaryImageList.length;
    print(_temporaryImageList);
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 5,
      children: List.generate(_temporaryImageList.length, (index) {
        return Stack(
          children: [
            Container(
              // width: double.infinity,
              margin: EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  // image: FileImage(_temporaryImageList[index]),
                  image: FileImage(File(_temporaryImageList[index].path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: InkWell(
                onTap: () => _removeImage(index),
                child: Container(
                  margin: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final imageFile = await picker.pickImage(source: ImageSource.camera);
    if (imageFile == null) return;

    setState(() {
      // _temporaryImageList.add(File(imageFile.path));
      _temporaryImageList.add(imageFile);
    });

    // Update numberOfImage to match the length of _temporaryImageList.
    final LocationController locationController = Get.find();
    locationController.numberOfImage.value = _temporaryImageList.length;

    print('7777777777777777777777');
    print(_temporaryImageList);
    print(locationController.numberOfImage);
    // print(locationController._temporaryImageList);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              if (_temporaryImageList.length < 5) {
                _showSelectionDialog(context);
              } else {
                Fluttertoast.showToast(
                  msg: "5개까지만 업로드 가능해요.",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                );
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('5개까지만 업로드 가능해요.')),
                // );
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 119, 181, 212)), // 버튼의 배경색을 설정
              shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                // 버튼의 모양을 둥글게 만듭니다
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // 둥근 모서리의 반경을 설정
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.image),
                SizedBox(width: 8),
                Text('이미지 첨부하기'),
              ],
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: _temporaryImageList.isEmpty
                ? Center(child: Text("이미지를 선택해주세요."))
                : buildGridView(),
          ),
        ],
      ),
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('이미지 선택'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _takePicture();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const <Widget>[
                  Icon(Icons.camera_alt, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('카메라'),
                ],
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                getImage();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: const <Widget>[
                  Icon(Icons.image, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('갤러리'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
