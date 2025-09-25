import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/data/model/place_suggetion.dart';
import 'package:touchhealth/controller/maps/maps_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Removed dependency on material_floating_search_bar_2 due to Flutter 3.35 API changes.
import 'package:skeletonizer/skeletonizer.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../core/utils/theme/color.dart';

class MyFloatingSearchBar extends StatefulWidget {
  const MyFloatingSearchBar({
    super.key,
  });

  @override
  MyFloatingSearchBarState createState() => MyFloatingSearchBarState();
}

class MyFloatingSearchBarState extends State<MyFloatingSearchBar> {
  final TextEditingController _textController = TextEditingController();

  Timer? _debounceTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 800);

  void Function(String)? onQueryChanged(query) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.toString().trim().isNotEmpty) {
      _debounceTimer = Timer(_debounceDuration, () {
        final sessionToken = const Uuid().v4();
        context.bloc<MapsCubit>().getPlaceSuggetions(
            place: query.toString().trim(), sessionToken: sessionToken);
      });
    }
    return null;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  List<PlaceSuggestionModel> _placeSuggestionList = [];

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: TextField(
            controller: _textController,
            onChanged: (val) => onQueryChanged(val),
            autocorrect: true,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Find a hospital...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                        setState(() {});
                        FocusScope.of(context).unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: ColorManager.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: ColorManager.black,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Flexible(
          child: BlocBuilder<MapsCubit, MapsState>(
            builder: (context, state) {
              if (state is MapsLoadedSuggestionsSuccess) {
                _placeSuggestionList = state.placeSuggestionList;
                return ListView.builder(
                  padding: EdgeInsets.only(
                      top: 10.h, bottom: MediaQuery.viewInsetsOf(context).bottom),
                  shrinkWrap: true,
                  itemCount: _placeSuggestionList.length,
                  itemBuilder: (context, index) => Card(
                    color: ColorManager.white,
                    child: ListTile(
                      trailing: Icon(
                        Icons.apartment_rounded,
                        size: 20.r,
                        color: ColorManager.green,
                      ),
                      leading: Icon(
                        Icons.place,
                        size: 20.r,
                        color: ColorManager.green,
                      ),
                      title: Text(
                        _placeSuggestionList[index].mainText,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        _placeSuggestionList[index].secondaryText,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodySmall
                            ?.copyWith(color: ColorManager.black),
                      ),
                      onTap: () {
                        final sessionToken = const Uuid().v4();
                        context.bloc<MapsCubit>().getPlaceLocation(
                            placeId: _placeSuggestionList[index].placeId,
                            description: _placeSuggestionList[index].description,
                            sessionToken: sessionToken);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                );
              }
              if (state is MapsLoading) {
                return Padding(
                  padding: EdgeInsets.only(
                      top: 10.h, bottom: MediaQuery.viewInsetsOf(context).bottom),
                  child: Skeletonizer(
                    enabled: true,
                    effect: ShimmerEffect(
                      baseColor: ColorManager.grey.withOpacity(0.2),
                      highlightColor: ColorManager.white,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: 3,
                      itemBuilder: (context, index) => Card(
                        color: ColorManager.white,
                        child: ListTile(
                          trailing: Icon(
                            Icons.apartment_rounded,
                            size: 20.r,
                            color: ColorManager.green,
                          ),
                          leading: Icon(
                            Icons.place,
                            size: 20.r,
                            color: ColorManager.green,
                          ),
                          title: const Text(
                            "Hospital Name",
                            textAlign: TextAlign.center,
                          ),
                          subtitle: const Text(
                            "Hospital Address, City, Country",
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
