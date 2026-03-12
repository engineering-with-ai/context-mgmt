## Pydantic AI Guidelines 🤖

### Agent Configuration
- **Define deps_type for dependency injection** to pass services like databases
- **Use model_settings** for consistent LLM configuration across agents

### Tool Design Patterns
- **Create focused, single-purpose tools** that do one thing well
- **Use RunContext[DepsType]** for accessing injected dependencies
- **Provide clear docstrings** for tool functions - the LLM uses these for understanding
- **Return structured responses** with clear status indicators when appropriate

### System Prompt Management
- **Use Jinja2 templates** for dynamic system prompt generation
- **Separate prompts by agent type** - organize in `prompts/` directory structure
- **Compose prompts from reusable components** using template inheritance
- **Include domain-specific instructions** when working with specialized knowledge

### Agent Specialization
- **Create specialized agents for specific domains** (analysis, search, processing)
- **Use agent factories** to create configured agents per use case
- **Share common tools** across related agents when appropriate

### Database Integration
- **Use async database pools** for efficient connection management
- **Implement proper schema setup** with required extensions
- **Create database dependency classes** for clean separation of concerns
- **Handle connection lifecycle** properly with context managers

### RAG Implementation
- **Use vector search tools** for semantic document retrieval
- **Implement similarity scoring** to rank document relevance
- **Format search results** clearly for LLM consumption
- **Combine multiple retrieval strategies** when needed

### Agentic RAG Patterns
- **Let agents decide when to search** - provide search tools and let LLM determine relevance
- **Use multi-step retrieval** - agents can search, analyze results, then search again
- **Implement query refinement** - agents can reformulate searches based on initial results
- **Provide search feedback** to help agents understand result quality

### Knowledge Graph Integration
- **Provide graph traversal tools** for agents to navigate knowledge structures
- **Support timeline and temporal queries** for historical analysis
- **Enable semantic graph search** across entity relationships


