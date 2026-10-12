import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/module.dart';
import 'package:epeoplecare/view/shared/menu.dart';
import 'package:flutter/material.dart';

class TransactionPage extends StatelessWidget {
  
  const TransactionPage({
    Key? key,
    this.onHeaderMenuPress,
    this.headerMenu = const [],
    this.createNewMenu = const [],
    this.onCreateNewMenuPress,
    this.menuModules,
  }) : super(key: key) ;

  final List<Menu> headerMenu;
  final List<Menu> createNewMenu;
  final ValueChanged? onHeaderMenuPress;
  final ValueChanged? onCreateNewMenuPress;
  final List<Module>? menuModules;

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 5.0,
          ),
          width: mediaQuery.size.width,
          height: 100.0,
          color: Config.DEFAULT_COLOR,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: headerMenu.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  if(onHeaderMenuPress != null) {
                    onHeaderMenuPress!(index);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 7.5, 
                    right: 7.5,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        headerMenu[index].icon,
                        size: 45.0,
                        color: Config.DEFAULT_ACCENT_COLOR,
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Expanded(
                        child: Text(
                          headerMenu[index].title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Config.DEFAULT_ACCENT_COLOR,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 15.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create New".tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                ),
              ),
              Divider(
                color: Config.DEFAULT_COLOR.withValues(alpha: 0.3),
              ),
              SizedBox(
                height: 100.0,
                width: mediaQuery.size.width,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: createNewMenu.length,
                  itemBuilder: (BuildContext context, int index) {
                    return GestureDetector(
                      onTap: () {
                        if(onCreateNewMenuPress != null) {
                          onCreateNewMenuPress!(index);
                        }
                      },
                      child: SizedBox(
                        width: 115.0,
                        child: Column(
                          children: [
                            Icon(
                              createNewMenu[index].icon,
                              size: 45.0,
                              color: Config.DEFAULT_COLOR,
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                            Text(
                              createNewMenu[index].title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              buildOthers(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildOthers(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Others".tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16.0,
          ),
        ),
        Divider(
          color: Config.DEFAULT_COLOR.withValues(alpha: 0.3),
        ),
        SizedBox(
          height: 100.0,
          width: mediaQuery.size.width,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: menuModules!.length,
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: menuModules![index].onTap,
                child: SizedBox(
                  width: 115.0,
                  child: Column(
                    children: [
                      Icon(
                        menuModules![index].icon,
                        size: 45.0,
                        color: Config.DEFAULT_COLOR,
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      Text(
                        menuModules![index].title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
