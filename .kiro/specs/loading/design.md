# Design: Loading

## Arquitectura

### Componentes Principales

#### LoadingProvider
Context provider que gestiona el estado global de loading.

```typescript
interface LoadingContextType {
  isLoading: boolean;
  message?: string;
  showLoading: (message?: string) => void;
  hideLoading: () => void;
}
```

#### LoadingSpinner
Componente visual reutilizable para mostrar el indicador de carga.

Props:
- `size`: 'small' | 'medium' | 'large'
- `variant`: 'spinner' | 'dots' | 'bar'
- `message`: string opcional

#### useLoading Hook
Hook personalizado para gestionar estados de carga locales.

```typescript
const useLoading = () => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<Error | null>(null);
  
  const withLoading = async (fn: () => Promise<any>) => {
    // Implementación
  };
  
  return { isLoading, error, withLoading };
};
```

## Flujo de Datos

1. Componente inicia operación asíncrona
2. Llama a `showLoading()` o `withLoading()`
3. LoadingProvider actualiza estado global
4. LoadingSpinner se renderiza
5. Operación completa
6. `hideLoading()` se llama automáticamente
7. LoadingSpinner desaparece

## Decisiones de Diseño

### Decisión 1: Context API vs Estado Local
- **Opción elegida**: Híbrido (Context para global, hooks para local)
- **Razón**: Flexibilidad y rendimiento

### Decisión 2: Animaciones
- **Opción elegida**: CSS animations
- **Razón**: Mejor rendimiento que JavaScript animations

### Decisión 3: Overlay
- **Opción elegida**: Portal para loading global
- **Razón**: Evita problemas de z-index y posicionamiento

## Estructura de Archivos

```
src/
├── components/
│   └── Loading/
│       ├── LoadingSpinner.tsx
│       ├── LoadingOverlay.tsx
│       └── index.ts
├── contexts/
│   └── LoadingContext.tsx
└── hooks/
    └── useLoading.ts
```

## Estilos

- Usar CSS modules o styled-components
- Animaciones suaves con ease-in-out
- Colores del tema de la aplicación
- Backdrop semi-transparente para overlay global
