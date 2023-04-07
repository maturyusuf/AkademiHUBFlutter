import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_comment_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final CollectionReference _postsCollection =
  FirebaseFirestore.instance.collection('posts');

  Future<void> addPost(Post post) async {
    try {
      await _postsCollection.add(post.toMap());
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }


  Future<List<Post>> getPosts() async {
    try {
      QuerySnapshot querySnapshot = await _postsCollection
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs
          .map((doc) => Post.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  final CollectionReference _commentsCollection = FirebaseFirestore.instance.collection('comments');

  Future<void> addComment(PostCommentModel comment) async {
    try {
      await _commentsCollection.add(comment.toFirestore());
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  Future<List<PostCommentModel>> getCommentsForPost(String postId) async {
    try {
      QuerySnapshot querySnapshot = await _commentsCollection
          .where('sentToPostId', isEqualTo: postId)
          .get();

      return querySnapshot.docs
          .map((doc) => PostCommentModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  Future<void> addUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.userId).set(user.toMap());
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  final CollectionReference _postsCollectionRef = FirebaseFirestore.instance.collection('posts');

  Future<void> updatePostLikeStatus(Post post, String userId) async {
    try {
      post.toggleLike(userId);
      await _postsCollectionRef.doc(post.id).update({'likes': post.likes, 'likedByUsers': post.likedByUsers});
    } catch (e) {
      print('Error updating post like status: $e');
      rethrow;
    }
  }


}

