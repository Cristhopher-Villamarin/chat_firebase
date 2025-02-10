// PrivateMessageRepository.java
package com.espe.messagingapp.repository;

import com.espe.messagingapp.model.PrivateMessage;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.util.List;

public interface PrivateMessageRepository extends MongoRepository<PrivateMessage, String> {
    List<PrivateMessage> findByFromUserOrToUser(String fromUser, String toUser);
}