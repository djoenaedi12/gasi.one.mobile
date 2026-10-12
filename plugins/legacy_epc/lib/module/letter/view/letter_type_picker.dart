import 'dart:collection';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/pagination.dart';
import 'package:epeoplecare/model/sort.dart';
import 'package:epeoplecare/model/sort_direction.dart';
import 'package:epeoplecare/module/letter/model/letter_type.dart';
import 'package:epeoplecare/module/letter/repository/letter_type_repository.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class LetterTypePicker extends StatefulWidget {
  final LetterType? letterType;
  final Map<String, dynamic>? paramaters;
  const LetterTypePicker({Key? key, this.letterType, this.paramaters}):super(key: key);
  @override
  State<StatefulWidget>  createState() => _LetterTypePickerState();
}

class _LetterTypePickerState extends State<LetterTypePicker> {

  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  int _currentPage = 0;
  Pagination<LetterType> _letterTypes = Pagination();
  final LetterTypeRepository _letterTypeRepository  = Repository().getLetterTypeRepository();
  List<Sort> sorts = [Sort("name", SortDirection.ASC)];
  Map<String, dynamic> paramaters = HashMap();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData(_currentPage);
  }

  _initData(int page) {
    if(widget.paramaters != null) {
      widget.paramaters!.forEach((key, value) { 
        paramaters.putIfAbsent(key, () => value);
      });
    }
    _letterTypeRepository.listPaginationReference(page: page,sorts: sorts, parameters: paramaters).then((value) {
      setState(() {
        _letterTypes = value;
        _isLoading = false;
      });
    });
  }

  void _onRefresh() async {
    setState(() {
      _currentPage = 0;
    });
    await _initData(_currentPage);
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    setState(() {
      _currentPage = _currentPage + 1;
    });
    if(widget.paramaters != null) {
      widget.paramaters!.forEach((key, value) { 
        paramaters.putIfAbsent(key, () => value);
      });
    }
    
    await _letterTypeRepository.listPagination(page: _currentPage, sorts: sorts, parameters: paramaters).then((value) {
      for (var item in value.content) {
        setState(() {
          _letterTypes.add(item);          
        });
      }
    });
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Config.DEFAULT_COLOR,
        iconTheme: IconThemeData(
          color: Config.DEFAULT_ACCENT_COLOR,
        ),
        title: Text(
          "Letter Type".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
              ),
              child: TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(
                      Icons.search,
                      color: Config.DEFAULT_COLOR,
                    ),
                  ),
                  border: InputBorder.none,
                  hintText: "Search".tr(),
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onFieldSubmitted: (val) {
                  setState(() {
                    if(val != "") {
                      paramaters['name.like'] = val;
                    } else {
                      paramaters.clear();
                    }
                    _currentPage = 0;
                  });

                  _initData(_currentPage);
                },
              ),
            ),
          ),
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              enablePullDown: true,
              enablePullUp: _letterTypes.totalPages - _currentPage > 1,
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
      
    if(_letterTypes.content.isEmpty) {
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
      itemCount: _letterTypes.content.length,
      separatorBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.0),
          child: Divider(color: Colors.grey.shade300),
        );
      },
      itemBuilder: (BuildContext context, int index) {
        LetterType letterType = _letterTypes.content[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop(letterType);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0, 
              horizontal: 10.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    letterType.name,
                    style: const TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.check,
                  color: widget.letterType != null && widget.letterType!.id == letterType.id ? Config.DEFAULT_COLOR : Colors.white,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}