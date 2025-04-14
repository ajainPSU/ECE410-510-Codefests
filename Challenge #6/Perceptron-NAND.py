import math
import matplotlib.pyplot as plt  # Import matplotlib for plotting

class Perceptron:
    def __init__(self, weights, bias, learning_rate=0.1):
        self.weights = weights
        self.bias = bias
        self.learning_rate = learning_rate

    def sigmoid(self, x):
        return 1 / (1 + math.exp(-x))

    def sigmoid_derivative(self, x):
        return x * (1 - x)

    def forward(self, inputs):
        # Weighted sum
        z = sum(w * i for w, i in zip(self.weights, inputs)) + self.bias
        # Apply sigmoid activation
        return self.sigmoid(z)

    def train(self, training_data, epochs):
        errors = []  # To store the total error for each epoch
        for epoch in range(epochs):
            total_error = 0
            for inputs, target in training_data:
                # Forward pass
                output = self.forward(inputs)
                # Calculate error
                error = target - output
                total_error += error ** 2  # Accumulate squared error
                # Update weights and bias using the Perceptron Learning Rule
                for i in range(len(self.weights)):
                    self.weights[i] += self.learning_rate * error * inputs[i] * self.sigmoid_derivative(output)
                self.bias += self.learning_rate * error * self.sigmoid_derivative(output)
            errors.append(total_error)  # Store total error for this epoch
        return errors  # Return the error history

# NAND function training data
training_data = [
    ([0, 0], 1),
    ([0, 1], 1),
    ([1, 0], 1),
    ([1, 1], 0)
]

# Initialize perceptron
weights = [0.0, 0.0]  # Start with zero weights
bias = 0.0            # Start with zero bias
learning_rate = 0.1   # Learning rate
perceptron = Perceptron(weights, bias, learning_rate)

# Train the perceptron
epochs = 10000  # Number of training iterations
errors = perceptron.train(training_data, epochs)

# Plot the error over epochs
plt.plot(range(epochs), errors)
plt.title("Training Error Over Epochs")
plt.xlabel("Epochs")
plt.ylabel("Total Error")
plt.show()

# Test the perceptron
for inputs, target in training_data:
    output = perceptron.forward(inputs)
    print(f"Inputs: {inputs}, Predicted: {round(output)}, Target: {target}")