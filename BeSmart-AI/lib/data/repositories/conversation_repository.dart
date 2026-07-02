import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../services/database_service.dart';

class ConversationRepository {
  ConversationRepository(this._db);

  final DatabaseService _db;
  static const _uuid = Uuid();

  Future<List<Conversation>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Conversation.fromMap).toList();
  }

  Future<Conversation?> getById(String id) async {
    final db = await _db.database;
    final rows = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Conversation.fromMap(rows.first);
  }

  Future<Conversation> create({String title = 'Nouvelle conversation'}) async {
    final db = await _db.database;
    final now = DateTime.now();
    final conversation = Conversation(
      id: _uuid.v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('conversations', conversation.toMap());
    return conversation;
  }

  Future<void> updateTitle(String id, String title) async {
    final db = await _db.database;
    await db.update(
      'conversations',
      {
        'title': title,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> touch(String id) async {
    final db = await _db.database;
    await db.update(
      'conversations',
      {'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final db = await _db.database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<ChatMessage> addMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
  }) async {
    final db = await _db.database;
    final message = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
    await db.insert('messages', message.toMap());
    await touch(conversationId);
    return message;
  }

  Future<void> updateMessageContent(String id, String content) async {
    final db = await _db.database;
    await db.update(
      'messages',
      {'content': content},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String?> getPreview(String conversationId) async {
    final db = await _db.database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['content'] as String?;
  }
}
