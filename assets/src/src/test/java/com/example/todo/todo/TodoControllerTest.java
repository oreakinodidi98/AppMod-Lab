package com.example.todo.todo;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.argThat;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.util.Collections;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(TodoController.class)
class TodoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TodoRepository todoRepository;

    @Test
    void indexShowsTodoList() throws Exception {
        when(todoRepository.findAllByOrderByCreatedAtDesc()).thenReturn(Collections.emptyList());

        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(view().name("todos"))
                .andExpect(model().attributeExists("todoForm", "todos", "remainingCount"));
    }

    @Test
    void createPersistsTrimmedTitleAndRedirects() throws Exception {
        mockMvc.perform(post("/todos").param("title", "  Ship the sample  "))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/"));

        verify(todoRepository).save(argThat(todo -> "Ship the sample".equals(todo.getTitle())));
    }

    @Test
    void createWithBlankTitleReturnsValidationError() throws Exception {
        when(todoRepository.findAllByOrderByCreatedAtDesc()).thenReturn(Collections.emptyList());

        mockMvc.perform(post("/todos").param("title", "   "))
                .andExpect(status().isOk())
                .andExpect(view().name("todos"))
                .andExpect(model().attributeHasFieldErrors("todoForm", "title"));

        verify(todoRepository, never()).save(any(Todo.class));
    }
}