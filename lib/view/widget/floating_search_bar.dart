import 'package:touchhealth/core/utils/helper/extention.dart';
import 'package:touchhealth/data/model/place_suggetion.dart';
import 'package:touchhealth/controller/maps/maps_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
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
  FloatingSearchBarController searchBarController =
      FloatingSearchBarController();

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
    searchBarController.dispose();
    super.dispose();
  }

  List<PlaceSuggestionModel> _placeSuggestionList = [];

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      onFocusChanged: (isFocused) {
        if (!isFocused) {
          searchBarController.close();
        }
      },
      isScrollControlled: true,
      accentColor: ColorManager.green,
      queryStyle: context.textTheme.bodySmall?.copyWith(
        color: ColorManager.black,
      ),
      textInputType: TextInputType.text,
      shadowColor: ColorManager.grey.withOpacity(0.4),
      controller: searchBarController,
      borderRadius: BorderRadius.circular(14),
      backgroundColor: ColorManager.white,
      iconColor: ColorManager.green,
      height: 45.h,
      hintStyle:
          context.textTheme.bodySmall?.copyWith(color: ColorManager.black),
      hint: 'Find a hospital...',
      showCursor: true,
      scrollPadding: EdgeInsets.only(bottom: 53.h, top: 0),
      transitionDuration: const Duration(milliseconds: 300),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? context.width / 1.05 : 500,
      debounceDelay: const Duration(milliseconds: 300),
      onQueryChanged: onQueryChanged,
      clearQueryOnClose: true,
      transition: SlideFadeFloatingSearchBarTransition(),
      automaticallyImplyDrawerHamburger: true,
      automaticallyImplyBackButton: true,
      autocorrect: true,
      actions: [
        FloatingSearchBarAction.searchToClear(),
      ],
      builder: (context, transition) {
        return BlocBuilder<MapsCubit, MapsState>(
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
                      //  widget.onPressed();
                      searchBarController.close();
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
                    itemCount: 3, // Show 3 shimmer items
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
            return Container();
          },
        );
      },
    );
  }
}
