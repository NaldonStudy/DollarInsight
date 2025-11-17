package com.ssafy.b205.backend.domain.persona.service;

import com.ssafy.b205.backend.domain.persona.entity.Persona;
import com.ssafy.b205.backend.domain.persona.entity.UserPersona;
import com.ssafy.b205.backend.domain.persona.repository.PersonaRepository;
import com.ssafy.b205.backend.domain.persona.repository.UserPersonaRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.stream.StreamSupport;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserPersonaServiceImplTest {

    @Mock
    private PersonaRepository personaRepository;
    @Mock
    private UserPersonaRepository userPersonaRepository;

    @Test
    void initializeForUserSkipsWhenNoPersonaDefined() {
        when(personaRepository.findAll()).thenReturn(List.of());
        UserPersonaServiceImpl service = new UserPersonaServiceImpl(personaRepository, userPersonaRepository);

        service.initializeForUser(42);

        verify(userPersonaRepository, never()).saveAll(any());
    }

    @Test
    void initializeForUserCreatesLinkForEachPersona() {
        Persona persona1 = mock(Persona.class);
        when(persona1.getId()).thenReturn(1);
        Persona persona2 = mock(Persona.class);
        when(persona2.getId()).thenReturn(2);
        when(personaRepository.findAll()).thenReturn(List.of(persona1, persona2));
        UserPersonaServiceImpl service = new UserPersonaServiceImpl(personaRepository, userPersonaRepository);

        service.initializeForUser(55);

        ArgumentCaptor<Iterable<UserPersona>> captor = ArgumentCaptor.forClass(Iterable.class);
        verify(userPersonaRepository).saveAll(captor.capture());
        List<UserPersona> saved = StreamSupport.stream(captor.getValue().spliterator(), false).toList();
        assertThat(saved).hasSize(2);
        assertThat(saved).allSatisfy(up -> {
            assertThat(up.getUserId()).isEqualTo(55);
            assertThat(up.isEnabled()).isTrue();
        });
        assertThat(saved).extracting(UserPersona::getPersonaId)
                .containsExactlyInAnyOrder(1, 2);
    }
}
