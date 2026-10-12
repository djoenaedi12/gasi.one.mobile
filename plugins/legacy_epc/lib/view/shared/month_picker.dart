import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/provider/date_provider.dart';
import 'package:flutter/material.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime? initialDate;
  const MonthPickerDialog({Key? key, this.initialDate}) : super(key: key);

  @override
  State<StatefulWidget>  createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  DateTime _currentDate = DateTime.now();
  
  @override
  void initState(){
    super.initState();
    if(widget.initialDate != null) {
      _currentDate = widget.initialDate!;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                DateProvider.convertDate2Str(_currentDate, "MMMM yyyy"),
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 15.0,),
              buildNavigation(),
              const SizedBox(height: 15.0,),
              buildMonth(),
              const SizedBox(height: 15.0,),
              buildButtonApply()
            ],
          ),
        ),
      ),
    );
  }

  Widget buildNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year - 1, _currentDate.month, 1);
            });
          },
          child: const Icon(Icons.chevron_left),
        ),
        Text(
          DateProvider.convertDate2Str(_currentDate, "yyyy"),
          style: const TextStyle(
            fontSize: 16.0,
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year + 1, _currentDate.month, 1);
            });
          },
          child: const Icon(Icons.chevron_right),
        )
      ],
    );
  }

  Widget buildMonth() {
    return GridView.builder(
      gridDelegate:const  SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      itemBuilder: (BuildContext bc, int index) {
        DateTime dt = DateTime(_currentDate.year, index + 1, 1);
        return GestureDetector(
          onTap: () {
            setState(() {
              _currentDate = DateTime(_currentDate.year, index + 1, 1);
            });
          },
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: _currentDate.month - 1 == index ? Config.DEFAULT_COLOR : Colors.white,
              shape: BoxShape.circle
            ),
            child: Center(
              child: Text(
                DateProvider.convertDate2Str(dt, "MMM"),
                style: TextStyle(
                  color: _currentDate.month - 1 == index ? Config.DEFAULT_ACCENT_COLOR : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildButtonApply() {
    var mediaQuery = MediaQuery.of(context);
    return SizedBox(
      height: 40.0,
      width: mediaQuery.size.width,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context, _currentDate);
        },
        child: Text(
          "Apply".tr(),
          style: TextStyle(
            color: Config.DEFAULT_ACCENT_COLOR,
          ),
        ),
      ),
    );
  }
}