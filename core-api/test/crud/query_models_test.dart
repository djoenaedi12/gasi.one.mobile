import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

void main() {
  test(
    'serializes nested filters, sorts, fields, and normalized pagination',
    () {
      const request = QueryRequest(
        filter: AndFilter([
          SimpleFilter(
            field: 'active',
            operator: FilterOperator.equals,
            value: true,
          ),
          OrFilter([
            SimpleFilter(
              field: 'name',
              operator: FilterOperator.like,
              value: 'admin',
            ),
            SimpleFilter(field: 'deletedAt', operator: FilterOperator.isNull),
          ]),
        ]),
        sorts: [SortOrder.desc('createdAt')],
        fields: ['id', 'name'],
        page: -1,
        size: 200,
      );

      expect(request.toJson(), {
        'filter': {
          'type': 'and',
          'filters': [
            {
              'type': 'simple',
              'field': 'active',
              'operator': 'EQUALS',
              'value': true,
            },
            {
              'type': 'or',
              'filters': [
                {
                  'type': 'simple',
                  'field': 'name',
                  'operator': 'LIKE',
                  'value': 'admin',
                },
                {'type': 'simple', 'field': 'deletedAt', 'operator': 'IS_NULL'},
              ],
            },
          ],
        },
        'sorts': [
          {'field': 'createdAt', 'direction': 'DESC'},
        ],
        'fields': ['id', 'name'],
        'page': 0,
        'size': 100,
      });
    },
  );

  test('nextPage preserves query criteria', () {
    const request = QueryRequest(
      filter: SimpleFilter(
        field: 'code',
        operator: FilterOperator.inList,
        value: ['A', 'B'],
      ),
      sorts: [SortOrder.asc('code')],
      page: 2,
      size: 25,
    );

    final next = request.nextPage();

    expect(next.page, 3);
    expect(next.size, 25);
    expect(next.filter, same(request.filter));
    expect(next.sorts, same(request.sorts));
  });
}
