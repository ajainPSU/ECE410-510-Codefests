import math

class Perceptron:
    def __init__(self, weights, bias):
        self.weights = weights
        self.bias = bias

    def sigmoid(self, x):
        return 1 / (1 + math.exp(-x))

    def forward(self, inputs):
        # Weighted sum
        z = sum(w * i for w, i in zip(self.weights, inputs)) + self.bias
        # Apply sigmoid activation
        return self.sigmoid(z)

# Example usage
weights = [0.5, -0.6]  # Example weights
bias = 0.1             # Example bias
perceptron = Perceptron(weights, bias)

inputs = [1.0, 2.0]    # Example inputs
output = perceptron.forward(inputs)
print(f"Output: {output}")
