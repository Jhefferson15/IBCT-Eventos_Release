import '../../domain/models/participant_model.dart';

// We might need to move ParticipantGridData or create a separate Result DTO if we want strict separation.
// For now, let's keep it simple and return the list + metadata, or just use the data class if moved.
// Actually, let's look at what ParticipantGridData holds: 
// It holds participants, sortedCustomKeys, visibleColumns.
// sortedCustomKeys and visibleColumns are computed presentation data, but derived from data.
// Let's refactor: The UseCase should typically return the processed data.
// Let's move ParticipantGridData definition to a shared model or keep it in the use case file for now?
// Best practice: Defined in Use Case file or Domain Models.
// Let's rely on the Use Case returning a Result type.

class ParticipantFilterResult {
  final List<Participant> participants;
  final List<String> sortedCustomKeys;
  final List<String> visibleColumns;

  ParticipantFilterResult(this.participants, this.sortedCustomKeys, this.visibleColumns);
}

class GetFilteredParticipantsUseCase {
  
  ParticipantFilterResult call({
    required List<Participant> participants,
    required String searchQuery,
    required Map<String, String> columnFilters,
    required String? sortColumnKey,
    required bool sortAscending,
    required List<String>? columnOrder,
    required List<String> defaultVisibleColumns, // From Event settings
  }) {
    
    // 1. Filter
    var filteredData = List<Participant>.from(participants);
    
    // Global Search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredData = filteredData.where((p) {
        return p.name.toLowerCase().contains(query) ||
               p.email.toLowerCase().contains(query) ||
               p.id.contains(query);
      }).toList();
    }
    
    // Helper to get value
    String getVal(Participant p, String key) {
        switch (key) {
          case 'Nome': return p.name;
          case 'Email': return p.email;
          case 'Telefone': return p.phone;
          case 'Empresa': return p.company ?? '';
          case 'Cargo': return p.role ?? '';
          case 'CPF/CNPJ': return p.cpf ?? '';
          case 'Status': return p.status;
          case 'Ingresso': return p.ticketType;
          default: return p.customFields[key]?.toString() ?? '';
        }
    }

    // Column Filters
    if (columnFilters.isNotEmpty) {
       filteredData = filteredData.where((p) {
          for (final entry in columnFilters.entries) {
             final val = getVal(p, entry.key).toLowerCase();
             final filter = entry.value.toLowerCase();
             if (!val.contains(filter)) return false;
          }
          return true;
       }).toList();
    }

    // 2. Sort
    if (sortColumnKey != null) {
      filteredData.sort((a, b) {
         final valA = getVal(a, sortColumnKey).toLowerCase();
         final valB = getVal(b, sortColumnKey).toLowerCase();
         return sortAscending ? valA.compareTo(valB) : valB.compareTo(valA);
      });
    }

    // 3. Extract Custom Columns (Keys)
    final Set<String> customKeys = {};
    for (var p in participants) {
      customKeys.addAll(p.customFields.keys);
    }
    final List<String> sortedCustomKeys = customKeys.toList()..sort();

    // 4. Compute Visible Columns
    List<String> columnsToShow = [];
    
    if (columnOrder != null && columnOrder.isNotEmpty) {
       columnsToShow = List.from(columnOrder);
    } else if (defaultVisibleColumns.isNotEmpty) {
       columnsToShow = List.from(defaultVisibleColumns);
    } else {
       columnsToShow = ['Nome', 'Email', 'Telefone', 'Ingresso', 'Status', 'Empresa', 'Cargo', 'CPF/CNPJ'];
       columnsToShow.addAll(sortedCustomKeys);
    }

    if (!columnsToShow.contains('Nome')) {
       columnsToShow.insert(0, 'Nome');
    }

    return ParticipantFilterResult(filteredData, sortedCustomKeys, columnsToShow);
  }
}
