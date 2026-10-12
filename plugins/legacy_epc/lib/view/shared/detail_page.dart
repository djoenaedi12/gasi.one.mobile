import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final Function(dynamic, int)? onEdit;
  final Function(int)? onDelete;
  final Function()? onTap;
  final List<dynamic> itemList;
  final Function(dynamic, int)? renderTitle;
  final Function(dynamic, int)? renderBody;
  final String title;
  final bool isEditable;
  final bool expended;
  final Function(dynamic, int)? isEditableForm;
  final bool canAdd;
  final bool canDelete;
  final bool canEdit;
  const DetailPage({Key? key, this.onDelete, this.onEdit, this.itemList = const [], this.onTap, this.renderTitle, this.title = "", this.isEditable= true, this.renderBody, this.expended= false, this.isEditableForm, this.canAdd = true, this.canEdit = true, this.canDelete = true}): super(key: key);
  
  @override
  State<StatefulWidget> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {

  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            left: 10.0,
            right: 10.0,
            top: 10.0,
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () {
                  if(!widget.isEditable || !widget.canAdd) return;
                  widget.onTap!();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Visibility(
                          visible: widget.isEditable && widget.canAdd,
                          child: Icon(
                            Icons.add_circle,
                            color: Config.DEFAULT_COLOR,
                          ),
                        ),
                        SizedBox(
                          width: widget.isEditable && widget.canAdd ? 5.0 : 0.0,
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),    
                  ],
                ),
              ),
              const SizedBox(
                height: 15.0,
              ),
              Divider(height: 1, color: Colors.grey.shade300),
            ],
          ),
        ),
        Container(
          constraints: const BoxConstraints(
            minHeight: 100,
          ),
          color: Colors.grey[200],
          padding: const EdgeInsets.all(
            5.0,
          ),
          child: Column(
            mainAxisAlignment: widget.itemList.isEmpty
            ? MainAxisAlignment.center 
            : MainAxisAlignment.start,
            children: <Widget>[
              widget.itemList.isEmpty
              ? Center(
                child: Text(
                  "No Data Found".tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.itemList.length,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 3.0,
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    expanded.add(widget.expended);
                    dynamic item = widget.itemList[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(5),
                          topRight: Radius.circular(5),
                          bottomLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                expanded[index] = !expanded[index];
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: widget.renderTitle != null 
                                      ? widget.renderTitle!(item, index)
                                      : const SizedBox()
                                  ),
                                ),
                                widget.isEditable && (widget.isEditableForm != null ? widget.isEditableForm!(item, index) : widget.isEditable)
                                ? _morePopup(item, index)
                                : Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Icon(
                                      !expanded[index] 
                                        ? Icons.arrow_drop_up 
                                        : Icons.arrow_drop_down,
                                      size: 25.0, 
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Visibility(
                            visible: expanded[index],
                            child: Column(
                              children: [
                                Divider(height: 1, color: Colors.grey.shade300),
                                widget.renderBody != null 
                                ? widget.renderBody!(item, index)
                                : const SizedBox()
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _morePopup(dynamic item, int index) {
    if(widget.canEdit && widget.canDelete) {
      return PopupMenuButton<int> (
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 1,
            child: Row(
              children: <Widget>[
                const Icon(Icons.edit),
                const SizedBox(
                  width: 5.0,
                ),
                Text("Edit".tr()),
              ],
            ),
          ),
          PopupMenuItem(
            value: 2,
            child: Row(
              children: <Widget>[
                const Icon(Icons.delete),
                const SizedBox(
                  width: 5.0,
                ),
                Text("Delete".tr()),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 1) {
            widget.onEdit!(item, index);
          } else {
            widget.onDelete!(index);
          }
        },
        icon: const Icon(Icons.more_vert),
      );
    } else if(widget.canEdit) {
      return PopupMenuButton<int> (
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 1,
            child: Row(
              children: <Widget>[
                const Icon(Icons.edit),
                const SizedBox(
                  width: 5.0,
                ),
                Text("Edit".tr()),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 1) {
            widget.onEdit!(item, index);
          } else {
            widget.onDelete!(index);
          }
        },
        icon: const Icon(Icons.more_vert),
      );
    } else if(widget.canDelete) {
      return PopupMenuButton<int> (
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 2,
            child: Row(
              children: <Widget>[
                const Icon(Icons.delete),
                const SizedBox(
                  width: 5.0,
                ),
                Text("Delete".tr()),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 1) {
            widget.onEdit!(item, index);
          } else {
            widget.onDelete!(index);
          }
        },
        icon: const Icon(Icons.more_vert),
      );
    }

    return const SizedBox();
  }
}