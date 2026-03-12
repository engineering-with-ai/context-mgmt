  ## Sensor Architecture Pattern

  This project follows a layered architecture for sensor implementations:

  [sensor_type]/
  ├── [sensor_type]_driver.py     # Low-level hardware interface
  ├── [sensor_type]_client.py     # High-level API abstraction└──
  [sensor_type]_client_test.py # Client interface tests

  **Driver Layer**: Hardware-specific implementation that can be swapped for
  different sensors of the same type. Handles direct sensor communication (I2C,
  SPI, GPIO protocols).

  **Client Layer**: Standardized high-level interface that applications interact
   with. Provides consistent API regardless of underlying driver implementation.

  **Testing**: Tests focus on the client interface to ensure API contract
  compliance.

  When adding new sensors, follow this pattern to maintain modularity and allow
  driver swapping without application code changes.
