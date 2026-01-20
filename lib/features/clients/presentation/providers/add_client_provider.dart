import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'clients_provider.dart';

part 'add_client_provider.g.dart';

@Riverpod(keepAlive: true)
class AddClient extends _$AddClient {
  @override
  Map<String, dynamic> build() {
    return {
      'type': 'company', // Default
      'contacts': [],
    };
  }

  void updateType(String type) {
    state = {...state, 'type': type};
  }

  void updateBasicInfo({
    String? name,
    String? rif, // For company
    String? personalID, // For person
    String? alias,
    String? email,
    String? phone,
  }) {
    final newState = {...state};
    if (name != null) newState['name'] = name;
    if (rif != null) newState['rif'] = rif;
    if (personalID != null) newState['personalID'] = personalID;
    if (alias != null) newState['alias'] = alias;
    if (email != null) newState['email'] = email;
    if (phone != null) newState['phone'] = phone;
    state = newState;
  }

  void updateAddress({
    String? address,
    String? city,
    String? state, // This shadows the provider state!
    String? country,
  }) {
    final newState = Map<String, dynamic>.from(
      this.state,
    ); // Use this.state explicitly
    if (address != null) newState['address'] = address;
    if (city != null) newState['city'] = city;
    if (state != null) {
      newState['state'] = state; // Map argument 'state' to key 'state'
    }
    if (country != null) newState['country'] = country;
    this.state = newState; // Assign back to this.state
  }

  // Used for the final step contact adding (Primary contact usually)
  void addContact(Map<String, dynamic> contactData) {
    // Ensure we have a contacts list
    final List<dynamic> currentContacts = List.from(state['contacts'] ?? []);
    currentContacts.add(contactData);
    state = {...state, 'contacts': currentContacts};
  }

  void reset() {
    state = {'type': 'company', 'contacts': []};
  }

  Future<void> submit() async {
    // Validate required fields based on type

    // Safety check: specific logic for 'person' type to ignore contacts list
    // This assumes 'type' is correctly set in state
    final submissionState = Map<String, dynamic>.from(state);

    if (submissionState['type'] == 'person') {
      submissionState.remove('contacts');
    }

    // Call main ClientsProvider to save
    await ref.read(clientsProvider.notifier).addClient(submissionState);

    // Reset state after success if needed, or let the provider be disposed (autoDispose handles this)
    // Since keepAlive is true, we should reset it here too or let the UI handle it.
    // Ideally reset after success to be clean.
    reset();
  }
}
