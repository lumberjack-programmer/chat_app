import 'package:flutter/material.dart';
import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


final _fireStore = FirebaseFirestore.instance;
User? loggedInUser;
List<Map<String?, String>> messages =  [];

class ChatScreen extends StatefulWidget {
  static String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late String messageText = '';

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  Future<void> getCurrentUser() async {
    try {
      loggedInUser = await _auth.currentUser!;
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: null,
        actions: [
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
              }),
        ],
        title: Text('️Chat'),
        backgroundColor: Color(0xff001c55),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomStreamBuilder(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(

                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      if (messageText != '') {
                        Map<String?, String> messageMap = {
                          loggedInUser?.email: messageText
                        };
                        messages.add(messageMap);
                        messageTextController.clear();

                        _fireStore
                            .collection('messages')
                            .doc('chatCollection')
                            .get()
                            .then((value) => {
                                  if (value.exists)
                                    {
                                      _fireStore
                                          .collection('messages')
                                          .doc('chatCollection')
                                          .update({'chat1': messages})
                                    }
                                  else
                                    {
                                      _fireStore
                                          .collection('messages')
                                          .doc('chatCollection')
                                          .set({'chat1': messages})
                                    }
                                });
                      }
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

class CustomStreamBuilder extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    print(loggedInUser);
    return StreamBuilder<QuerySnapshot>(
        stream: _fireStore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
          } else
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator(backgroundColor: Colors.lightBlueAccent));
            } else {

              messages = [];

          final messagesSnapshot = snapshot.data?.docs;

          List<MessageBubble> messageBubbles = [];

          for (var message in messagesSnapshot!) {
            Map<String, dynamic> chat =  message.data() as Map<String, dynamic> ;

            List<dynamic> test = chat['chat1'] as List<dynamic>;


            for (var elem in test) {
              Map<String?, dynamic> tmp = elem as Map<String?, dynamic>;

              tmp.forEach((key, value) {
                final messageText = value;
                final messageSender = key;
                if (messageText != null && messageSender != null) {

                  messages.add({key : value});
                  final messageBubble = MessageBubble(messageText: messageText,
                      messageSender: messageSender,
                      isMineMessage: loggedInUser?.email == key
                          ? true
                          : false);
                       messageBubbles.add(messageBubble);
                }
              });
                }
                  }


          return Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0,),
            children: messageBubbles,
            ),
          );
          }
            return Container();
        },
    );
  }



}

class MessageBubble extends StatelessWidget {
  MessageBubble({
    required this.messageText,
    required this.messageSender,
    required this.isMineMessage
  });

  final String messageText;
  final String messageSender;

  final bool isMineMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(
        10.0,
      ),
      child: Column(
        crossAxisAlignment: isMineMessage == true ? CrossAxisAlignment.end :  CrossAxisAlignment.start,
        children: [
          Text(
            messageSender,
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.black38,
            ),
          ),
          SizedBox(height: 4.0,),
          Container(
            constraints: BoxConstraints(
              maxWidth: 250,
            ),
            child: Material(
              borderRadius: BorderRadius.circular(15.0),
              elevation: 5.0,
              color: isMineMessage == true ? Colors.lightBlueAccent : Colors.grey.shade100,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 10,
                ),
                child: Text(
                  messageText,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: isMineMessage == true ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
