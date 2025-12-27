
/// Abstract base class for handling specific CSV data aspects.
abstract class CsvHandler<T> {
  /// Processes the input and returns the transformed output.
  T process(T input);
}
