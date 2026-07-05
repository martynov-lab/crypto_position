/// Result of an operation: either [Ok] with a value or [Err] with an error.
///
/// Used instead of exceptions to propagate API call results.
sealed class Result<T, E> {
  const Result();

  Result<U, E> map<U>(U Function(T value) function) => switch (this) {
        Ok(:final value) => Ok(function(value)),
        Err(:final error) => Err(error),
      };

  Result<T, F> mapErr<F>(F Function(E error) function) => switch (this) {
        Ok(:final value) => Ok(value),
        Err(:final error) => Err(function(error)),
      };

  B fold<B>(B Function(T value) ifOk, B Function(E error) ifErr) =>
      switch (this) {
        Ok(:final value) => ifOk(value),
        Err(:final error) => ifErr(error),
      };
}

final class Ok<T, E> extends Result<T, E> {
  final T value;

  const Ok(this.value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  final E error;

  const Err(this.error);

  @override
  String toString() => 'Err($error)';
}
