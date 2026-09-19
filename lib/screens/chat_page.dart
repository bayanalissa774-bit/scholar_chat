import 'package:scholar_chat/screens/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:scholar_chat/constants/app_colors.dart';
import 'package:scholar_chat/widgets/chat_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final CollectionReference<Map<String, dynamic>> messagesCollection =
      FirebaseFirestore.instance.collection("messages");
  final Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream =
      FirebaseFirestore.instance
          .collection('messages')
          .orderBy('createdAt')
          .snapshots();

  final Set<String> selectedMessageIds = <String>{};
  final Set<String> currentUserMessageIds = <String>{};
  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  void toggleMessageSelection(String messageId) {
    setState(() {
      if (selectedMessageIds.contains(messageId)) {
        selectedMessageIds.remove(messageId);
      } else {
        selectedMessageIds.add(messageId);
      }
    });
  }

  void selectAllMessages() {
    setState(() {
      selectedMessageIds.clear();
      selectedMessageIds.addAll(currentUserMessageIds);
    });
  }

  Future<void> deleteSelectedMessages() async {
    final WriteBatch batch = FirebaseFirestore.instance.batch();

    for (final String messageId in selectedMessageIds) {
      batch.delete(messagesCollection.doc(messageId));
    }

    await batch.commit();

    if (!mounted) return;

    setState(() {
      selectedMessageIds.clear();
    });
  }

  Future<void> sendMessage() async {
    final String message = messageController.text.trim();
    if (message.isEmpty) {
      return;
    }
    await messagesCollection.add({
      'message': message,
      'email': FirebaseAuth.instance.currentUser!.email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    messageController.clear();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> signOutUser() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SignInPage(),
        ),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: isSelectionMode
            ? Text('${selectedMessageIds.length} selected')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/scholar.png',
                    height: 30,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  const Text('chat'),
                ],
              ),
        actions: isSelectionMode
            ? [
                IconButton(
                  onPressed: selectAllMessages,
                  icon: const Icon(Icons.select_all),
                  tooltip: 'Select all',
                ),
                IconButton(
                  onPressed: deleteSelectedMessages,
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete all selected',
                ),
              ]
            : [
                IconButton(
                  onPressed: signOutUser,
                  icon: const Icon(Icons.logout),
                  tooltip: " sign out",
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                final messages = snapshot.data!.docs;
                currentUserMessageIds.clear();
                for (final document in messages) {
                  final messageData = document.data();
                  final String email = messageData['email'] as String? ?? '';
                  if (email == FirebaseAuth.instance.currentUser?.email) {
                    currentUserMessageIds.add(document.id);
                  }
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients && messages.isNotEmpty) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final String messageId = messages[index].id;
                    final messageData = messages[index].data();
                    final String message =
                        messageData['message'] as String? ?? '';

                    final String email = messageData['email'] as String? ?? '';
                    final bool isSender =
                        email == FirebaseAuth.instance.currentUser?.email;
                    final bool isSelected =
                        selectedMessageIds.contains(messageId);

                    return GestureDetector(
                      onLongPress: isSender
                          ? () {
                              toggleMessageSelection(messageId);
                            }
                          : null,
                      onTap: isSelectionMode && isSender
                          ? () {
                              toggleMessageSelection(messageId);
                            }
                          : null,
                      child: Container(
                        color: isSelected
                            ? const Color(0x1F2196F3)
                            : Colors.transparent,
                        child: ChatBubble(
                          message: message,
                          isSender: isSender,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 25),
              child: TextField(
                controller: messageController,
                textInputAction: TextInputAction.send,
                onSubmitted: (value) {
                  sendMessage();
                },
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(
                      Icons.send,
                    ),
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

// أولًا: نكمل تحسين صفحة المحادثة

// بقي:

// نخلي القائمة تنزل تلقائيًا لآخر رسالة بعد الإرسال.
// نتأكد أن الكيبورد ما يغطي حقل الكتابة.
// ننظف أي كود قديم أو imports غير مستخدمة.
// ثانيًا: نربط التطبيق فعليًا

// بعدها نبدأ بالوظائف الحقيقية:

// Firebase Authentication للتسجيل وتسجيل الدخول.
// Firestore لحفظ الرسائل.
// عرض الرسائل مباشرة من قاعدة البيانات.
// تمييز رسالة المستخدم الحالي عن رسائل الآخرين.
// إضافة تسجيل الخروج.

// هلق الأفضل نكمل أول تحسين: النزول التلقائي لآخر رسالة بعد الإرسال.
