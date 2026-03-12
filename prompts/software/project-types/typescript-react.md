## React Component Organization ⚛️

### Component Directory Structure
Each component has its own directory with multiple files following the Container/Presenter pattern:

```
components/
└── ComponentName/
    ├── ComponentName.tsx              # Presentational component (pure UI)
    ├── ComponentName.types.tsx        # Separate for api use and avoid cycles
    ├── ComponentName.container.tsx    # Container component (data fetching/logic)
    ├── ComponentName.styles.ts        # StyleSheet definitions
    └── ComponentName.test.tsx         # Colocated tests
```

### Pattern Rules
- **Presentational components (`.tsx`)**: Pure UI, receives props, no data fetching
- **Container components (`.container.tsx`)**: Handles data fetching, business logic, wraps presentational component
- **Styles (`.styles.ts`)**: Separate StyleSheet definitions using `react-native` StyleSheet API
- **Tests (`.test.tsx`)**: Colocated with component, tests both presenter and container
