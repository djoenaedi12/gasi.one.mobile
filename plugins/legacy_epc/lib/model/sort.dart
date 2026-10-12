
import 'package:epeoplecare/model/sort_direction.dart';

class Sort {
  String sort;
  SortDirection sortDirection;

  Sort(
    this.sort,
    this.sortDirection,
  );

  String getSort() {
    return sort;
  }

  setSort(String sort) {
    this.sort = sort;
  }

  SortDirection getSortDirection() {
    return sortDirection;
  }

  setSortDirection(SortDirection sortDirection) {
    this.sortDirection = sortDirection;
  }
}