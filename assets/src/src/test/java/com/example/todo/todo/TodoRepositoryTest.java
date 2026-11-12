package com.example.todo.todo;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

@DataJpaTest
class TodoRepositoryTest {

    @Autowired
    private TodoRepository todoRepository;

    @Test
    void savesAndLoadsTodo() {
        Todo saved = todoRepository.saveAndFlush(new Todo("Write release notes"));

        List<Todo> todos = todoRepository.findAllByOrderByCreatedAtDesc();

        assertThat(saved.getId()).isNotNull();
        assertThat(saved.getCreatedAt()).isNotNull();
        assertThat(todos).extracting(Todo::getTitle).containsExactly("Write release notes");
    }
}