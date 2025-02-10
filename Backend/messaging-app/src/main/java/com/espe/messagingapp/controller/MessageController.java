package com.espe.messagingapp.controller;

import com.espe.messagingapp.model.Message;
import com.espe.messagingapp.repository.MessageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

@RestController
public class MessageController {

    @Autowired
    private MessageRepository messageRepository;

    @PostMapping("/send")
    public void sendMessage(@RequestBody Message message, WebSocketSession session) {
        // Guardar el mensaje en MongoDB
        messageRepository.save(message);

        // Log de mensaje
        System.out.println("Mensaje recibido: " + message.getContent());

        try {
            // Enviar respuesta al cliente
            session.sendMessage(new TextMessage(message.getContent()));
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
