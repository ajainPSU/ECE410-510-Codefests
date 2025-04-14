import math
import matplotlib.pyplot as plt
import random

class MLP:
    def __init__(self, input_size, hidden_size, output_size, learning_rate=0.1):
        # Initialize weights and biases for the hidden and output layers
        self.hidden_weights = [[random.uniform(-0.5, 0.5) for _ in range(input_size)] for _ in range(hidden_size)]
        self.hidden_biases = [random.uniform(-0.5, 0.5) for _ in range(hidden_size)]
        self.output_weights = [random.uniform(-0.5, 0.5) for _ in range(hidden_size)]
        self.output_bias = random.uniform(-0.5, 0.5)
        self.learning_rate = learning_rate

    def sigmoid(self, x):
        return 1 / (1 + math.exp(-x))

    def sigmoid_derivative(self, x):
        return x * (1 - x)

    def forward(self, inputs):
        # Hidden layer computations
        self.hidden_layer_outputs = []
        for i in range(len(self.hidden_weights)):
            z = sum(w * inp for w, inp in zip(self.hidden_weights[i], inputs)) + self.hidden_biases[i]
            self.hidden_layer_outputs.append(self.sigmoid(z))
        
        # Output layer computation
        z = sum(w * h for w, h in zip(self.output_weights, self.hidden_layer_outputs)) + self.output_bias
        self.output = self.sigmoid(z)
        return self.output

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

                # Backpropagation for output layer
                output_delta = error * self.sigmoid_derivative(output)
                for i in range(len(self.output_weights)):
                    self.output_weights[i] += self.learning_rate * output_delta * self.hidden_layer_outputs[i]
                self.output_bias += self.learning_rate * output_delta

                # Backpropagation for hidden layer
                hidden_deltas = []
                for i in range(len(self.hidden_weights)):
                    hidden_error = output_delta * self.output_weights[i]
                    hidden_delta = hidden_error * self.sigmoid_derivative(self.hidden_layer_outputs[i])
                    hidden_deltas.append(hidden_delta)
                    for j in range(len(self.hidden_weights[i])):
                        self.hidden_weights[i][j] += self.learning_rate * hidden_delta * inputs[j]
                    self.hidden_biases[i] += self.learning_rate * hidden_delta

            errors.append(total_error)  # Store total error for this epoch
        return errors  # Return the error history

# XOR function training data
xor_training_data = [
    ([0, 0], 0),
    ([0, 1], 1),
    ([1, 0], 1),
    ([1, 1], 0)
]

# Initialize MLP
input_size = 2
hidden_size = 6  # Increase the number of hidden neurons for better learning
output_size = 1
learning_rate = 0.05  # Adjust the learning rate for faster convergence
mlp_xor = MLP(input_size, hidden_size, output_size, learning_rate)

# Train the MLP for XOR
epochs = 50000  # Increase the number of epochs for better convergence
xor_errors = mlp_xor.train(xor_training_data, epochs)

# Plot the error over epochs
plt.plot(range(epochs), xor_errors, label="XOR Error")
plt.title("Training Error Over Epochs (XOR)")
plt.xlabel("Epochs")
plt.ylabel("Total Error")
plt.legend()
plt.show()

# Test the MLP for XOR
print("\nTesting XOR Function:")
for inputs, target in xor_training_data:
    output = mlp_xor.forward(inputs)
    print(f"Inputs: {inputs}, Predicted: {round(output)}, Target: {target}")