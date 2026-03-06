package com.friends.backend.notification.prefs;

import org.springframework.data.jpa.repository.JpaRepository;

public interface NotificationPreferencesRepository
    extends JpaRepository<NotificationPreferencesEntity, Long> {
}
