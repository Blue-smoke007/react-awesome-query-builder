package com.example;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.expression.Expression;
import org.springframework.expression.ExpressionParser;
import org.springframework.expression.spel.standard.SpelExpressionParser;
import org.springframework.web.bind.annotation.*;

@SpringBootApplication
@RestController
public class SpelApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpelApplication.class, args);
    }

    @PostMapping("/evaluate")
    public Object evaluateExpression(@RequestBody SpelRequest request) {
        ExpressionParser parser = new SpelExpressionParser();
        Expression exp = parser.parseExpression(request.getExpression());
        return exp.getValue(request.getContext());
    }
}

class SpelRequest {
    private String expression;
    private Object context;

    public String getExpression() { return expression; }
    public void setExpression(String expression) { this.expression = expression; }
    public Object getContext() { return context; }
    public void setContext(Object context) { this.context = context; }
}