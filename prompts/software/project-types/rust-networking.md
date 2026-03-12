## Rust Networking Project Guidelines 🛜

### Architecture
- **Adapter pattern** for multiple protocols
- **Shared client/publisher** pattern
- **Async-first** with tokio

### Dependencies
- **tokio** for async runtime
- **serde** for serialization
- **reqwest** for HTTP

### Structure
```
src/
main.rs
client.rs     # Shared networking client
adapters/     # Protocol modules
```

### Error Handling
- **Propagate with `?`** operator
- **Continue on individual failures** - don't crash entire system

## Integration Testing with Testcontainers 🐳

### Integration Test Structure
Follow AAA pattern with container orchestration:

### Best Practices
- **Container orchestration**: Start dependent services in proper order
- **Dynamic configuration**: Use container ports to build connection strings
- **Wait strategies**: Use specific log messages for reliable startup detection
- **Error propagation**: Use `?` operator and `Box<dyn Error>` for test error handling
- **Resource cleanup**: Containers automatically cleaned up when dropped