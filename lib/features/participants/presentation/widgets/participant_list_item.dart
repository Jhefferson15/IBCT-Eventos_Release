import 'package:flutter/material.dart';
import '../../../editor/domain/models/participant_model.dart';

class ParticipantListItem extends StatelessWidget {
  final Participant participant;
  final VoidCallback onTap;

  const ParticipantListItem({
    super.key,
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          participant.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (participant.email.isNotEmpty)
              Text(participant.email),
            if (participant.role != null && participant.role!.isNotEmpty)
              Text(
                participant.role!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
