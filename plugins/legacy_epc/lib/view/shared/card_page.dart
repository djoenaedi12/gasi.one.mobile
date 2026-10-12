import 'package:flutter/material.dart';

class CardPage extends StatefulWidget {
  final List<dynamic> list;
  final Function(dynamic, int)? renderTitle;
  final Function(dynamic, int)? renderHeader;
  final Function(dynamic, int)? renderBody;
  final bool expanded;
  final ScrollPhysics physics;
  final Color? color;
  const CardPage({Key? key, this.list = const [], this.renderHeader, this.renderTitle, this.renderBody, this.expanded= false, this.physics= const AlwaysScrollableScrollPhysics(), this.color}):super(key: key);

  @override
  State<StatefulWidget> createState() => _CardPageState();
}

class _CardPageState extends State<CardPage> {

  List<bool> expanded = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: widget.list.length,
      physics: widget.physics,
      itemBuilder: (BuildContext bc, int index) {
        expanded.add(widget.expanded);
        var data = widget.list[index];
        return Card(
          color: Colors.white,
          elevation: 1.5,
          child: SizedBox(
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      expanded[index] = !expanded[index];
                    });
                  },
                  child: widget.renderHeader != null 
                  ? widget.renderHeader!(data, index)
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          widget.renderTitle != null
                            ? widget.renderTitle!(data, index)
                            : const SizedBox(),
                            Icon(
                              !expanded[index] ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              size: 25.0, 
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                ),
                Visibility(
                  visible: expanded[index],
                  child: Container(
                    color: widget.color ?? Colors.white,
                    child: Column(
                      children: [
                        Divider(height: 1, color: Colors.grey.shade300),
                        widget.renderBody != null 
                        ? widget.renderBody!(data, index)
                        : const SizedBox(),
                      ],
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