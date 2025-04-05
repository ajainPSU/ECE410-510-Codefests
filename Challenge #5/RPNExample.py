def rpn_calculate(expression):
    stack = []
    operators = {'+': lambda x, y: x + y,
                 '-': lambda x, y: x - y,
                 '*': lambda x, y: x * y,
                 '/': lambda x, y: x / y}
    
    tokens = expression.split()
    
    for token in tokens:
        if token in operators:
            y, x = stack.pop(), stack.pop()
            stack.append(operators[token](x, y))
        else:
            stack.append(float(token))
    
    return stack[0] if stack else None

# Example usage with moderate and high complexity expressions
expressions = [
    "3 4 + 2 *",  # (3 + 4) * 2 = 14.0
    "15 7 1 1 + - / 3 * 2 1 1 + + -",  # 15 / (7 - (1 + 1)) * 3 - (2 + (1 + 1)) = 9.0
    "5 1 2 + 4 * + 3 -",  # 5 + ((1 + 2) * 4) - 3 = 14.0
    "2 3 + 5 6 + *",  # (2 + 3) * (5 + 6) = 55.0
    "10 2 8 * + 3 -",  # 10 + (2 * 8) - 3 = 23.0
    "7 2 3 * - 4 +"  # 7 - (2 * 3) + 4 = 5.0
]

for expression in expressions:
    result = rpn_calculate(expression)
    print(f"Expression: {expression} => Result: {result}")