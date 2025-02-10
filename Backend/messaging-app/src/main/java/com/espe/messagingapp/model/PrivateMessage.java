// PrivateMessage.java
package com.espe.messagingapp.model;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import java.util.Date;

@Document(collection = "private_messages")
public class PrivateMessage {
    @Id
    private String id;
    private String fromUser;
    private String toUser;
    private String message;
    private String time;
    private Date createdAt;

    // Constructor, Getters y Setters
    public PrivateMessage() {}

    public PrivateMessage(String fromUser, String toUser, String message, String time) {
        this.fromUser = fromUser;
        this.toUser = toUser;
        this.message = message;
        this.time = time;
        this.createdAt = new Date();
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getFromUser() {
        return fromUser;
    }

    public void setFromUser(String fromUser) {
        this.fromUser = fromUser;
    }

    public String getToUser() {
        return toUser;
    }

    public void setToUser(String toUser) {
        this.toUser = toUser;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getTime() {
        return time;
    }

    public void setTime(String time) {
        this.time = time;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    // Getters y Setters omitidos por brevedad
}