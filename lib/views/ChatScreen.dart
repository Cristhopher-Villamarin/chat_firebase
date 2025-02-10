import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final String username;

  ChatScreen({required this.channel, required this.username});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> _messages = [];
  List<dynamic> _users = [];
  final TextEditingController _messageController = TextEditingController();
  String _currentChat = 'broadcast';
  String? _selectedUserSession;
  String? _selectedUsername;
  late StreamSubscription _subscription;
  Map<String, int> _unreadMessages = {}; // Contador de mensajes no leídos por usuario

  // Función para formatear la fecha
  String _formatMessageDate(String timestamp) {
    DateTime date;
    try {
      date = DateTime.parse(timestamp);
    } catch (e) {
      // Si el formato de la fecha no es ISO, se puede intentar otro parseo o devolver el timestamp original
      return timestamp;
    }
    final now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Ayer ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd MMM, HH:mm').format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    _subscription = widget.channel.stream.listen(_handleIncomingMessage);
  }

  void _handleIncomingMessage(dynamic message) {
    final Map<String, dynamic> data = jsonDecode(message);

    if (data['type'] == 'USERS_UPDATE') {
      // Creamos la lista de usuarios conectados proveniente del servidor
      List<dynamic> connectedUsers = (data['users'] as List)
          .map((u) => {
        'sessionId': u['sessionId']?.toString() ?? '',
        'username': u['username']?.toString() ?? 'Desconocido',
        'userId': u['userId']?.toString() ?? ''
      })
          .toList();

      setState(() {
        // Actualizamos o agregamos los usuarios conectados en la lista _users
        for (var connectedUser in connectedUsers) {
          int index = _users.indexWhere((user) =>
          user['username']?.toString() == connectedUser['username']?.toString());
          if (index != -1) {
            // Si ya existe, actualizamos su información (por ejemplo, sessionId)
            _users[index] = connectedUser;
          } else {
            // Si no existe, lo agregamos
            _users.add(connectedUser);
          }
        }

        // Para cada usuario en _users que no se encuentre en connectedUsers, marcamos como desconectado
        for (var user in _users) {
          bool isConnected = connectedUsers.any((cu) =>
          cu['username']?.toString() == user['username']?.toString());
          if (!isConnected) {
            user['sessionId'] = ''; // Usuario desconectado
          }
        }
      });

      _showConnectionNotification(data['message'] ?? 'Actualización de usuarios');
    }
    else if (data['type'] == 'MESSAGE') {
      setState(() {
        _messages.add({
          'type': 'public',
          'username': data['username'],
          'message': data['message'],
          'timestamp': DateTime.now().toString(),
        });
      });
    } else if (data['type'] == 'PRIVATE_MESSAGE') {
      setState(() {
        _messages.add({
          'type': 'private',
          'from': data['fromUsername'],
          'to': data['toUsername'],
          'message': data['message'],
          'time': data['time'],
          'timestamp': DateTime.now().toString(),
        });
      });

      // Incrementar contador de mensajes no leídos si no estamos en ese chat
      if (data['fromUsername'] != widget.username &&
          (_currentChat != 'private' || _selectedUsername != data['fromUsername'])) {
        setState(() {
          _unreadMessages[data['fromUsername']] =
              (_unreadMessages[data['fromUsername']] ?? 0) + 1;
        });

        // Mostrar notificación de mensaje recibido
        _showMessageNotification(data['fromUsername'], data['message']);
      }

    } else if (data['type'] == 'PRIVATE_MESSAGE_HISTORY') {
      // Procesamos el historial de chats privados
      final List<dynamic> history = data['data'];
      for (var historyMsg in history) {
        // Convertimos cada mensaje histórico al formato usado localmente
        final messageMap = {
          'type': 'private',
          'from': historyMsg['fromUser'],
          'to': historyMsg['toUser'],
          'message': historyMsg['message'],
          'time': historyMsg['time'],
          'timestamp': historyMsg['time'], // Se usa la misma fecha/hora del mensaje
        };

        setState(() {
          _messages.add(messageMap);
        });

        // Determinar quién es la contraparte.
        // Suponiendo que el usuario logueado (widget.username) es el que envió los mensajes,
        // la contraparte es el "toUser". En otro caso, se tomaría "fromUser".
        String partner;
        if (widget.username == historyMsg['fromUser']) {
          partner = historyMsg['toUser'];
        } else {
          partner = historyMsg['fromUser'];
        }

        // Si la conversación con ese usuario aún no existe en la lista de _users,
        // se añade con sessionId vacío (lo que indica que está desconectado)
        bool exists = _users.any((u) => u['username'] == partner);
        if (!exists) {
          setState(() {
            _users.add({
              'username': partner,
              'sessionId': '', // Vacío, usuario desconectado
              'userId': '',
            });
          });
        }
      }
    }
  }

  void _showConnectionNotification(String message) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A9DFF), Color(0xFF3E6FE1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showMessageNotification(String sender, String message) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.black54],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFF4ECDC4),
                    radius: 20,
                    child: Text(
                      sender[0].toUpperCase(),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          sender,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      overlayEntry.remove();
                      _openPrivateChat(sender);
                    },
                    child: Text(
                      'Ver',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState?.insert(overlayEntry);
    Future.delayed(Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _openPrivateChat(String username) {
    final user = _users.firstWhere((u) => u['username'] == username);
    setState(() {
      _currentChat = 'private';
      _selectedUserSession = user['sessionId'];
      _selectedUsername = username;
      _unreadMessages[username] = 0; // Limpiar mensajes no leídos
    });
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final currentTime = DateTime.now().toString();

    if (_currentChat == 'broadcast') {
      widget.channel.sink.add(jsonEncode({
        'type': 'MESSAGE',
        'username': widget.username,
        'message': _messageController.text,
      }));
    } else {
      // Crear el mensaje privado
      final privateMessage = {
        'type': 'private',
        'from': widget.username,
        'to': _selectedUsername,
        'message': _messageController.text,
        'time': TimeOfDay.now().format(context),
        'timestamp': currentTime,
      };

      // Añadir el mensaje a la lista local
      setState(() {
        _messages.add(privateMessage);
      });

      // Enviar el mensaje al servidor
      widget.channel.sink.add(jsonEncode({
        'type': 'PRIVATE_MESSAGE',
        'toSession': _selectedUserSession,
        'fromUsername': widget.username,
        'toUsername': _selectedUsername,
        'message': _messageController.text,
        'time': TimeOfDay.now().format(context),
      }));
    }

    _messageController.clear();
  }

  Widget _buildMessageDate(String timestamp, bool showDate) {
    if (!showDate) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatMessageDate(timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublicMessageBubble(Map<String, dynamic> message, bool showDate) {
    final bool isMe = message['username'] == widget.username;
    return Column(
      children: [
        _buildMessageDate(message['timestamp'], showDate),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                colors: [Color(0xFF6A9DFF), Color(0xFF3E6FE1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [Color(0xFFE8E8E8), Color(0xFFD1D1D1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      message['username'] ?? 'Desconocido',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                Text(
                  message['message'],
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateMessageBubble(Map<String, dynamic> message, bool showDate) {
    final bool isMe = message['from'] == widget.username;
    return Column(
      children: [
        _buildMessageDate(message['timestamp'], showDate),
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF2BAF9F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : LinearGradient(
                colors: [Color(0xFFFFB88C), Color(0xFFDE6262)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    isMe
                        ? 'Para: ${_selectedUsername}'
                        : 'De: ${message['from']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  message['message'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Actualizamos la construcción de la lista de usuarios para incluir
  // el indicador de conexión (bolita verde o gris) y un texto de estado.
  Widget _buildUsersList(List<dynamic> users) {
    // Filtramos para no mostrar al usuario logueado
    List<dynamic> filteredUsers =
    users.where((user) => user['username'] != widget.username).toList();
    return ListView(
      children: filteredUsers.map<Widget>((user) {
        final unreadCount = _unreadMessages[user['username']] ?? 0;
        final bool isConnected = user['sessionId'].toString().isNotEmpty;
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFF4ECDC4),
                child: Text(
                  user['username']?[0].toUpperCase() ?? '?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            user['username'] ?? 'Desconocido',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(isConnected ? 'Conectado' : 'Desconectado'),
          trailing: unreadCount > 0
              ? Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
              : null,
          onTap: () {
            setState(() {
              _currentChat = 'private';
              _selectedUserSession = user['sessionId']?.toString();
              _selectedUsername = user['username']?.toString();
              _unreadMessages[user['username']] = 0; // Limpiar contador
            });
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _logout() {
    widget.channel.sink.close();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado de mensajes según la sala activa
    List<dynamic> filteredMessages = [];
    if (_currentChat == 'broadcast') {
      filteredMessages =
          _messages.where((msg) => msg['type'] == 'public').toList();
    } else {
      filteredMessages = _messages.where((msg) {
        if (msg['type'] != 'private') return false;
        final from = msg['from'];
        final to = msg['to'];
        // Se muestran solo los mensajes de la conversación privada actual
        return (from == _selectedUsername && to == widget.username) ||
            (from == widget.username && to == _selectedUsername);
      }).toList();
    }
    final messagesToShow = filteredMessages.reversed.toList();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.indigo,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentChat == 'broadcast'
                    ? 'Chat Público'
                    : 'Chat con ${_selectedUsername ?? ''}',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 4),
              Text(
                'Conectado como: ${widget.username}',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: _logout,
            )
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient:
                  LinearGradient(colors: [Colors.indigo, Colors.indigoAccent]),
                ),
                child: Center(
                  child: Text(
                    'Usuarios Conectados',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
              ),
              Expanded(child: _buildUsersList(_users)),
              ListTile(
                leading: Icon(Icons.chat),
                title: Text('Chat Público'),
                onTap: () {
                  setState(() {
                    _currentChat = 'broadcast';
                  });
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade100, Colors.indigo.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: messagesToShow.length,
                  itemBuilder: (context, index) {
                    final message = messagesToShow[index];
                    final showDate =
                    (index < 5) ? (index == messagesToShow.length - 1) : index % 5 == 0;

                    if (_currentChat == 'broadcast') {
                      return _buildPublicMessageBubble(message, showDate);
                    } else {
                      return _buildPrivateMessageBubble(message, showDate);
                    }
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: 8),
                    Material(
                      shape: CircleBorder(),
                      elevation: 4,
                      color: Colors.indigo,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    widget.channel.sink.close();
    super.dispose();
  }

  bool _shouldShowDate(String currentTimestamp, String? previousTimestamp) {
    if (previousTimestamp == null) return true;

    final currentDate = DateTime.parse(currentTimestamp);
    final previousDate = DateTime.parse(previousTimestamp);

    return currentDate.day != previousDate.day ||
        currentDate.month != previousDate.month ||
        currentDate.year != previousDate.year;
  }
}
