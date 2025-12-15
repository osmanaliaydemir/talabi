class RoleMismatchException implements Exception {
  final String actualRole;
  final String expectedRole;

  RoleMismatchException(this.actualRole, this.expectedRole);

  @override
  String toString() =>
      'RoleMismatchException: Expected $expectedRole, but got $actualRole';
}
