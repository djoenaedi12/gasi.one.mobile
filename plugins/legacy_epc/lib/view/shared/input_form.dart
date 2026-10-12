import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/dropdown.dart';
import 'package:epeoplecare/model/employee/employee.dart';
import 'package:epeoplecare/repository/repository.dart';
import 'package:epeoplecare/view/shared/boolean_picker_page.dart';
import 'package:epeoplecare/view/shared/custom_date_picker.dart';
import 'package:epeoplecare/view/shared/picker_file.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class InputForm {

  Widget renderToogleField({
    dynamic value,
    dynamic option1,
    dynamic option2,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: value == option1 ? Config.DEFAULT_COLOR : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3.0),
                bottomLeft: Radius.circular(3.0),
              )

            ),
            child: Center(
              child: Text(
                option1.toString().toUpperCase(),
                style: TextStyle(
                  color: value == option1 ? Config.DEFAULT_ACCENT_COLOR : Colors.black,
                ),
              )
            ),
          ),
          Container(
            padding: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: value == option2 ? Config.DEFAULT_COLOR : Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3.0),
                bottomRight: Radius.circular(3.0),
              )
            ),
            child: Center(
              child: Text(
                option2.toString().toUpperCase(),
                style: TextStyle(
                  color: value == option2 ? Config.DEFAULT_ACCENT_COLOR : Colors.black,
                ),
              )
            ),
          )
        ],
      ),
    );
  }

  Widget renderTextField({
    TextEditingController? controller,
    String? fieldName,
    TextInputType textInputType= TextInputType.text,
    String? Function(String?)? validator,
    bool enabled= true,
    int maxLines= 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    void Function(String)?  onFieldSubmitted,
    String? initialValue,
    TextInputAction? textInputAction,
    dynamic focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          // height: 40.0,
          child: TextFormField(      
            initialValue: controller != null ? null : initialValue ?? "",
            enabled: enabled,
            maxLines: maxLines,
            maxLength: maxLength,
            controller: controller,
            keyboardType: textInputType,
            textInputAction: textInputType == TextInputType.multiline ? TextInputAction.newline : textInputAction ?? TextInputAction.done,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
            ),
            validator: validator,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            onFieldSubmitted: onFieldSubmitted,
            focusNode: focusNode,
          ),
        ),
      ],
    );
  }

  Widget renderPasswordField({
    TextEditingController? controller,
    dynamic fieldName,
    bool obscureText= true,
    void Function()? onTap,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldName.runtimeType.toString() == "String" 
        ? Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text(
              fieldName,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          )
        : fieldName,
        SizedBox(
          child: TextFormField(
            obscureText: obscureText,
            controller: controller,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
              suffixIcon: GestureDetector(
                onTap: onTap,
                child: Icon(
                  obscureText
                  ? Icons.visibility_off
                  : Icons.visibility,
                ),
              ),
            ),
            validator: validator,
            textInputAction: textInputAction ?? TextInputAction.done,
          ),
        ),
      ],
    );
  }

  Widget renderDateTimeField({
    TextEditingController? controller,
    String? fieldName,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    void Function(DateTime?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: () {
              showDatePicker(
                context: Config.navigatorKey.currentContext!,
                initialDate: initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Config.DEFAULT_COLOR,
                        onPrimary: Config.DEFAULT_ACCENT_COLOR,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          disabledForegroundColor: Config.DEFAULT_COLOR,
                        )
                      )
                    ), 
                    child: child ?? const SizedBox(),
                  );
                },
              ).then((valueDate) {
                if (valueDate == null) return;

                showTimePicker(
                  context: Config.navigatorKey.currentContext!,
                  initialTime: TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Config.DEFAULT_COLOR,
                          onPrimary: Config.DEFAULT_ACCENT_COLOR,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            disabledForegroundColor: Config.DEFAULT_COLOR,
                          )
                        )
                      ), 
                      child: child ?? const SizedBox(),
                    );
                  },
                ).then((value) {
                  if (value == null) return;

                  DateTime pickValue = DateTime(valueDate.year, valueDate.month, valueDate.day, value.hour, value.minute);
                  if(onChanged != null) {
                    onChanged(pickValue);
                  }
                });
              });
            },
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget renderDateField({
    TextEditingController? controller,
    String? fieldName,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    void Function(DateTime?)? onChanged,
    String? Function(String?)? validator,
    bool enabled= true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: () {
              if(!enabled) return;

              showDatePicker(
                context: Config.navigatorKey.currentContext!,
                initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
                firstDate: firstDate,
                lastDate: lastDate,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Config.DEFAULT_COLOR,
                        onPrimary: Config.DEFAULT_ACCENT_COLOR,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          disabledForegroundColor: Config.DEFAULT_COLOR,
                        )
                      )
                    ), 
                    child: child ?? const SizedBox(),
                  );
                },
              ).then((value) {
                if (value == null) return;
                
                if(onChanged != null) {
                  onChanged(value);
                }
              });
            },
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget renderTimeField({
    TextEditingController? controller,
    String? fieldName,
    void Function(TimeOfDay?)? onChanged,
    String? Function(String?)? validator,
    bool enabled = true,
    TimeOfDay? time
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: () {
              if(!enabled) return;

              showTimePicker(
                context: Config.navigatorKey.currentContext!,
                initialTime: time ?? TimeOfDay.now(),
              ).then((value) {
                if (value == null) return;

                if(onChanged != null) {
                  onChanged(value);
                }
              });
            },
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget renderDropdownField({
    String? fieldName,
    String? Function(Object?)? validator,
    dynamic value,
    List<Dropdown> listItem= const [],
    void Function(Object?)? onChanged,
    bool enabled= true,
    Widget Function(dynamic value)? disabledHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: DropdownButtonFormField(
            decoration: InputDecoration(
              fillColor: Colors.red,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
            ),
            initialValue: value,
            items: listItem.map((item) {
              return DropdownMenuItem(
                value: item.value,
                child: Text(
                  "${item.label}",
                  style: TextStyle(
                    fontWeight: FontWeight.normal
                  )
                ),
              );
            }).toList(),
            validator: validator,
            onChanged: enabled ? onChanged : null,
            disabledHint: enabled || disabledHint == null ? null : disabledHint(value),
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget renderAttachmentField({
    String? fieldName,
    void Function()? onRemoveAttachment,
    void Function(Object?)? onChanged,
    File? attachment,
    String? alternateAttachment,
    bool isError= false,
    bool filePicker = false,
    bool imagePicker = true,
    bool galleryPicker = true,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) {
    var mediaQuery = MediaQuery.of(Config.navigatorKey.currentContext!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        attachment != null
            ? Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 5.0,),
                    height: 200.0,
                    width: mediaQuery.size.width,
                    child: Image.file(
                      attachment,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: onRemoveAttachment,
                      child: Container(
                        height: 30.0,
                        width: 30.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.all(Radius.circular(50)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.5),
                              spreadRadius: 2,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20.0,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : alternateAttachment != null 
              ? Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0,),
                      height: 200.0,
                      width: mediaQuery.size.width,
                      child: CachedNetworkImage(
                        httpHeaders: Repository().generateHeader(),
                        imageUrl: alternateAttachment,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => SizedBox(
                          child: Center(
                            child: Platform.isAndroid
                                ? const CircularProgressIndicator()
                                : const CupertinoActivityIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          return _renderAttachmentPicker(onChanged: onChanged, filePicker: filePicker, imagePicker: imagePicker, galleryPicker: galleryPicker, preferredCameraDevice: preferredCameraDevice);
                        },
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: onRemoveAttachment,
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.all(Radius.circular(50)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.5),
                                spreadRadius: 2,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _renderAttachmentPicker(onChanged: onChanged, filePicker: filePicker, imagePicker: imagePicker, galleryPicker: galleryPicker, preferredCameraDevice: preferredCameraDevice),
        const SizedBox(height: 5.0),
        Visibility(
          visible: isError,
          child: Text(
            "This field is required".tr(),
            style: const TextStyle(
              fontSize: 12.0,
              color: Colors.red,
            ),
          ),
        )
      ],
    );
  } 

  Widget _renderAttachmentPicker({
    void Function(Object?)? onChanged,
    required bool filePicker,
    required bool imagePicker,
    required bool galleryPicker,
    required CameraDevice preferredCameraDevice,
  }) {
    var mediaQuery = MediaQuery.of(Config.navigatorKey.currentContext!);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: Config.navigatorKey.currentContext!,
          builder: (BuildContext bc) {
            return PickerFile(
              filePicker: filePicker,
              imagePicker: imagePicker,
              galleryPicker: galleryPicker,
              preferredCameraDevice: preferredCameraDevice,
            );
          },
        ).then((value) {
          if(onChanged != null) {
            onChanged(value);
          }
        });
      },
      child: SizedBox(
        height: 200.0,
        width: mediaQuery.size.width,
        child: Image.asset(
          'assets/img/no-image-available.png',
          fit: BoxFit.fill,
        ),
      ),
    );
  }

  Widget renderButton({
    String? text,
    void Function()? onPressed,
    Color? buttonColor,
    Color? textColor,
    double? width,
    bool enabled= true,
  }) {
    buttonColor ??= Config.DEFAULT_COLOR;
    textColor ??= Config.DEFAULT_ACCENT_COLOR;
    var mediaQuery = MediaQuery.of(Config.navigatorKey.currentContext!);
    width ??= mediaQuery.size.width;  

    return Container(
      margin: const EdgeInsets.only(
        top: 10.0,
      ),
      width: width,
      height: 40.0,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledForegroundColor: Colors.grey[200],
        ),
        child: Text(
          text ?? "",
          style: TextStyle(
            color: enabled ? textColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget renderDetailField({
    String? title,
    String?content,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0, 
              bottom: 10.0,
            ),
            child: Text(
              title ?? "",
              style: const TextStyle(
                color: Colors.grey
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 1.0),
            child: Text(
              content ?? "",
              style: const TextStyle(
                fontSize: 16.0,
              ),
            ),
          ),
          Divider(color: Colors.grey.shade300),
        ],
      ),
    );
  }

  Widget renderDetailAttachmentField({
    String? title,
    String? content,
  }) {
    var mediaQuery = MediaQuery.of(Config.navigatorKey.currentContext!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0, 
              bottom: 10.0,
            ),
            child: Text(
              title ?? "",
              style: const TextStyle(
                color: Colors.grey
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 1.0),
            child: SizedBox(
              height: 200.0,
              width: mediaQuery.size.width,
              child: CachedNetworkImage(
                httpHeaders: Repository().generateHeader(),
                imageUrl: content ?? "",
                fit: BoxFit.contain,
                placeholder: (context, url) => SizedBox(
                  child: Center(
                    child: Platform.isAndroid
                        ? const CircularProgressIndicator()
                        : const CupertinoActivityIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/img/no-image-available.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget renderCustomField({
    TextEditingController? controller,
    String? fieldName,
    void Function()? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: TextFormField(        
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: onTap,
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: Colors.red,
                ),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.only(left: 20.0),
                child: const Icon(
                  Icons.arrow_right,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget renderCustomDateField({
    TextEditingController? controller,
    String? fieldName,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    void Function(DateTime)? onChanged,
    String? Function(String?)? validator,
    bool enabled= true,
    required Employee employee,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: TextFormField(
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: () {
              if(!enabled) return;

              showDialog(
                context: Config.navigatorKey.currentContext!, 
                builder: (BuildContext context) {
                  return CustomDatePicker(
                    initialDate: initialDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    employee: employee,
                  );
                }
              ).then((value) {
                if (value == null) return;
                
                if(onChanged != null) {
                  onChanged(value);
                }
              });
            },
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget renderBooleanField({
    TextEditingController? controller,
    String? fieldName,
    String? Function(String?)? validator,
    void Function(bool)? onChanged,
    bool? value,
  }) {
    if(value != null && controller != null) {
      if(value == true) {
        controller.text = "Yes".tr();
      }
      else {
        controller.text = "No".tr();
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(
            fieldName ?? "",
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        SizedBox(
          child: TextFormField(      
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: () {
              showDialog(
                context: Config.navigatorKey.currentContext!,
                builder: (BuildContext context) => BooleanPickerPage(
                  value: value,
                  title: fieldName,
                )
              ).then((value) {
                if(controller != null) {
                  if(value == null) {
                    controller.text = "";
                  } else if(value == true) {
                    controller.text = "Yes".tr();
                  } else if (value == false) {
                    controller.text = "No".tr();
                  }
                }

                if(onChanged != null) {
                  onChanged(value);
                }
              });
            },
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade300,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 0.5,
                  color: Config.DEFAULT_COLOR,
                ),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  width: 1,
                  color: Colors.red,
                ),
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.only(left: 20.0),
                child: const Icon(
                  Icons.arrow_right,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}