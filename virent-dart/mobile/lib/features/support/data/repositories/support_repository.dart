import '../../../../core/configs/services/api_client.dart';
import '../models/ticket_model.dart';

/// Repository that fetches and mutates the user's support tickets.
///
/// Wraps the `/support/tickets` REST endpoints. Returns typed [Ticket]
/// objects so the UI never has to touch raw JSON.
class SupportRepository {
  /// Creates a repository backed by [api] (or a fresh [ApiClient]).
  SupportRepository([ApiClient? api]) : _api = api ?? ApiClient();

  final ApiClient _api;

  /// Fetches every ticket belonging to the current user, newest first.
  Future<List<Ticket>> getTickets() async {
    final data = await _api.get('/support/tickets');
    final list = (data['tickets'] as List? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(Ticket.fromJson)
        .toList();
    list.sort((a, b) => (b.updatedAt ?? b.createdAt)
        .compareTo(a.updatedAt ?? a.createdAt));
    return list;
  }

  /// Creates a new ticket.
  ///
  /// [type] is the category, [subject] is the one-line summary, and
  /// [message] is the initial body that opens the thread.
  Future<Ticket> createTicket({
    required TicketType type,
    required String subject,
    required String message,
  }) async {
    final data = await _api.post('/support/tickets', {
      'type': type.name,
      'subject': subject,
      'message': message,
    });
    final json = (data['ticket'] ?? data) as Map<String, dynamic>;
    return Ticket.fromJson(json);
  }

  /// Appends a new [message] to the thread [ticketId].
  Future<TicketMessage> sendMessage({
    required String ticketId,
    required String message,
  }) async {
    final data = await _api.post('/support/tickets/$ticketId/messages', {
      'message': message,
    });
    final json = (data['message'] ?? data) as Map<String, dynamic>;
    return TicketMessage.fromJson(json);
  }

  /// Closes the ticket with [ticketId].
  Future<void> closeTicket(String ticketId) =>
      _api.post('/support/tickets/$ticketId/close', <String, dynamic>{});
}
