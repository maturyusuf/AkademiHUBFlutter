import 'package:akademi_hub_flutter/service/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/post_comment_model.dart';
import 'models/post_model.dart';

class PostDetailsPage extends StatefulWidget {
  final Post post;



  PostDetailsPage({required this.post});

  @override
  _PostDetailsPageState createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final String? currentUserName = FirebaseAuth.instance.currentUser?.displayName;
  String? _selectedCommentId;


  void _submitComment() async {
    if (_commentController.text.isNotEmpty) {
      print(currentUserId);
      print(currentUserName);
      PostCommentModel newComment = PostCommentModel(
          id: '',
          content: _commentController.text,
          likes: 0,
          sentToPostId: widget.post.id,
          sentByUserId: currentUserId!,
          sentByUserName:currentUserName!,
          isSolved: false
      );

      try {
        await _firestoreService.addComment(newComment);
        widget.post.commentCount++;
        await _firestoreService.updateCommentCount(widget.post);
        _commentController.clear();
        setState(() {});
      } catch (e) {
        print('Error submitting comment: $e');
      }
    }
  }


  void _toggleSelectedComment(PostCommentModel comment) async {
    if (widget.post.sentByUserId == currentUserId) {
      await _firestoreService.updateCommentIsSolved(comment.id, !comment.isSolved);
      await _firestoreService.updateUserPoints(
          comment.sentByUserId, comment.isSolved ? -20 : 20);
      setState(() {
        comment.isSolved = !comment.isSolved;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("username = "+currentUserName!);
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.title,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(widget.post.content),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'by ${widget.post.sentByUserName}',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey),
          Expanded(
            child: FutureBuilder<List<PostCommentModel>>(
              future: _firestoreService.getCommentsForPost(widget.post.id),
              builder: (BuildContext context,
                  AsyncSnapshot<List<PostCommentModel>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('An error occurred'));
                } else {
                  List<PostCommentModel> comments = snapshot.data!;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _buildCommentCard(comments[index]);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4.0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _submitComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCard(PostCommentModel comment) {
    bool isSelected = _selectedCommentId == comment.id;
    return Card(
      color: comment.isSolved ? Colors.lightGreen[100] : null,
      child: InkWell(
        onTap: () => _toggleSelectedComment(comment),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.sentByUserName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(comment.content),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isSelected && widget.post.sentByUserId == currentUserId
                      ? Icon(Icons.check, color: Colors.green)
                      : SizedBox(),
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.grey),
                      SizedBox(width: 5),
                      Text('${comment.likes}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}