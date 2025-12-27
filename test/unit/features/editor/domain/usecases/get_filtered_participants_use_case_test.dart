import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/features/editor/domain/models/participant_model.dart';
import 'package:ibct_eventos/features/editor/domain/usecases/get_filtered_participants_use_case.dart';

void main() {
  late GetFilteredParticipantsUseCase useCase;

  setUp(() {
    useCase = GetFilteredParticipantsUseCase();
  });

  final p1 = Participant(
    id: 'p1',
    eventId: 'e1',
    name: 'Alice Smith',
    email: 'alice@example.com',
    phone: '111',
    ticketType: 'VIP',
    status: 'confirmed',
    token: 't1',
    customFields: {'Company': 'TechCorp'},
  );

  final p2 = Participant(
    id: 'p2',
    eventId: 'e1',
    name: 'Bob Jones',
    email: 'bob@example.com',
    phone: '222',
    ticketType: 'Regular',
    status: 'pending',
    token: 't2',
    customFields: {'Company': 'OtherCorp', 'Age': '30'},
  );

  final p3 = Participant(
    id: 'p3',
    eventId: 'e1',
    name: 'Charlie Brown',
    email: 'charlie@test.com',
    phone: '333',
    ticketType: 'Regular',
    status: 'confirmed',
    token: 't3',
    customFields: {},
  );

  final participants = [p1, p2, p3];
  final defaultColumns = ['Nome', 'Email', 'Telefone', 'Ingresso', 'Status', 'Empresa', 'Cargo', 'CPF/CNPJ'];

  group('GetFilteredParticipantsUseCase', () {
    test('should return all participants when no filters applied', () {
      final result = useCase(
        participants: participants,
        searchQuery: '',
        columnFilters: {},
        sortColumnKey: null,
        sortAscending: true,
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

      expect(result.participants.length, 3);
      expect(result.sortedCustomKeys, containsAll(['Company', 'Age']));
    });

    test('should filter by search query (name)', () {
      final result = useCase(
        participants: participants,
        searchQuery: 'Alice',
        columnFilters: {},
        sortColumnKey: null,
        sortAscending: true,
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

      expect(result.participants.length, 1);
      expect(result.participants.first.name, 'Alice Smith');
    });

    test('should filter by search query (case insensitive email)', () {
      final result = useCase(
        participants: participants,
        searchQuery: 'TEST.COM',
        columnFilters: {},
        sortColumnKey: null,
        sortAscending: true,
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

      expect(result.participants.length, 1);
      expect(result.participants.first.email, 'charlie@test.com');
    });

    test('should filter by column filters', () {
      final result = useCase(
        participants: participants,
        columnFilters: {'Ingresso': 'Regular', 'Status': 'confirmed'},
        searchQuery: '',
        sortColumnKey: null,
        sortAscending: true,
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

      expect(result.participants.length, 1);
      expect(result.participants.first.name, 'Charlie Brown');
    });

    test('should sort ascending by Name', () {
      final result = useCase(
        participants: participants,
        sortColumnKey: 'Nome',
        sortAscending: true,
        searchQuery: '',
        columnFilters: {},
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

      final names = result.participants.map((p) => p.name).toList();
      expect(names, ['Alice Smith', 'Bob Jones', 'Charlie Brown']);
    });

    test('should sort descending by Name', () {
      final result = useCase(
        participants: participants,
        sortColumnKey: 'Nome',
        sortAscending: false,
        searchQuery: '',
        columnFilters: {},
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

      final names = result.participants.map((p) => p.name).toList();
      expect(names, ['Charlie Brown', 'Bob Jones', 'Alice Smith']);
    });

    test('should sort by custom field', () {
      final result = useCase(
        participants: participants,
        sortColumnKey: 'Company',
        sortAscending: true,
        searchQuery: '',
        columnFilters: {},
        columnOrder: null,
        defaultVisibleColumns: defaultColumns,
      );

       // Company: TechCorp, OtherCorp, null (empty string per helper)
       // Empty string usually comes first in comparison?
       // Let's check helper: `getVal` returns '' if null.
       // '' vs 'TechCorp' vs 'OtherCorp'.
       // Sorted: '', 'OtherCorp', 'TechCorp' ?
       // Charlie (null), Bob (OtherCorp), Alice (TechCorp).
       
       final names = result.participants.map((p) => p.name).toList();
       expect(names, ['Charlie Brown', 'Bob Jones', 'Alice Smith']);
    });

    test('should respect column order', () {
      final order = ['Nome', 'Status'];
      final result = useCase(
        participants: participants,
        columnOrder: order,
        searchQuery: '',
        columnFilters: {},
        sortColumnKey: null,
        sortAscending: true,
        defaultVisibleColumns: defaultColumns,
      );

      expect(result.visibleColumns, order);
    });

    test('should ensure Nome is in visible columns', () {
      final order = ['Status']; // No Nome
      final result = useCase(
        participants: participants,
        columnOrder: order,
        searchQuery: '',
        columnFilters: {},
        sortColumnKey: null,
        sortAscending: true,
        defaultVisibleColumns: defaultColumns,
      );

      expect(result.visibleColumns, ['Nome', 'Status']);
    });
  });
}
