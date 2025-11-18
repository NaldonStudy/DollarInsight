package com.ssafy.b205.backend.domain.user.service;

import com.ssafy.b205.backend.domain.persona.service.UserPersonaService;
import com.ssafy.b205.backend.domain.user.entity.User;
import com.ssafy.b205.backend.domain.user.entity.UserCredential;
import com.ssafy.b205.backend.domain.user.entity.UserStatus;
import com.ssafy.b205.backend.domain.user.repository.UserCredentialRepository;
import com.ssafy.b205.backend.domain.user.repository.UserRepository;
import com.ssafy.b205.backend.support.error.AppException;
import com.ssafy.b205.backend.support.error.ErrorCode;
import com.ssafy.b205.backend.infra.security.TokenProvider;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private UserCredentialRepository credentialRepository;
    @Mock
    private UserPersonaService userPersonaService;
    @Mock
    private PasswordEncoder passwordEncoder;
    @Mock
    private TokenProvider tokenProvider;

    private UserServiceImpl userService;

    @BeforeEach
    void setUp() {
        userService = new UserServiceImpl(userRepository, credentialRepository, userPersonaService, passwordEncoder, tokenProvider);
    }

    @Test
    void signupThrowsWhenPasswordIsWeak() {
        assertThatThrownBy(() -> userService.signup("weak@example.com", "Weak", "pass"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("비밀번호");
        verifyNoInteractions(userRepository, credentialRepository, userPersonaService);
    }

    @Test
    void signupRejectsDuplicateEmail() {
        when(userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull("dup@example.com")).thenReturn(true);

        assertThatThrownBy(() -> userService.signup("dup@example.com", "DupUser", "Aa1!aaaa"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("이미 사용 중");

        verify(userRepository, never()).save(any());
    }

    @Test
    void signupPersistsUserCredentialAndPersonaLinks() {
        String email = "alice@example.com";
        when(userRepository.existsByEmailIgnoreCaseAndDeletedAtIsNull(email)).thenReturn(false);
        User saved = User.builder()
                .id(1)
                .uuid(UUID.randomUUID())
                .email(email)
                .nickname("Alice")
                .status(UserStatus.ACTIVE)
                .build();
        when(userRepository.save(any(User.class))).thenReturn(saved);
        when(passwordEncoder.encode("Aa1!good")).thenReturn("encoded-hash");
        when(credentialRepository.save(any(UserCredential.class))).thenAnswer(invocation -> invocation.getArgument(0));

        User result = userService.signup(email, "Alice", "Aa1!good");

        assertThat(result).isSameAs(saved);
        verify(userPersonaService).initializeForUser(1);

        ArgumentCaptor<UserCredential> credCaptor = ArgumentCaptor.forClass(UserCredential.class);
        verify(credentialRepository).save(credCaptor.capture());
        UserCredential credential = credCaptor.getValue();
        assertThat(credential.getUser()).isSameAs(saved);
        assertThat(credential.getPasswordHash()).isEqualTo("encoded-hash");
    }

    @Test
    void issueAccessReturnsTokenWhenCredentialsMatch() {
        User user = createUser("user@example.com", "User");
        when(userRepository.findByEmailIgnoreCaseAndDeletedAtIsNull("user@example.com")).thenReturn(Optional.of(user));
        UserCredential cred = UserCredential.builder()
                .user(user)
                .passwordHash("stored-hash")
                .build();
        when(credentialRepository.findByUser(user)).thenReturn(Optional.of(cred));
        when(passwordEncoder.matches("Password1!", "stored-hash")).thenReturn(true);
        when(tokenProvider.createAccessToken(user.getUuid().toString(), "device-01")).thenReturn("token-value");

        String token = userService.issueAccess("user@example.com", "Password1!", "  device-01 ");

        assertThat(token).isEqualTo("token-value");
        verify(tokenProvider).createAccessToken(user.getUuid().toString(), "device-01");
    }

    @Test
    void issueAccessThrowsWhenPasswordMismatch() {
        User user = createUser("user@example.com", "User");
        when(userRepository.findByEmailIgnoreCaseAndDeletedAtIsNull("user@example.com")).thenReturn(Optional.of(user));
        UserCredential cred = UserCredential.builder()
                .user(user)
                .passwordHash("stored-hash")
                .build();
        when(credentialRepository.findByUser(user)).thenReturn(Optional.of(cred));
        when(passwordEncoder.matches("WrongPass1!", "stored-hash")).thenReturn(false);

        assertThatThrownBy(() -> userService.issueAccess("user@example.com", "WrongPass1!", "dev"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("비밀번호");

        verify(tokenProvider, never()).createAccessToken(anyString(), anyString());
    }

    @Test
    void changeNicknameSkipsWhenSameIgnoringCase() {
        User user = createUser("nick@example.com", "Alice");
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));

        userService.changeNickname(user.getUuid().toString(), "ALICE");

        verify(userRepository, never())
                .existsByNicknameIgnoreCaseAndDeletedAtIsNullAndIdNot(anyString(), anyInt());
        assertThat(user.getNickname()).isEqualTo("Alice");
    }

    @Test
    void changePasswordUpdatesHashWhenOldMatches() {
        User user = createUser("pw@example.com", "Bob");
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        UserCredential cred = UserCredential.builder()
                .user(user)
                .passwordHash("stored-hash")
                .build();
        when(credentialRepository.findByUser(user)).thenReturn(Optional.of(cred));
        when(passwordEncoder.matches("Current1!", "stored-hash")).thenReturn(true);
        when(passwordEncoder.matches("Newpass1!", "stored-hash")).thenReturn(false);
        when(passwordEncoder.encode("Newpass1!")).thenReturn("encoded-new");

        userService.changePassword(user.getUuid().toString(), "Current1!", "Newpass1!");

        assertThat(cred.getPasswordHash()).isEqualTo("encoded-new");
    }

    @Test
    void changePasswordThrowsWhenOldPasswordIncorrect() {
        User user = createUser("pw@example.com", "Bob");
        when(userRepository.findByUuidAndDeletedAtIsNull(user.getUuid())).thenReturn(Optional.of(user));
        UserCredential cred = UserCredential.builder()
                .user(user)
                .passwordHash("stored-hash")
                .build();
        when(credentialRepository.findByUser(user)).thenReturn(Optional.of(cred));
        when(passwordEncoder.matches("Current1!", "stored-hash")).thenReturn(false);

        AppException ex = assertThrows(AppException.class,
                () -> userService.changePassword(user.getUuid().toString(), "Current1!", "Newpass1!"));
        assertThat(ex.getCode()).isEqualTo(ErrorCode.FORBIDDEN);
    }

    private User createUser(String email, String nickname) {
        return User.builder()
                .id(1)
                .uuid(UUID.randomUUID())
                .email(email)
                .nickname(nickname)
                .status(UserStatus.ACTIVE)
                .build();
    }
}
