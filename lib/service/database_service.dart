import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCollection(String collection, String data, String uid) async {
    try {
      await _firestore.collection(collection).add({
        'name': data,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding collection: $e');
    }
  }

  Future<void> addDataToCollection(
      String collectionName, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collectionName).add(data);
    } catch (e) {
      print('Error adding data to collection: $e');
    }
  }

  Future<DocumentSnapshot> getDocument(String collection, String docId) async {
    try {
      DocumentSnapshot document =
          await _firestore.collection(collection).doc(docId).get();
      return document;
    } catch (e) {
      print('Belge getirilirken hata oluştu: $e');
      rethrow;
    }
  }

  Future<void> updateDocument(
      String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      print('Error updating document: $e');
    }
  }

  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
      print('Belge silindi: $docId');
    } catch (e) {
      print('Belge silinirken hata oluştu: $e');
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getCollections(String userId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('Collections')
        .where('uid', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> collections = snapshot.docs.map((doc) {
      return {
        'uid': doc.id,
        'name': doc['name'],
      };
    }).toList();

    collections.forEach((collection) {
      print("Collection ID: ${collection['uid']}, Name: ${collection['name']}");
    });

    return collections;
  }

  Future<void> deleteCollection(String uid) async {
    try {
      var collection = _firestore.collection('Collections').doc(uid);
      print("Koleksiyon referansı alındı");

      var snapshots = await collection.collection('items').get();
      print(
          "Alt belgeler alındı, toplam belge sayısı: ${snapshots.docs.length}");

      for (var doc in snapshots.docs) {
        await doc.reference.delete();
        print("Belge silindi: ${doc.id}");
      }

      await collection.delete();
      print("Koleksiyon silindi");
    } catch (e) {
      print("Error deleting collection: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getCollectionsItems(String uid) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('Collections')
          .doc(uid)
          .collection('items')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'uid': doc.id,
          'data': doc['data'],
          'timestamp': doc['timestamp'],
          'data': doc['data'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching collection items: $e");
      return [];
    }
  }

  Stream<DocumentSnapshot> getCollaborativeDocument(String docId) {
    return _firestore.collection('Collaborative').doc(docId).snapshots();
  }

  Future<void> updateCollaborativeDocument(
      String docId, Map<String, dynamic> data) {
    return _firestore.collection('Collaborative').doc(docId).update(data);
  }

  Future<DocumentSnapshot> getCollaborativeDocumentOnce(String docId) {
    return _firestore.collection('Collaborative').doc(docId).get();
  }
    Future<List<String>> getUserCollaborativePages() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot snapshot = await _firestore
          .collection('Collaborative')
          .where('members', arrayContains: user.uid)
          .get();

      // Kullanıcının erişebileceği belge ID'lerini döndür
      return snapshot.docs.map((doc) => doc.id).toList();
    }
    return [];
  }
}
