
abstract class Repository {

}

/// Interface for generic CRUD operations on a repository.

abstract class CrudRepository<T, K> implements Repository {
  Stream<T> readAll();

  Future<T> create(T entity);

  Future<T> read(K id);

  Future<T> update(T entity);

  Future<T> delete(T entity);
}