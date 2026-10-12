import 'package:kusurins/firestore/room_firestore.dart';
import 'package:kusurins/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:kusurins/firestore/room_firestore.dart';

import '../model/talk_room.dart';
import '../utils/shared_prefs.dart';

class TalkRoomPage extends StatefulWidget {
  final TalkRoom talkRoom;
  const TalkRoomPage(this.talkRoom, {super.key});

  @override
  State<TalkRoomPage> createState() => _TalkRoomPageState();
}

class _TalkRoomPageState extends State<TalkRoomPage> {
  final TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        title: Text(widget.talkRoom.talkUser.name),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: RoomFirestore.fetchMessageSnapshot(widget.talkRoom.roomId),
              builder: (context, snapshot) {
                if(snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 68),
                    child: ListView.builder(
                        physics: RangeMaintainingScrollPhysics(),
                        shrinkWrap: true,
                        reverse: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          final Message message = Message(
                              message: data['message'],
                              isMe: SharedPrefs.fetchUid() == data['sender_id'],
                              sendTime: data['send_time']
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, left: 10, right: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
                              children: [
                                Container(
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                    decoration: BoxDecoration(
                                        color: message.isMe ? Colors.green : Colors.white,
                                        borderRadius: BorderRadius.circular(15)
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    child: Text(message.message
                                    )),
                                Text(intl.DateFormat('HH:mm').format(message.sendTime.toDate()))
                              ],
                            ),
                          );
                        }
                    ),
                  );
                } else {
                  return Center(child: Text('メッセージがありません。'),);
                }
              }
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                color: Colors.white,
                height: 60,
                child: Row(
                  children: [
                    Expanded(child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                            contentPadding: EdgeInsets.only(left: 10),
                            border: OutlineInputBorder()
                        ),
                      ),
                    )),
                    IconButton(
                        onPressed: () async {
                          await RoomFirestore.sendMessage(
                              roomId: widget.talkRoom.roomId,
                              message: controller.text

                          );
                          controller.clear();
                        },
                        icon: const Icon(Icons.send)
                    )
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                height: MediaQuery.of(context).padding.bottom,
              ),
            ],
          )
        ],
      ),
    );
  }
}
