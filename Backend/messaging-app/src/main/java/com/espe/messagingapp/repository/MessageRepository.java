package com.espe.messagingapp.repository;

import com.espe.messagingapp.model.Message;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface MessageRepository extends MongoRepository<Message, String> {
    // Aquí puedes agregar métodos personalizados si los necesitas
}
