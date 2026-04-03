# LoadingSpinner Widget

A reusable Flutter widget for displaying loading indicators with multiple variants and sizes.

## Features

- **Three visual variants**: Spinner (circular), Dots (animated dots), Bar (horizontal progress bar)
- **Three size options**: Small, Medium, Large
- **Optional message**: Display text below the loading indicator
- **Custom colors**: Override the default theme color
- **Smooth animations**: 60fps animations with ease-in-out curves
- **Theme integration**: Automatically uses app theme colors

## Usage

### Basic Usage

```dart
import 'package:lubricentros_app/widgets/loading/loading_spinner.dart';

// Default spinner (medium size, spinner variant)
LoadingSpinner()

// With message
LoadingSpinner(
  message: 'Loading data...',
)
```

### Size Variants

```dart
// Small
LoadingSpinner(size: LoadingSize.small)

// Medium (default)
LoadingSpinner(size: LoadingSize.medium)

// Large
LoadingSpinner(size: LoadingSize.large)
```

### Visual Variants

```dart
// Circular spinner (default)
LoadingSpinner(variant: LoadingVariant.spinner)

// Animated dots
LoadingSpinner(variant: LoadingVariant.dots)

// Horizontal bar
LoadingSpinner(variant: LoadingVariant.bar)
```

### Custom Colors

```dart
LoadingSpinner(
  color: Colors.blue,
  message: 'Processing...',
)
```

### Complete Example

```dart
LoadingSpinner(
  size: LoadingSize.large,
  variant: LoadingVariant.dots,
  message: 'Please wait while we process your request...',
  color: Theme.of(context).colorScheme.secondary,
)
```

## Common Use Cases

### In a FutureBuilder

```dart
FutureBuilder<Data>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: LoadingSpinner(
          message: 'Loading data...',
        ),
      );
    }
    
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    
    return DataWidget(data: snapshot.data!);
  },
)
```

### In a Button

```dart
ElevatedButton(
  onPressed: isLoading ? null : _handleSubmit,
  child: isLoading
    ? const LoadingSpinner(
        size: LoadingSize.small,
        color: Colors.white,
      )
    : const Text('Submit'),
)
```

### Full Screen Loading

```dart
if (isLoading)
  Container(
    color: Colors.black54,
    child: const Center(
      child: LoadingSpinner(
        size: LoadingSize.large,
        message: 'Processing your request...',
      ),
    ),
  )
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `size` | `LoadingSize` | `LoadingSize.medium` | Size of the loading indicator |
| `variant` | `LoadingVariant` | `LoadingVariant.spinner` | Visual style of the indicator |
| `message` | `String?` | `null` | Optional text displayed below the indicator |
| `color` | `Color?` | `null` | Custom color (defaults to theme primary color) |

## Animation Details

- **Spinner**: Continuous rotation at 1200ms per cycle
- **Dots**: Sequential fade animation with 1200ms cycle, 200ms delay between dots
- **Bar**: Sliding animation with ease-in-out curve, 1500ms per cycle

## Accessibility

The LoadingSpinner widget is designed with accessibility in mind:
- Uses semantic widgets that work with screen readers
- Respects theme contrast settings
- Message text is readable by assistive technologies

## Performance

All animations use Flutter's efficient animation system:
- Hardware-accelerated rendering
- Minimal CPU usage
- Smooth 60fps animations
- Automatic cleanup when widget is disposed

## Example Screen

See `loading_spinner_example.dart` for a complete demonstration of all variants and configurations.
