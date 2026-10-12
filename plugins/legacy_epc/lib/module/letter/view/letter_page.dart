import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/letter/model/letter.dart';
import 'package:epeoplecare/module/letter/model/letter_type.dart';
import 'package:epeoplecare/module/letter/repository/letter_repository.dart';
import 'package:epeoplecare/module/letter/view/letter_filter.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:epeoplecare/provider/storage_provider.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;

class LetterPage extends StatefulWidget {
  final String title;
  final IconData? icon;
  const LetterPage({super.key, this.title="", this.icon});

  @override
  State<StatefulWidget> createState() => _LetterPageState();
}

class _LetterPageState extends State<LetterPage> {

  Map<String, dynamic> filters = HashMap();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<Letter> _letters = Pagination();
  final LetterRepository _letterRepository = Repository().getLetterRepository();
  List<Sort> sorts = [Sort("id", SortDirection.DESC)];
  DateTime? _dateFrom;
  DateTime? _dateTo;
  LetterType? _letterType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }
  
  _initData() {
    filters.putIfAbsent("employee", () => Config.user!.employee!.id);
    _letterRepository.listPagination(page: _currentPage, sorts: sorts, parameters: filters).then((value) {
      EasyLoading.dismiss();
      setState(() {
        _letters = value;
        _isLoading = false;
      });
    }).catchError((onError) {
        setState(() {
          _isLoading = false;
        });
    });
  }

  void _onRefresh() async {
    setState(() {
      _currentPage = 0;
    });
    _initData();
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    setState(() {
      _currentPage = _currentPage + 1;
    });
    filters.putIfAbsent("employee", () => Config.user!.employee!.id);
    await _letterRepository.listPagination(page: _currentPage, sorts: sorts, parameters: filters).then((value) {
      for (var item in value.content) {
        setState(() {
          _letters.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  _onTapItem(int index) {
    Letter letter = _letters.content[index];
    urlFileShare(letter);
  }

  _filterRecord() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext bc) {
        return LetterFilter(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          letterType: _letterType,
        );
      }
    ).then((value) {
      if (value == null) return;

      setState(() {
        filters.clear();
        _currentPage = 0;
        if(value['dateFrom'] != null && value['dateFrom'] != "") {
          _dateFrom = value['dateFrom'];
          filters.putIfAbsent("issuedDate.gte", () => DateProvider.convertDate2Str(_dateFrom, "yyyy-MM-dd"));
        } else {
          _dateFrom = null;
        }

        if(value['dateTo'] != null && value['dateTo'] != "") {
          _dateTo = value['dateTo'];
          filters.putIfAbsent("issuedDate.lte", () => DateProvider.convertDate2Str(_dateTo, "yyyy-MM-dd"));
        } else {
          _dateTo = null;
        }

        if(value['letterType'] != null && value['letterType'] != "") {
          _letterType = value['letterType'];
          filters.putIfAbsent("letterType", () => _letterType!.id);
        } else {
          _letterType = null;
        }
      });
      

      EasyLoading.show(status: "Please Wait".tr());
      _initData();
    });
  }

  urlFileShare(Letter? letter) {
    if(letter == null || letter.filePath == null || letter.filePath == "") return;

    EasyLoading.show(status: "Please Wait".tr());
    List<int> ids = [letter.id ?? 0];
    _letterRepository.print(ids).then((value) async {
      EasyLoading.dismiss();
      if(value != null) {
        String dir = await StorageProvider().getExternalStorage();
        String ext = p.extension(letter.filePath ?? "");
        String fileName = '${letter.letterType!.name}_${letter.employee!.code}$ext';
        File file = File('$dir/$fileName');
        await file.writeAsBytes(value);
        final box = context.findRenderObject() as RenderBox?;
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            sharePositionOrigin: box == null
                ? null
                : box.localToGlobal(Offset.zero) & box.size,
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagePage(
              icon: const Icon(Icons.error, size: 100, color: Colors.red),
              title: "Error".tr(),
              subTitle: "No Data Found".tr(),
            ),
          ),
        );
      }
    }).catchError((onError){
      EasyLoading.dismiss();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessagePage(
            icon: const Icon(Icons.error, size: 100, color: Colors.red),
            title: "Error".tr(),
            subTitle: onError.toString(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: Config.DEFAULT_ACCENT_COLOR,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SmartRefresher(
            controller: _refreshController,
            enablePullUp: _letters.totalPages - _currentPage > 1,
            enablePullDown: true,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            header: const ClassicHeader(),
            footer: CustomFooter(
              builder: (context, mode) {
                Widget? body;
                if (mode == LoadStatus.loading) {
                  body = const CircularProgressIndicator();
                }
                return SizedBox(
                  height: body != null ? 50.0 : 0.0,
                  child: Center(child: body),
                );
              },
            ),
            child: buildData(),
          ),
          Positioned(
            bottom: 30.0,
            left: (size.width / 2) - 50,
            child: GestureDetector(
              onTap: _filterRecord,
              child: Container(
                padding: const EdgeInsets.all(5.0),
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      30.0,
                    )
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Icon(
                          Icons.filter_list_alt,
                          color: Config.DEFAULT_COLOR,
                        ),
                        Visibility(
                          visible: _dateFrom != null || _dateTo != null || _letterType != null,
                          child: Positioned(
                            top: 2.0,
                            right: 0.0,
                            child: Container(
                              width: 9.0,
                              height: 9.0,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 5.0),
                    Text(
                      "Filter".tr(),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildData() {
    if(_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Platform.isAndroid
          ? CircularProgressIndicator(valueColor:AlwaysStoppedAnimation<Color>(Config.DEFAULT_COLOR))
          : const CupertinoActivityIndicator(),
          const SizedBox(height: 15.0),
          Text(
            "Please Wait".tr(),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    if(_letters.content.isEmpty) {
      return Center(
        child: Text(
          "No Data Found".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _letters.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        var letter = _letters.content[index];
        return GestureDetector(
          onTap: () {
            _onTapItem(index);
          },
          child: Container(
            color: Colors.white,
            margin: EdgeInsets.only(
              top: index == 0 ? 10.0 : 5.0,
              left: 10.0,
              right: 10.0,
              bottom: 10.0,
            ),
            padding: const EdgeInsets.all(
              7.0,
            ),
            child: Row(
              children: [
                Text(
                  letter.letterType!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Text(
                  DateProvider.convertDateStrFormat(letter.issuedDate, "yyyy-MM-dd", "dd MMM yyyy"),
                ),
                const SizedBox(width: 5.0),
                Expanded(
                  child: Text(
                    letter.description ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}