class RoleMismatchException implements Exception {
  RoleMismatchException(this.actualRole, this.expectedRole);
  final String actualRole;
  final String expectedRole;

  @override
  String toString() =>
      'RoleMismatchException: Expected $expectedRole, but got $actualRole';
}
