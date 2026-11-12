package com.example.todo.todo;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

public class TodoForm {

    @NotBlank(message = "Enter a task before adding it.")
    @Size(max = 120, message = "Keep the task to 120 characters or fewer.")
    private String title;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }
}