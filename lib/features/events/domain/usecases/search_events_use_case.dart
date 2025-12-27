import '../models/event_model.dart';

class SearchEventsUseCase {
  // Pure logic use case, no repository needed if we pass list. 
  // However, often search might hit backend. 
  // Currently, the logic in provider was client-side filtering on a list.
  // We will keep it client-side but encapsulated here.
  
  List<Event> call({
    required List<Event> events,
    required String query,
  }) {
    if (query.isEmpty) {
      return events;
    }
    
    final lowerQuery = query.toLowerCase();
    
    return events.where((event) {
      final titleMatch = event.title.toLowerCase().contains(lowerQuery);
      final locationMatch = event.location.toLowerCase().contains(lowerQuery);
      final descriptionMatch = event.description.toLowerCase().contains(lowerQuery);
      
      return titleMatch || locationMatch || descriptionMatch;
    }).toList();
  }
}
