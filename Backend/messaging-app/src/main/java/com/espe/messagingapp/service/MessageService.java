package com.espe.messagingapp.service;

import com.espe.messagingapp.model.Message;
import com.espe.messagingapp.repository.MessageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class MessageService {

    @Autowired
    private MessageRepository messageRepository;

    public void saveMessage(Message message) {
        messageRepository.save(message); // Guarda el mensaje en la base de datos
    }
}
