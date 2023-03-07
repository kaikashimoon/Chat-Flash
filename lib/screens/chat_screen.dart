import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {

  static String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late User loggedInUser;
  late String messageText;

  @override
  void initState() {
    super.initState();
    getCurrentUser();

    // messagesStream();

  }

  void getCurrentUser() async {
    try{

      final user = await _auth.currentUser;
      if(user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
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

  void messageStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()){
      for (var message in snapshot.docs){
        var messegeData = message.data();
        var messageSender = messegeData['sender'];
        var messageText = messegeData['text'];
        print('this is messege sender $messageSender and this is message text $messageText');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages').orderBy('date').snapshots(),
              builder: (context, snapshot) {
                List<MessageBubble> messageBubbles = [];
                if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.lightBlueAccent,
                      ),
                    );
                }
                  final messages = snapshot.data!.docs;
                  for (var message in messages) {
                    final messageText = message.get('text');
                    final messageSender = message.get('sender');
                    DateTime date = DateTime.parse(message.get('date').toDate().toString());
                    final dateTime = DateFormat('MM/dd/yyyy, hh:mm a').format(date);

                    final messageBubble = MessageBubble(messageSend: messageSender, messageTex: messageText, dateMessage: dateTime);

                    messageBubbles.add(messageBubble);
                  } //for

                return Expanded(
                  //Use listview to scroll and not overflow
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
                    children: messageBubbles,
                  ),
                );
              }, // builder
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                        _firestore.collection('messages').add({
                        'text': messageText,
                        'sender': loggedInUser.email,
                        'date': DateTime.now(),
                        });
                    },
                    child: Text(
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

class MessageBubble extends StatelessWidget {

  MessageBubble({this.messageSend, this.messageTex, required this.dateMessage });

  final String? messageSend;
  final String? messageTex;
  final String dateMessage;

  @override
  Widget build(BuildContext context) {
      return  Padding(
        padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(messageSend!,
                style: TextStyle(
                    fontSize: 12.0,
                  color: Colors.black54
                ),
              ),
              Material(
                borderRadius: BorderRadius.circular(30.0),
                elevation: 5.0,
                color: Colors.lightBlue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  child: Text('$messageTex',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(dateMessage,
                  style: TextStyle(
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