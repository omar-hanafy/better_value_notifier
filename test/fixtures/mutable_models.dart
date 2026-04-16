class MutableUser {
  MutableUser(this.name);

  String name;

  @override
  String toString() => 'MutableUser($name)';
}

class HashMutableUser {
  HashMutableUser(this.name);

  String name;

  @override
  bool operator ==(Object other) =>
      other is HashMutableUser && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'HashMutableUser($name)';
}
