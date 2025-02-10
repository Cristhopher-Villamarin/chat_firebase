package com.espe.messagingapp.config;

import com.espe.messagingapp.model.Message;
import com.espe.messagingapp.model.PrivateMessage;
import com.espe.messagingapp.model.User;
import com.espe.messagingapp.repository.PrivateMessageRepository;
import com.espe.messagingapp.repository.UserRepository;
import com.espe.messagingapp.service.MessageService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PrivateMessageRepository privateMessageRepository;

    // Lista sincronizada para almacenar las sesiones activas
    private final Set<WebSocketSession> activeSessions = Collections.synchronizedSet(new HashSet<>());

    // Mapa para asociar sesiones con nombres de usuario
    private final Map<WebSocketSession, String> userSessions = new ConcurrentHashMap<>();

    private final ObjectMapper objectMapper = new ObjectMapper(); // Para procesar JSON

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        registry.addHandler(new WebSocketHandler() {
            @Override
            public void afterConnectionEstablished(WebSocketSession session) {
                synchronized (activeSessions) {
                    activeSessions.add(session);
                }
            }

            @Override
            public void handleMessage(WebSocketSession session, WebSocketMessage<?> message) throws Exception {
                String payload = message.getPayload().toString();
                Map<String, String> messageData = objectMapper.readValue(payload, Map.class);

                switch (messageData.get("type")) {
                    case "JOIN":
                        handleJoin(session, messageData.get("username"));
                        break;
                    case "MESSAGE":
                        handlePublicMessage(session, payload);
                        break;
                    case "PRIVATE_MESSAGE":
                        handlePrivateMessage(session, messageData);
                        break;
                }
            }

            private void handleJoin(WebSocketSession session, String username) throws Exception {
                String normalizedUsername = username.toUpperCase();
                User user = userRepository.findByUsername(normalizedUsername);

                if (user == null) {
                    user = new User(normalizedUsername);
                    userRepository.save(user);
                }

                userSessions.put(session, user.getId());
                sendUserHistory(session, normalizedUsername);
                System.out.println("Usuario conectó: " + session.getId() + " (Usuario: " + username + ")");
                notifyUsers(normalizedUsername, "conectó");
            }

            private void handlePublicMessage(WebSocketSession session, String payload) {
                broadcastMessage(payload);
            }

            private void handlePrivateMessage(WebSocketSession session, Map<String, String> messageData) throws Exception {
                String fromUser = messageData.get("fromUsername");
                String toUser = messageData.get("toUsername");
                String content = messageData.get("message");
                String toSession = messageData.get("toSession");
                String time = new Date().toString();

                PrivateMessage pm = new PrivateMessage(fromUser, toUser, content, time);
                privateMessageRepository.save(pm);

                sendPrivateMessage(pm, toSession);
            }

            private void sendUserHistory(WebSocketSession session, String username) throws Exception {
                List<PrivateMessage> history = privateMessageRepository.findByFromUserOrToUser(username, username);
                List<Map<String, Object>> historyList = new ArrayList<>();
                Map<String, Object> historyResponse = new HashMap<>();
                for (PrivateMessage msg : history) {
                    Map<String, Object> response = new HashMap<>();
                    response.put("type", "PRIVATE_MESSAGE_HISTORY");
                    response.put("fromUser", msg.getFromUser());
                    response.put("toUser", msg.getToUser());
                    response.put("message", msg.getMessage());
                    response.put("time", msg.getTime());
                    historyList.add(response);
                }

                historyResponse.put("type", "PRIVATE_MESSAGE_HISTORY");
                historyResponse.put("data", historyList);

                session.sendMessage(new TextMessage(objectMapper.writeValueAsString(historyResponse)));
            }

            private void sendPrivateMessage(PrivateMessage pm, String toSession) throws Exception {
                List<WebSocketSession> webSocketSessions = findSessionsById(toSession);

                Map<String, Object> message = new HashMap<>();
                message.put("type", "PRIVATE_MESSAGE");
                message.put("fromUsername", pm.getFromUser());
                message.put("toUsername", pm.getToUser());
                message.put("message", pm.getMessage());
                message.put("time", pm.getTime());

                String jsonMessage = objectMapper.writeValueAsString(message);

                privateMessageToSend(jsonMessage, webSocketSessions);

            }


            // Función para encontrar la sesión por su ID
            public List<WebSocketSession> findSessionsById(String sessionId) {
                return userSessions.entrySet().stream()
                        .filter(entry -> entry.getValue().equals(sessionId))
                        .map(Map.Entry::getKey)
                        .collect(Collectors.toList());
            }

            @Override
            public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
                System.out.println("Error en WebSocket: " + exception.getMessage());
            }

            @Override
            public void afterConnectionClosed(WebSocketSession session, CloseStatus closeStatus) throws Exception {
                String username = userSessions.remove(session);
                activeSessions.remove(session);
                if (username != null) {
                    System.out.println("Usuario desconectado: " + session.getId() + " (Usuario: " + username + ")");
                    // Notificar la lista actualizada de usuarios
                    notifyUsers(username, "desconectó");
                }
            }

            @Override
            public boolean supportsPartialMessages() {
                return false;
            }

            // Método para enviar mensajes a todos los usuarios conectados
            private void broadcastMessage(String message) {
                synchronized (activeSessions) {
                    for (WebSocketSession session : activeSessions) {
                        if (session.isOpen()) {
                            try {
                                session.sendMessage(new TextMessage(message));
                            } catch (Exception e) {
                                System.out.println("Error enviando mensaje: " + e.getMessage());
                            }
                        }
                    }
                }
            }

            // Método para enviar mensajes a todos los usuarios conectados
            private void privateMessageToSend(String message, List<WebSocketSession> webSocketSessions) {
                synchronized (activeSessions) {
                    for (WebSocketSession session : webSocketSessions) {
                        if (session.isOpen()) {
                            try {
                                session.sendMessage(new TextMessage(message));
                            } catch (Exception e) {
                                System.out.println("Error enviando mensaje: " + e.getMessage());
                            }
                        }
                    }
                }
            }

            private void notifyUsers(String usernameChanged, String action) throws JsonProcessingException {
                List<Map<String, Object>> usersData = new ArrayList<>();

                for (Map.Entry<WebSocketSession, String> entry : userSessions.entrySet()) {
                    User user = userRepository.findById(entry.getValue()).orElse(null);
                    if (user != null) {
                        usersData.add(Map.of(
                                "userId", user.getId(),
                                "username", user.getUsername(),
                                "sessionId", entry.getValue()
                        ));
                    }
                }

                Map<String, Object> notification = Map.of(
                        "type", "USERS_UPDATE",
                        "users", usersData,
                        "message", usernameChanged + " se " + action
                );

                broadcastMessage(objectMapper.writeValueAsString(notification));
            }
        }, "/ws").setAllowedOrigins("*"); // Se permite cualquier origen
    }
}
