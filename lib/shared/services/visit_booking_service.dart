import 'package:cloud_firestore/cloud_firestore.dart';

class VisitBookingService {
  final FirebaseFirestore _db;

  VisitBookingService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  /// Creates a new site visit booking document in Firestore collection `visit_bookings`.
  Future<DocumentReference> createVisitBooking({
    required String listingId,
    required String listingTitle,
    required String buyerId,
    required String buyerName,
    required String buyerPhone,
    required String sellerId,
    required DateTime visitDateTime,
    String? note,
  }) async {
    return await _db.collection('visit_bookings').add({
      'listing_id': listingId,
      'listing_title': listingTitle,
      'buyer_id': buyerId,
      'buyer_name': buyerName,
      'buyer_phone': buyerPhone,
      'seller_id': sellerId,
      'visit_date': Timestamp.fromDate(visitDateTime),
      'note': note ?? '',
      'status': 'pending', // 'pending', 'confirmed', 'completed', 'cancelled'
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  /// Streams incoming visit requests for a specific seller.
  Stream<QuerySnapshot> streamSellerBookings(String sellerId) {
    return _db
        .collection('visit_bookings')
        .where('seller_id', isEqualTo: sellerId)
        .snapshots();
  }

  /// Streams visit bookings submitted by a specific buyer.
  Stream<QuerySnapshot> streamBuyerBookings(String buyerId) {
    return _db
        .collection('visit_bookings')
        .where('buyer_id', isEqualTo: buyerId)
        .snapshots();
  }

  /// Streams visit bookings submitted by a specific buyer for a specific listing.
  Stream<QuerySnapshot> streamUserBookingForListing({
    required String buyerId,
    required String listingId,
  }) {
    return _db
        .collection('visit_bookings')
        .where('buyer_id', isEqualTo: buyerId)
        .where('listing_id', isEqualTo: listingId)
        .snapshots();
  }

  /// Updates status of a visit booking (e.g. 'confirmed', 'cancelled').
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    await _db.collection('visit_bookings').doc(bookingId).update({
      'status': newStatus,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
