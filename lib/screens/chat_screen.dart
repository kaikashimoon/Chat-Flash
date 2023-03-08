import 'package:flashchat/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:time_formatter/time_formatter.dart';

final _firestore = FirebaseFirestore.instance;
User? loggedInUser;

class ChatScreen extends StatefulWidget {

  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();

  }

  void getCurrentUser() async {
    try{

      final user = await _auth.currentUser;
      if(user != null) {
        loggedInUser = user;
        print(loggedInUser!.email);
      }
    } catch(e) {
      print(e);
    }
  }

  // void getMessages() async {
  //   QuerySnapshot querySnapshot = await _firestore.collection('messages').get();
  //   final messages = querySnapshot.docs.map((doc) => doc.data()).toList();
  //   for (var message in messages) {
  //     print(message);
  //   }
  // }

  // void messageStream() async {
  //   await for (var snapshot in _firestore.collection('messages').snapshots()){
  //     for (var message in snapshot.docs){
  //       var messegeData = message.data();
  //       var messageSender = messegeData['sender'];
  //       var messageText = messegeData['text'];
  //       print('this is messege sender $messageSender and this is message text $messageText');
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pushReplacementNamed(context, WelcomeScreen.id);
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                        messageTextController.clear();
                        _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser!.email,
                        'date': FieldValue.serverTimestamp(),
                        });
                    },
                    child: const Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MessageStream extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return  StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> messageBubbles = [];
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.lightBlueAccent,
              ),
            ),
          );
        }
        final messages = snapshot.data!.docs;
        for (var message in messages) {
          final messageText = message.get('text');
          final messageSender = message.get('sender');
          final messageTime = message.get('date');
          // final Timestamp timestamp = message.get('date') as Timestamp ?? Timestamp.now();
          // final DateTime dateTime = timestamp.toDate();
          // final dateString = DateFormat('K:mm:ss').format(dateTime);
          // final dateTime = DateFormat('MM/dd/yyyy, hh:mm a').format(date);

          // print(dateString);

          final currentUser = loggedInUser!.email;

          if(currentUser == messageSender) {

          }


          final messageBubble = MessageBubble(
              messageSend: messageSender,
              messageTex: messageText,
              time: messageTime,
              isMe: currentUser == messageSender,
          );

          messageBubbles.add(messageBubble);
        } //for

        return Expanded(
          //Use listview to scroll and not overflow
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      }, // builder
    );
  }

}

class MessageBubble extends StatelessWidget {

  MessageBubble({this.messageSend, this.messageTex,  required this.isMe, required Timestamp time}) : time =  time ?? Timestamp.now();

  final String? messageSend;
  final String? messageTex;
  final Timestamp time;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
      return  Padding(
        padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(messageSend!,
                style: const TextStyle(
                    fontSize: 12.0,
                  color: Colors.black54
                ),
              ),
              Material(
                borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(30.0), bottomLeft: Radius.circular(30.0), bottomRight: Radius.circular(30.0)) : BorderRadius.only(topRight: Radius.circular(30.0), bottomLeft: Radius.circular(30.0), bottomRight: Radius.circular(30.0)),
                elevation: 5.0,
                color: isMe ? Colors.lightBlue : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  child: Text('$messageTex',
                    style: TextStyle(
                      color: isMe ?  Colors.white : Colors.black54,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('${formatTime(time.millisecondsSinceEpoch)}',
                  style: const TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54
                  ),
                ),
              ),
            ],
          ),
      );
  }
}