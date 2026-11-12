package com.example.todo.todo;

import javax.validation.Valid;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.server.ResponseStatusException;

@Controller
public class TodoController {

    private final TodoRepository todoRepository;

    public TodoController(TodoRepository todoRepository) {
        this.todoRepository = todoRepository;
    }

    @GetMapping("/")
    public String index(Model model) {
        if (!model.containsAttribute("todoForm")) {
            model.addAttribute("todoForm", new TodoForm());
        }
        addTodoList(model);
        return "todos";
    }

    @PostMapping("/todos")
    public String create(@Valid @ModelAttribute("todoForm") TodoForm todoForm,
            BindingResult bindingResult, Model model) {
        if (bindingResult.hasErrors()) {
            addTodoList(model);
            return "todos";
        }

        todoRepository.save(new Todo(todoForm.getTitle().trim()));
        return "redirect:/";
    }

    @PostMapping("/todos/{id}/toggle")
    public String toggle(@PathVariable Long id) {
        Todo todo = findTodo(id);
        todo.toggle();
        todoRepository.save(todo);
        return "redirect:/";
    }

    @PostMapping("/todos/{id}/delete")
    public String delete(@PathVariable Long id) {
        Todo todo = findTodo(id);
        todoRepository.delete(todo);
        return "redirect:/";
    }

    private Todo findTodo(Long id) {
        return todoRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Todo not found"));
    }

    private void addTodoList(Model model) {
        List<Todo> todos = todoRepository.findAllByOrderByCreatedAtDesc();
        model.addAttribute("todos", todos);
        model.addAttribute("remainingCount", todos.stream()
                .filter(todo -> !todo.isCompleted())
                .count());
    }
}