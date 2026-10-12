
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class TransactionTabItemPage extends StatefulWidget {
  
  const TransactionTabItemPage({
    Key? key,
    required this.onLoading,
    required this.onRefresh,
    required this.renderItem,
    required this.onTapItem,
    required this.data,
    this.enabledPullUp = false,
    this.index = 0,
    this.isLoading = false,
  }): super(key: key);

  final Function onRefresh;
  final Function onLoading;
  final Widget Function(dynamic, int) renderItem;
  final Function(dynamic, int) onTapItem;
  final List<dynamic> data;
  final bool enabledPullUp;
  final int index;
  final bool isLoading;

  @override
  State<StatefulWidget>  createState() => _TransactionTabItemPageState();
}

class _TransactionTabItemPageState extends State<TransactionTabItemPage> {
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  void _onRefresh() async {
    try {
      await widget.onRefresh();
    } catch (e) {
      //
    }
    _refreshController.refreshCompleted();
  }

  void _onLoading() async {
    try {
      await widget.onLoading();
    } catch (e) {
      //
    }
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  Widget _renderItem(item) {
    return widget.renderItem(item, widget.index);
  }

  _onTapItem(item) {
    try {
      widget.onTapItem(item, widget.index);
    } catch (e) {
      //
    }
  }

  @override
  Widget build(BuildContext context) {
    return SmartRefresher(
      controller: _refreshController,
      enablePullDown: true,
      enablePullUp: widget.enabledPullUp,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      header: const ClassicHeader(),
      footer: CustomFooter(
        builder: (context, mode) {
          Widget? body;
          if (mode == LoadStatus.loading) {
            body = CircularProgressIndicator(valueColor:AlwaysStoppedAnimation<Color>(Config.DEFAULT_COLOR));
          }
          return SizedBox(
            height: body != null ? 50.0 : 0.0,
            child: Center(child: body),
          );
        },
      ),
      child: widget.data.isEmpty
        ? widget.isLoading 
          ? Column(
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
            )
          : Center(
            child: Text(
              "No Data Found".tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
          )
        : ListView.separated(
          itemCount: widget.data.length,
          separatorBuilder: (BuildContext context, int index) {
            return Divider(
              height: 1.0,
              color: Colors.grey.shade300
            );
          },
          itemBuilder: (BuildContext context, int index) {
            var item = widget.data[index];
            return InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                _onTapItem(item);
              },
              child: _renderItem(item),
            );
          },
        ),
    );
  }
}
